import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mimu/features/calls/signal_crypto.dart';
import 'package:mimu/features/calls/signal_double_ratchet.dart';
import 'package:mimu/features/calls/sender_key_crypto.dart';

/// Central service for managing Signal Protocol crypto and sessions.
class SignalService {
  static final SignalService _instance = SignalService._internal();
  factory SignalService() => _instance;
  SignalService._internal();

  DoubleRatchetSignalCrypto? _crypto;
  SenderKeyCrypto? _senderKeyCrypto;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _crypto = DoubleRatchetSignalCrypto(prefs);
    _senderKeyCrypto = SenderKeyCrypto(prefs);
  }

  SignalCrypto get crypto {
    if (_crypto == null) {
      // Lazy init fallback if init() wasn't called (though it should be)
      throw StateError('SignalService not initialized. Call init() first.');
    }
    return _crypto!;
  }

  SenderKeyCrypto get senderKeyCrypto {
    if (_senderKeyCrypto == null) {
      throw StateError('SignalService not initialized. Call init() first.');
    }
    return _senderKeyCrypto!;
  }
  
  /// Set the user's stable Identity Key (derived from mnemonic).
  void setIdentityKey(Uint8List privateKey) {
    _crypto?.setIdentityKey(privateKey);
  }

  /// Generate PreKeys for registration (Signed PreKey + One-Time PreKeys).
  /// Signs the Signed PreKey using the provided [authKeyPair] (Ed25519).
  /// Note: Signal Protocol usually signs with the Identity Key (X25519 converted or XEdDSA),
  /// but this server seems to use a separate Signing Key (Ed25519).
  Future<Map<String, dynamic>> generatePreKeys(
      int startId, int count, dynamic authKeyPair) async {
    // We assume authKeyPair is CryptoKeyPair from crypto_auth_service.dart
    // but we can't import it directly due to circular deps if not careful.
    // Ideally SignalService should import CryptoKeyPair.

    final crypto = this.crypto as DoubleRatchetSignalCrypto;

    // 1. Generate Signed PreKey
    final signedPreKey = crypto.generateKeyPair();
    final signedPreKeyId = 1;
    
    // Store Signed PreKey private key
    await crypto.storeSignedPreKey(signedPreKeyId, signedPreKey.privateKey);
    
    // Sign the public key
    // authKeyPair has .sign(Uint8List message)
    final signature = authKeyPair.sign(signedPreKey.publicKey);

    // 2. Generate One-Time PreKeys
    final oneTimePreKeys = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      final key = crypto.generateKeyPair();
      final keyId = startId + i;
      
      // Store One-Time PreKey private key
      await crypto.storePreKey(keyId, key.privateKey);
      
      oneTimePreKeys.add({
        'key_id': keyId,
        'public_key': base64Encode(key.publicKey),
      });
    }

    return {
      'signed_prekey': {
        'key_id': signedPreKeyId,
        'public_key': base64Encode(signedPreKey.publicKey),
        'signature': base64Encode(signature),
      },
      'one_time_prekeys': oneTimePreKeys,
    };
  }
}
