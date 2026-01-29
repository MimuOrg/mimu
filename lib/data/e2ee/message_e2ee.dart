import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal E2EE for messages: per-chat symmetric key (32 bytes) + ChaCha20-Poly1305.
///
/// NOTE: This provides encrypted_payload end-to-end only if peers have the same chat key.
/// Key distribution (Signal sessions) should replace this later.
class MessageE2EE {
  static const _keyPrefix = 'e2ee_chat_key_v1_';
  static final _cipher = Chacha20.poly1305Aead();

  static Future<SecretKey> _getOrCreateChatKey(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString('$_keyPrefix$chatId');
    if (b64 != null && b64.isNotEmpty) {
      return SecretKey(base64Decode(b64));
    }
    final keyBytes = await _cipher.newSecretKey();
    final raw = await keyBytes.extractBytes();
    await prefs.setString('$_keyPrefix$chatId', base64Encode(raw));
    return SecretKey(raw);
  }

  /// Encrypt JSON payload to base64 string.
  /// Format: base64(nonce(12) || mac(16) || ciphertext)
  static Future<String> encryptJsonForChat(String chatId, Map<String, dynamic> payload) async {
    final key = await _getOrCreateChatKey(chatId);
    final nonce = _cipher.newNonce();
    final plaintext = utf8.encode(jsonEncode(payload));
    final box = await _cipher.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );
    final out = BytesBuilder()
      ..add(box.nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    return base64Encode(out.toBytes());
  }

  /// Decrypt base64 string produced by encryptJsonForChat.
  static Future<Map<String, dynamic>> decryptJsonForChat(String chatId, String encryptedPayloadBase64) async {
    final key = await _getOrCreateChatKey(chatId);
    final raw = base64Decode(encryptedPayloadBase64);
    if (raw.length < 12 + 16) {
      throw FormatException('encrypted payload too short');
    }
    final nonce = raw.sublist(0, 12);
    final macBytes = raw.sublist(12, 28);
    final cipherText = raw.sublist(28);
    final box = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    final clear = await _cipher.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  }
}

