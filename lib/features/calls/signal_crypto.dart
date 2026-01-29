import 'dart:convert';

/// Abstraction for Signal Protocol E2EE signalling encryption.
/// Replace implementation with real Signal (Double Ratchet) session per peer.
abstract class SignalCrypto {
  /// Encrypt plaintext JSON and return opaque bytes (transport-safe base64).
  String encryptToBase64(String plaintextJson);

  /// Decrypt opaque base64 back to plaintext JSON.
  String decryptFromBase64(String encryptedBase64);
}

/// TEMPORARY stub: does NOT provide security. Must be replaced.
class InsecureBase64Crypto implements SignalCrypto {
  @override
  String encryptToBase64(String plaintextJson) => base64Encode(utf8.encode(plaintextJson));

  @override
  String decryptFromBase64(String encryptedBase64) =>
      utf8.decode(base64Decode(encryptedBase64));
}


