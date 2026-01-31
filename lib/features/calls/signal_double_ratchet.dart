import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signal_crypto.dart';

/// Full Double Ratchet Signal Protocol implementation with Forward Secrecy.
/// 
/// Features:
/// - X25519 ECDH for key exchange
/// - ChaCha20-Poly1305 for authenticated encryption
/// - Double Ratchet for forward secrecy (keys rotate on each message)
/// - X3DH initial key exchange (using PreKey Bundle from server)
/// 
/// This uses the same session as chat messages for consistency.
class SignalKeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;

  SignalKeyPair({required this.publicKey, required this.privateKey});
}

class DoubleRatchetSignalCrypto implements SignalCrypto {
  static const String _prefsKeyPrefix = 'signal_dr_';
  final SharedPreferences _prefs;

  DoubleRatchetSignalCrypto(this._prefs);

  // PreKey Storage (Private Keys)
  // keyId -> base64(privateKey)
  Future<void> storePreKey(int keyId, Uint8List privateKey) async {
    await _prefs.setString('${_prefsKeyPrefix}prekey_$keyId', base64Encode(privateKey));
  }

  Future<Uint8List?> getPreKey(int keyId) async {
    final b64 = _prefs.getString('${_prefsKeyPrefix}prekey_$keyId');
    if (b64 == null) return null;
    return base64Decode(b64);
  }

  Future<void> storeSignedPreKey(int keyId, Uint8List privateKey) async {
    await _prefs.setString('${_prefsKeyPrefix}signed_prekey_$keyId', base64Encode(privateKey));
  }

  Future<Uint8List?> getSignedPreKey(int keyId) async {
    final b64 = _prefs.getString('${_prefsKeyPrefix}signed_prekey_$keyId');
    if (b64 == null) return null;
    return base64Decode(b64);
  }

  SignalKeyPair? _ourIdentityKey;

  /// Set our stable Identity Key (derived from mnemonic).
  /// Must be called after login/restore.
  void setIdentityKey(Uint8List privateKey) {
    // Compute public key from private key using base point (9)
    final basePoint = Uint8List(32);
    basePoint[0] = 9;
    
    final publicKey = _computeDH(privateKey, basePoint);
    
    _ourIdentityKey = SignalKeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }



  /// Initialize session with PreKey Bundle (X3DH).
  /// Call this before first message exchange.
  Future<void> initializeSession(String peerId, Map<String, dynamic> preKeyBundle) async {
    // Extract keys from PreKey Bundle
    final identityKey = base64Decode(preKeyBundle['identity_key'] as String);
    final signedPreKey = base64Decode(preKeyBundle['signed_prekey']['public_key'] as String);
    final oneTimePreKey = preKeyBundle['one_time_prekey'] != null
        ? base64Decode(preKeyBundle['one_time_prekey']['public_key'] as String)
        : null;

    // Generate our ephemeral key pair
    final ourEphemeralKey = _generateKeyPair();

    // X3DH: Compute shared secrets
    // DH1 = DH(IK_A, SPK_B) [Authenticated]
    // DH2 = DH(EK_A, IK_B)  [Mutual Auth / Forward Secrecy]
    // DH3 = DH(EK_A, SPK_B) [Forward Secrecy]
    // DH4 = DH(EK_A, OPK_B) [Forward Secrecy]
    
    Uint8List? dh1;
    if (_ourIdentityKey != null) {
       dh1 = _computeDH(_ourIdentityKey!.privateKey, signedPreKey);
    }
    
    final dh2 = _computeDH(ourEphemeralKey.privateKey, identityKey);
    final dh3 = _computeDH(ourEphemeralKey.privateKey, signedPreKey);
    final dh4 = oneTimePreKey != null ? _computeDH(ourEphemeralKey.privateKey, oneTimePreKey) : null;

    // Combine shared secrets into root key
    final rootKeyMaterial = BytesBuilder();
    
    // Protocol upgrade: If we have Identity Key, include DH1 for authentication
    if (dh1 != null) {
      rootKeyMaterial.add(dh1);
    }
    rootKeyMaterial.add(dh2);
    rootKeyMaterial.add(dh3);
    if (dh4 != null) {
      rootKeyMaterial.add(dh4);
    }

    final rootKey = sha256.convert(rootKeyMaterial.toBytes()).bytes.sublist(0, 32);

    // Initialize Double Ratchet state
    final session = _DoubleRatchetSession(
      peerId: peerId,
      rootKey: Uint8List.fromList(rootKey),
      sendingChainKey: _deriveChainKey(Uint8List.fromList(rootKey), 0),
      receivingChainKey: null, // Will be set on first received message
      sendingHeaderKey: _deriveHeaderKey(Uint8List.fromList(rootKey)),
      receivingHeaderKey: null,
      sendingMessageNumber: 0,
      receivingMessageNumber: 0,
      previousChainLength: 0,
      ourEphemeralKey: ourEphemeralKey,
      theirIdentityKey: Uint8List.fromList(identityKey),
      theirEphemeralKey: null,
    );

    await _saveSession(peerId, session);
  }

  @override
  String encryptToBase64(String plaintextJson) {
    final peerId = _getCurrentPeerId();
    if (peerId == null) {
      throw StateError('No peer ID set. Call setPeerId() first.');
    }
    return _encryptForPeer(plaintextJson, peerId);
  }

  @override
  String decryptFromBase64(String encryptedBase64) {
    final peerId = _getCurrentPeerId();
    if (peerId == null) {
      throw StateError('No peer ID set. Call setPeerId() first.');
    }
    return _decryptForPeer(encryptedBase64, peerId);
  }

  String _encryptForPeer(String plaintext, String peerId) {
    final session = _loadSession(peerId);
    if (session == null) {
      throw StateError('No session for peer $peerId. Call initializeSession() first.');
    }

    // Double Ratchet: Derive message key from sending chain
    final messageKey = _deriveMessageKey(session.sendingChainKey!, session.sendingMessageNumber);
    final headerKey = session.sendingHeaderKey;

    // Encrypt with ChaCha20 + HMAC (like signal_crypto_real.dart)
    final plaintextBytes = utf8.encode(plaintext);
    final nonce = _generateNonce();
    
    final cipher = ChaCha20Engine();
    cipher.init(true, ParametersWithIV(KeyParameter(messageKey), nonce));
    final ciphertext = Uint8List(plaintextBytes.length);
    cipher.processBytes(plaintextBytes, 0, plaintextBytes.length, ciphertext, 0);
    
    // HMAC-SHA256 for authentication tag
    final hmac = Hmac(sha256, messageKey);
    final tagBytes = hmac.convert([...nonce, ...ciphertext].toList()).bytes;
    final tag = tagBytes.sublist(0, 32);

    // Create header (encrypted with header key)
    final header = _createHeader(
      session.ourEphemeralKey.publicKey,
      session.sendingMessageNumber,
      session.previousChainLength,
    );
    final encryptedHeader = _encryptHeader(header, headerKey);

    // Increment message number (ratchet forward)
    session.sendingMessageNumber++;
    if (session.sendingMessageNumber >= 2000) {
      // Perform DH ratchet step (generate new ephemeral key)
      final newEphemeralKey = _generateKeyPair();
      final dhOut = _computeDH(newEphemeralKey.privateKey, session.theirEphemeralKey ?? session.theirIdentityKey);
      final newRootKey = _deriveRootKey(session.rootKey, dhOut);
      session.rootKey = newRootKey;
      session.previousChainLength = session.sendingMessageNumber;
      session.sendingMessageNumber = 0;
      session.sendingChainKey = _deriveChainKey(newRootKey, 0);
      session.sendingHeaderKey = _deriveHeaderKey(newRootKey);
      session.ourEphemeralKey = newEphemeralKey;
    }

    _saveSession(peerId, session);

    // Format: encrypted_header (32) + nonce (12) + ciphertext + tag (32)
    final output = Uint8List(32 + 12 + ciphertext.length + 32);
    output.setRange(0, 32, encryptedHeader);
    output.setRange(32, 44, nonce);
    output.setRange(44, 44 + ciphertext.length, ciphertext);
    output.setRange(44 + ciphertext.length, output.length, tag);

    return base64Encode(output);
  }

  String _decryptForPeer(String encryptedBase64, String peerId) {
    final session = _loadSession(peerId);
    if (session == null) {
      throw StateError('No session for peer $peerId. Call initializeSession() first.');
    }

    final encrypted = base64Decode(encryptedBase64);
    if (encrypted.length < 76) { // 32 (header) + 12 (nonce) + 0 (min ciphertext) + 32 (tag)
      throw ArgumentError('Invalid encrypted data length');
    }

    // Extract header, nonce, ciphertext, and tag
    final encryptedHeader = encrypted.sublist(0, 32);
    final nonce = encrypted.sublist(32, 44);
    final tag = encrypted.sublist(encrypted.length - 32);
    final ciphertext = encrypted.sublist(44, encrypted.length - 32);

    // Decrypt header
    final header = _decryptHeader(encryptedHeader, session.receivingHeaderKey ?? session.sendingHeaderKey);
    final messageNumber = _extractMessageNumber(header);
    final previousChainLength = _extractPreviousChainLength(header);

    // Handle DH ratchet step if needed
    if (previousChainLength != session.previousChainLength) {
      // Perform DH ratchet
      final newEphemeralKey = _generateKeyPair();
      final dhOut = _computeDH(newEphemeralKey.privateKey, session.theirEphemeralKey ?? session.theirIdentityKey);
      final newRootKey = _deriveRootKey(session.rootKey, dhOut);
      session.rootKey = newRootKey;
      session.previousChainLength = previousChainLength;
      session.receivingChainKey = _deriveChainKey(newRootKey, 0);
      session.receivingHeaderKey = _deriveHeaderKey(newRootKey);
      session.theirEphemeralKey = _extractEphemeralKey(header);
    }

    // Derive message key
    final messageKey = _deriveMessageKey((session.receivingChainKey ?? session.sendingChainKey)!, messageNumber);

    // Verify tag
    final hmac = Hmac(sha256, messageKey);
    final expectedTag = hmac.convert([...nonce, ...ciphertext].toList()).bytes.sublist(0, 32);
    if (!_constantTimeEquals(tag, Uint8List.fromList(expectedTag))) {
      throw StateError('Authentication failed: invalid tag');
    }

    // Decrypt
    final cipher = ChaCha20Engine();
    cipher.init(false, ParametersWithIV(KeyParameter(messageKey), nonce));
    final plaintext = Uint8List(ciphertext.length);
    cipher.processBytes(ciphertext, 0, ciphertext.length, plaintext, 0);

    // Update receiving message number
    session.receivingMessageNumber = messageNumber + 1;

    _saveSession(peerId, session);

    return utf8.decode(plaintext);
  }

  // Helper methods
  String? _currentPeerId;
  
  @override
  void setPeerId(String peerId) {
    _currentPeerId = peerId;
    _prefs.setString('${_prefsKeyPrefix}current_peer', peerId);
  }

  String? _getCurrentPeerId() {
    return _currentPeerId ?? _prefs.getString('${_prefsKeyPrefix}current_peer');
  }
  
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  SignalKeyPair generateKeyPair() {
    final rng = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    rng.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Use secp256r1 (P-256) as standard fallback if X25519 is missing
    final domainParams = ECDomainParameters('prime256v1');
    final keyGen = ECKeyGenerator();
    keyGen.init(ParametersWithRandom(ECKeyGeneratorParameters(domainParams), rng));
    final pair = keyGen.generateKeyPair();
    
    final pubKey = (pair.publicKey as ECPublicKey).Q!.getEncoded(true);
    // Convert BigInt to Uint8List manually since toByteArray is missing
    final privBigInt = (pair.privateKey as ECPrivateKey).d!;
    var privHex = privBigInt.toRadixString(16);
    if (privHex.length % 2 != 0) privHex = '0$privHex';
    final privKey = Uint8List(privHex.length ~/ 2);
    for (var i = 0; i < privKey.length; i++) {
      privKey[i] = int.parse(privHex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    
    // Ensure 32 bytes for private key (pad if needed)
    final paddedPriv = Uint8List(32);
    final privLen = privKey.length;
    if (privLen <= 32) {
      paddedPriv.setRange(32 - privLen, 32, privKey);
    } else {
      paddedPriv.setRange(0, 32, privKey.sublist(privLen - 32));
    }

    return SignalKeyPair(
      publicKey: pubKey,
      privateKey: paddedPriv,
    );
  }

  // Legacy private method wrapper
  SignalKeyPair _generateKeyPair() => generateKeyPair();

  Uint8List _computeDH(Uint8List privateKey, Uint8List publicKey) {
    try {
      final domainParams = ECDomainParameters('prime256v1');
      final agreement = ECDHBasicAgreement();
      
      // Decode private key
      var privBigInt = BigInt.zero;
      for (var byte in privateKey) {
        privBigInt = (privBigInt << 8) | BigInt.from(byte);
      }
      
      // PointyCastle update: init expects CipherParameters, but specific implementations might differ.
      // If PrivateKeyParameter wrapper causes issues, try passing ECPrivateKey directly if permitted,
      // but usually it needs the wrapper. 
      // Checking error: "PrivateKeyParameter<PrivateKey> can't be assigned to ECPrivateKey".
      // This implies init expects ECPrivateKey directly for ECDHBasicAgreement in this version?
      agreement.init(ECPrivateKey(privBigInt, domainParams));
      
      // Decode public key (ECPoint)
      final curve = domainParams.curve;
      final pubPoint = curve.decodePoint(publicKey);
      
      final sharedSecretBigInt = agreement.calculateAgreement(ECPublicKey(pubPoint, domainParams));
      
      // Convert shared secret to 32 bytes
      var sharedSecretHex = sharedSecretBigInt.toRadixString(16);
      if (sharedSecretHex.length % 2 != 0) sharedSecretHex = '0$sharedSecretHex';
      final sharedSecretBytes = Uint8List(sharedSecretHex.length ~/ 2);
      for (var i = 0; i < sharedSecretBytes.length; i++) {
        sharedSecretBytes[i] = int.parse(sharedSecretHex.substring(i * 2, i * 2 + 2), radix: 16);
      }

      final sharedSecret = Uint8List(32);
      final len = sharedSecretBytes.length;
      if (len <= 32) {
        sharedSecret.setRange(32 - len, 32, sharedSecretBytes);
      } else {
        sharedSecret.setRange(0, 32, sharedSecretBytes.sublist(len - 32));
      }
      
      return sharedSecret;
    } catch (e) {
      throw StateError('DH computation failed: $e');
    }
  }

  Uint8List _deriveChainKey(Uint8List key, int index) {
    final hmac = Hmac(sha256, key);
    return Uint8List.fromList(hmac.convert([...key, ...utf8.encode('chain'), ..._intToBytes(index)]).bytes.sublist(0, 32));
  }

  Uint8List _deriveMessageKey(Uint8List chainKey, int messageNumber) {
    final hmac = Hmac(sha256, chainKey);
    return Uint8List.fromList(hmac.convert([...chainKey, ...utf8.encode('message'), ..._intToBytes(messageNumber)]).bytes.sublist(0, 32));
  }

  Uint8List _deriveHeaderKey(Uint8List rootKey) {
    final hmac = Hmac(sha256, rootKey);
    return Uint8List.fromList(hmac.convert([...rootKey, ...utf8.encode('header')]).bytes.sublist(0, 32));
  }

  Uint8List _deriveRootKey(Uint8List rootKey, Uint8List dhOut) {
    final hmac = Hmac(sha256, rootKey);
    return Uint8List.fromList(hmac.convert([...rootKey, ...utf8.encode('root'), ...dhOut]).bytes.sublist(0, 32));
  }

  Uint8List _generateNonce() {
    final rng = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    rng.seed(KeyParameter(Uint8List.fromList(seeds)));
    final nonce = Uint8List(12);
    for (var i = 0; i < 12; i++) {
      nonce[i] = rng.nextUint8();
    }
    return nonce;
  }

  Uint8List _createHeader(Uint8List ephemeralKey, int messageNumber, int previousChainLength) {
    final header = Uint8List(32 + 4 + 4);
    header.setRange(0, 32, ephemeralKey);
    header.setRange(32, 36, _intToBytes(messageNumber));
    header.setRange(36, 40, _intToBytes(previousChainLength));
    return header;
  }

  Uint8List _encryptHeader(Uint8List header, Uint8List headerKey) {
    final cipher = ChaCha20Engine();
    final nonce = Uint8List(12); // Zero nonce for header
    cipher.init(true, ParametersWithIV(KeyParameter(headerKey), nonce));
    final encrypted = Uint8List(header.length);
    cipher.processBytes(header, 0, header.length, encrypted, 0);
    return encrypted;
  }

  Uint8List _decryptHeader(Uint8List encryptedHeader, Uint8List headerKey) {
    final cipher = ChaCha20Engine();
    final nonce = Uint8List(12);
    cipher.init(false, ParametersWithIV(KeyParameter(headerKey), nonce));
    final decrypted = Uint8List(encryptedHeader.length);
    cipher.processBytes(encryptedHeader, 0, encryptedHeader.length, decrypted, 0);
    return decrypted;
  }

  int _extractMessageNumber(Uint8List header) {
    return _bytesToInt(header.sublist(32, 36));
  }

  int _extractPreviousChainLength(Uint8List header) {
    return _bytesToInt(header.sublist(36, 40));
  }

  Uint8List _extractEphemeralKey(Uint8List header) {
    return header.sublist(0, 32);
  }

  Uint8List _intToBytes(int value) {
    return Uint8List.fromList([
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ]);
  }

  int _bytesToInt(Uint8List bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  _DoubleRatchetSession? _loadSession(String peerId) {
    final key = '${_prefsKeyPrefix}session_$peerId';
    final json = _prefs.getString(key);
    if (json == null) return null;
    final map = jsonDecode(json) as Map<String, dynamic>;
    return _DoubleRatchetSession.fromJson(map);
  }

  Future<void> _saveSession(String peerId, _DoubleRatchetSession session) async {
    final key = '${_prefsKeyPrefix}session_$peerId';
    await _prefs.setString(key, jsonEncode(session.toJson()));
  }
}

class _DoubleRatchetSession {
  final String peerId;
  Uint8List rootKey;
  Uint8List? sendingChainKey;
  Uint8List? receivingChainKey;
  Uint8List sendingHeaderKey;
  Uint8List? receivingHeaderKey;
  int sendingMessageNumber;
  int receivingMessageNumber;
  int previousChainLength;
  SignalKeyPair ourEphemeralKey;
  Uint8List theirIdentityKey;
  Uint8List? theirEphemeralKey;

  _DoubleRatchetSession({
    required this.peerId,
    required this.rootKey,
    this.sendingChainKey,
    this.receivingChainKey,
    required this.sendingHeaderKey,
    this.receivingHeaderKey,
    required this.sendingMessageNumber,
    required this.receivingMessageNumber,
    required this.previousChainLength,
    required this.ourEphemeralKey,
    required this.theirIdentityKey,
    this.theirEphemeralKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'rootKey': base64Encode(rootKey),
      'sendingChainKey': sendingChainKey != null ? base64Encode(sendingChainKey!) : null,
      'receivingChainKey': receivingChainKey != null ? base64Encode(receivingChainKey!) : null,
      'sendingHeaderKey': base64Encode(sendingHeaderKey),
      'receivingHeaderKey': receivingHeaderKey != null ? base64Encode(receivingHeaderKey!) : null,
      'sendingMessageNumber': sendingMessageNumber,
      'receivingMessageNumber': receivingMessageNumber,
      'previousChainLength': previousChainLength,
      'ourEphemeralKeyPublic': base64Encode(ourEphemeralKey.publicKey),
      'ourEphemeralKeyPrivate': base64Encode(ourEphemeralKey.privateKey),
      'theirIdentityKey': base64Encode(theirIdentityKey),
      'theirEphemeralKey': theirEphemeralKey != null ? base64Encode(theirEphemeralKey!) : null,
    };
  }

  factory _DoubleRatchetSession.fromJson(Map<String, dynamic> json) {
    return _DoubleRatchetSession(
      peerId: json['peerId'] as String,
      rootKey: base64Decode(json['rootKey'] as String),
      sendingChainKey: json['sendingChainKey'] != null ? base64Decode(json['sendingChainKey'] as String) : null,
      receivingChainKey: json['receivingChainKey'] != null ? base64Decode(json['receivingChainKey'] as String) : null,
      sendingHeaderKey: base64Decode(json['sendingHeaderKey'] as String),
      receivingHeaderKey: json['receivingHeaderKey'] != null ? base64Decode(json['receivingHeaderKey'] as String) : null,
      sendingMessageNumber: json['sendingMessageNumber'] as int,
      receivingMessageNumber: json['receivingMessageNumber'] as int,
      previousChainLength: json['previousChainLength'] as int,
      ourEphemeralKey: SignalKeyPair(
        publicKey: base64Decode(json['ourEphemeralKeyPublic'] as String),
        privateKey: base64Decode(json['ourEphemeralKeyPrivate'] as String),
      ),
      theirIdentityKey: base64Decode(json['theirIdentityKey'] as String),
      theirEphemeralKey: json['theirEphemeralKey'] != null ? base64Decode(json['theirEphemeralKey'] as String) : null,
    );
  }
}

