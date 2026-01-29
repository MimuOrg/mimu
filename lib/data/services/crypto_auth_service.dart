import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:http/http.dart' as http;

import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/services/bip39_wordlists.dart';

// Re-export MnemonicLanguage for convenience
export 'package:mimu/data/services/bip39_wordlists.dart' show MnemonicLanguage;

/// Result of key generation from mnemonic
class CryptoKeyPair {
  final Uint8List seed;
  final Uint8List publicKey;
  final String publicKeyBase64;
  final ed.PrivateKey _privateKey;

  CryptoKeyPair._({
    required this.seed,
    required this.publicKey,
    required ed.PrivateKey privateKey,
  })  : publicKeyBase64 = base64Encode(publicKey),
        _privateKey = privateKey;

  String get fingerprint => sha256.convert(publicKey).toString();

  /// Sign data and return signature bytes
  Uint8List sign(Uint8List message) {
    return Uint8List.fromList(ed.sign(_privateKey, message));
  }

  /// Sign message string and return base64 signature
  String signMessage(String message) {
    final data = Uint8List.fromList(utf8.encode(message));
    return base64Encode(sign(data));
  }
}

/// Challenge response from server
class ChallengeResponse {
  final String nonce;
  final int expiresIn;

  ChallengeResponse({required this.nonce, required this.expiresIn});

  factory ChallengeResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeResponse(
      nonce: json['nonce'] as String,
      expiresIn: json['expires_in'] as int? ?? 300,
    );
  }
}

/// Authentication response with JWT tokens
class CryptoAuthResponse {
  final String userId;
  final String accessToken;
  final String refreshToken;
  final String fingerprint;

  CryptoAuthResponse({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.fingerprint,
  });

  factory CryptoAuthResponse.fromJson(Map<String, dynamic> json) {
    return CryptoAuthResponse(
      userId: json['user_id'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      fingerprint: json['fingerprint'] as String,
    );
  }
}

/// Result of mnemonic validation
class MnemonicValidationResult {
  final bool isValid;
  final String? error;
  final MnemonicLanguage? detectedLanguage;

  MnemonicValidationResult({
    required this.isValid,
    this.error,
    this.detectedLanguage,
  });
}

/// Authentication exception
class CryptoAuthException implements Exception {
  final String message;
  final int? statusCode;

  CryptoAuthException(this.message, {this.statusCode});

  @override
  String toString() => 'CryptoAuthException: $message';
}

/// Service for BIP-39 mnemonic and Ed25519 cryptographic operations
class CryptoAuthService {
  static final CryptoAuthService _instance = CryptoAuthService._internal();
  factory CryptoAuthService() => _instance;
  CryptoAuthService._internal();

  final Bip39Wordlists _wordlists = Bip39Wordlists();

  CryptoKeyPair? _currentKeyPair;
  String? _currentMnemonic;
  MnemonicLanguage? _currentLanguage;

  /// Initialize service (load wordlists)
  Future<void> init() async {
    await _wordlists.init();
  }

  /// Get current key pair (if generated/restored)
  CryptoKeyPair? get currentKeyPair => _currentKeyPair;

  /// Get current mnemonic (ONLY for display to user during registration!)
  String? get currentMnemonic => _currentMnemonic;

  /// Get current mnemonic language
  MnemonicLanguage? get currentLanguage => _currentLanguage;

  /// Generate a new 12-word mnemonic phrase
  String generateMnemonic({MnemonicLanguage language = MnemonicLanguage.english}) {
    final wordlist = _wordlists.getWordlist(language);
    final random = Random.secure();

    // Generate 128 bits of entropy for 12 words
    final entropy = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      entropy[i] = random.nextInt(256);
    }

    // Calculate checksum (first 4 bits of SHA256)
    final hash = sha256.convert(entropy);
    final checksumByte = hash.bytes[0];

    // Convert entropy + checksum to 11-bit indices
    final bits = _bytesToBits(entropy) + _byteToBits(checksumByte).substring(0, 4);

    final words = <String>[];
    for (int i = 0; i < 12; i++) {
      final index = int.parse(bits.substring(i * 11, (i + 1) * 11), radix: 2);
      words.add(wordlist[index]);
    }

    final mnemonic = words.join(' ');
    _currentMnemonic = mnemonic;
    _currentLanguage = language;

    return mnemonic;
  }

  /// Validate mnemonic phrase and detect language
  MnemonicValidationResult validateMnemonic(String mnemonic) {
    final words = mnemonic.trim().toLowerCase().split(RegExp(r'\s+'));

    if (words.length != 12) {
      return MnemonicValidationResult(
        isValid: false,
        error: 'Mnemonic must contain exactly 12 words',
      );
    }

    // Try to detect language
    MnemonicLanguage? detectedLanguage = _wordlists.detectPhraseLanguage(mnemonic);

    if (detectedLanguage == null) {
      // Find invalid words for error message
      final invalidWords = <String>[];
      for (final word in words) {
        if (_wordlists.detectWordLanguage(word) == null) {
          invalidWords.add(word);
        }
      }

      return MnemonicValidationResult(
        isValid: false,
        error: 'Unknown words: ${invalidWords.take(3).join(", ")}${invalidWords.length > 3 ? "..." : ""}',
      );
    }

    // Verify checksum
    if (!_verifyChecksum(words, detectedLanguage)) {
      return MnemonicValidationResult(
        isValid: false,
        error: 'Invalid checksum - please verify the phrase',
      );
    }

    return MnemonicValidationResult(
      isValid: true,
      detectedLanguage: detectedLanguage,
    );
  }

  bool _verifyChecksum(List<String> words, MnemonicLanguage language) {
    final indices = words.map((w) => _wordlists.getWordIndex(w, language)).toList();

    if (indices.any((i) => i < 0)) return false;

    String bits = '';
    for (final index in indices) {
      bits += index.toRadixString(2).padLeft(11, '0');
    }

    // 132 bits total: 128 entropy + 4 checksum
    final entropyBits = bits.substring(0, 128);
    final checksumBits = bits.substring(128, 132);

    final entropy = _bitsToBytes(entropyBits);
    final hash = sha256.convert(entropy);
    final expectedChecksum = _byteToBits(hash.bytes[0]).substring(0, 4);

    return checksumBits == expectedChecksum;
  }

  /// Restore keys from mnemonic phrase
  CryptoKeyPair restoreKeysFromMnemonic(String mnemonic, {MnemonicLanguage? language}) {
    final validation = validateMnemonic(mnemonic);
    if (!validation.isValid) {
      throw ArgumentError('Invalid mnemonic: ${validation.error}');
    }

    final effectiveLanguage = language ?? validation.detectedLanguage!;
    _currentMnemonic = mnemonic.trim().toLowerCase();
    _currentLanguage = effectiveLanguage;

    final keyPair = _deriveKeysFromMnemonic(mnemonic, effectiveLanguage);
    _currentKeyPair = keyPair;

    return keyPair;
  }

  /// Generate keys from current mnemonic (after generateMnemonic was called)
  CryptoKeyPair generateKeys() {
    if (_currentMnemonic == null || _currentLanguage == null) {
      throw StateError('No mnemonic generated. Call generateMnemonic first.');
    }

    final keyPair = _deriveKeysFromMnemonic(_currentMnemonic!, _currentLanguage!);
    _currentKeyPair = keyPair;

    return keyPair;
  }

  // ==================== API Methods ====================

  /// Request challenge from server
  Future<ChallengeResponse> requestChallenge(String publicKeyBase64) async {
    final response = await http.post(
      Uri.parse('${ServerConfig.baseUrl}/auth/challenge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'public_key': publicKeyBase64}),
    );

    if (response.statusCode == 200) {
      return ChallengeResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw CryptoAuthException('User not found', statusCode: 404);
    } else {
      throw CryptoAuthException(
        'Challenge request failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Verify signature and get JWT tokens
  Future<CryptoAuthResponse> verifySignature(
    String publicKeyBase64,
    String signature,
  ) async {
    final response = await http.post(
      Uri.parse('${ServerConfig.baseUrl}/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'public_key': publicKeyBase64,
        'signature': signature,
      }),
    );

    if (response.statusCode == 200) {
      return CryptoAuthResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw CryptoAuthException('Invalid signature', statusCode: 401);
    } else {
      throw CryptoAuthException(
        'Verification failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Complete challenge-response authentication flow
  Future<CryptoAuthResponse> authenticate() async {
    if (_currentKeyPair == null) {
      throw StateError('No key pair available. Generate or restore keys first.');
    }

    // Step 1: Request challenge
    final challenge = await requestChallenge(_currentKeyPair!.publicKeyBase64);

    // Step 2: Sign nonce
    final signature = _currentKeyPair!.signMessage(challenge.nonce);

    // Step 3: Verify signature and get JWT
    return await verifySignature(_currentKeyPair!.publicKeyBase64, signature);
  }

  /// Register new user with public key
  Future<CryptoAuthResponse> register({
    required String displayName,
    String? language,
  }) async {
    if (_currentKeyPair == null) {
      throw StateError('No key pair available. Generate keys first.');
    }

    final response = await http.post(
      Uri.parse('${ServerConfig.baseUrl}/auth/register-crypto'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'public_key': _currentKeyPair!.publicKeyBase64,
        'fingerprint': _currentKeyPair!.fingerprint,
        'display_name': displayName,
        'language': language ?? 'en',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CryptoAuthResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      throw CryptoAuthException('User already exists', statusCode: 409);
    } else {
      throw CryptoAuthException(
        'Registration failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Clear current keys from memory (logout)
  void clearKeys() {
    _currentKeyPair = null;
    _currentMnemonic = null;
    _currentLanguage = null;
  }

  // ==================== Private Cryptographic Methods ====================

  CryptoKeyPair _deriveKeysFromMnemonic(String mnemonic, MnemonicLanguage language) {
    // BIP-39: Derive seed from mnemonic using PBKDF2-HMAC-SHA512
    final normalizedMnemonic = mnemonic.trim().toLowerCase();
    final salt = Uint8List.fromList(utf8.encode('mnemonic')); // Standard BIP-39 salt

    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));
    pbkdf2.init(Pbkdf2Parameters(salt, 2048, 64));

    final seed = pbkdf2.process(Uint8List.fromList(utf8.encode(normalizedMnemonic)));

    // Use first 32 bytes as Ed25519 seed
    final privateSeed = Uint8List.fromList(seed.sublist(0, 32));

    // Generate Ed25519 key pair using ed25519_edwards
    final privateKey = ed.newKeyFromSeed(privateSeed);
    final publicKey = ed.public(privateKey);

    return CryptoKeyPair._(
      seed: privateSeed,
      publicKey: Uint8List.fromList(publicKey.bytes),
      privateKey: privateKey,
    );
  }

  // ==================== Bit/Byte Conversion Utilities ====================

  String _bytesToBits(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join();
  }

  String _byteToBits(int byte) {
    return byte.toRadixString(2).padLeft(8, '0');
  }

  Uint8List _bitsToBytes(String bits) {
    final bytes = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      bytes.add(int.parse(bits.substring(i, i + 8), radix: 2));
    }
    return Uint8List.fromList(bytes);
  }
}
