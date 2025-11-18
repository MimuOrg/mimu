import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _keyUsername = 'user_username';
  static const String _keyDisplayName = 'user_display_name';
  static const String _keyAvatarPath = 'user_avatar_path';
  static const String _keyPrId = 'user_prid';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String getUsername() => _prefs?.getString(_keyUsername) ?? 'usermimu';
  static Future<void> setUsername(String username) async {
    await _prefs?.setString(_keyUsername, username);
  }

  static String getDisplayName() => _prefs?.getString(_keyDisplayName) ?? 'Username';
  static Future<void> setDisplayName(String name) async {
    await _prefs?.setString(_keyDisplayName, name);
  }

  static String? getAvatarPath() => _prefs?.getString(_keyAvatarPath);
  static Future<void> setAvatarPath(String? path) async {
    if (path == null) {
      await _prefs?.remove(_keyAvatarPath);
    } else {
      await _prefs?.setString(_keyAvatarPath, path);
    }
  }

  static String? getPrId() => _prefs?.getString(_keyPrId);
  static Future<void> setPrId(String prid) async {
    await _prefs?.setString(_keyPrId, prid);
  }

  static String generateRandomPrId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }
    return buffer.toString();
  }
}

