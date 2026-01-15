import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mimu/data/user_service.dart';

class StatusService {
  static const String _keyStatuses = 'user_statuses';
  static const String _keyStatusPrivacy = 'status_privacy';
  static const String _keyStatusExpiry = 'status_expiry_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Map<String, dynamic>>> getStatuses() async {
    await init();
    final data = _prefs?.getString(_keyStatuses);
    if (data == null) return [];
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(data));
      // Удаляем истекшие статусы (24 часа)
      final now = DateTime.now();
      final validStatuses = <Map<String, dynamic>>[];
      for (final status in list) {
        final expiryStr = _prefs?.getString(_keyStatusExpiry + (status['id'] as String? ?? ''));
        if (expiryStr != null) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null && expiry.isAfter(now)) {
            validStatuses.add(status);
          } else {
            await _prefs?.remove(_keyStatusExpiry + (status['id'] as String? ?? ''));
            if (status['imagePath'] != null) {
              try {
                final file = File(status['imagePath'] as String);
                if (await file.exists()) {
                  await file.delete();
                }
              } catch (_) {}
            }
          }
        } else {
          validStatuses.add(status);
        }
      }
      if (validStatuses.length != list.length) {
        await _prefs?.setString(_keyStatuses, jsonEncode(validStatuses));
      }
      return validStatuses;
    } catch (_) {
      return [];
    }
  }

  static Future<String> addStatus(String imagePath, {bool isMe = true}) async {
    await init();
    final statuses = await getStatuses();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final expiry = DateTime.now().add(const Duration(hours: 24));
    
    final status = {
      'id': id,
      'imagePath': imagePath,
      'isMe': isMe,
      'name': isMe ? UserService.getDisplayName() : 'Друг',
      'avatar': isMe ? UserService.getAvatarPath() : 'assets/images/avatar_placeholder.png',
      'time': 'Сейчас',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    statuses.insert(0, status);
    await _prefs?.setString(_keyStatuses, jsonEncode(statuses));
    await _prefs?.setString(_keyStatusExpiry + id, expiry.toIso8601String());
    return id;
  }

  static Future<void> deleteStatus(String statusId) async {
    await init();
    final statuses = await getStatuses();
    final status = statuses.firstWhere((s) => s['id'] == statusId, orElse: () => {});
    if (status.isNotEmpty) {
      statuses.removeWhere((s) => s['id'] == statusId);
      await _prefs?.setString(_keyStatuses, jsonEncode(statuses));
      await _prefs?.remove(_keyStatusExpiry + statusId);
      if (status['imagePath'] != null) {
        try {
          final file = File(status['imagePath'] as String);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
  }

  static Future<String> getStatusPrivacy() async {
    await init();
    return _prefs?.getString(_keyStatusPrivacy) ?? 'Все';
  }

  static Future<void> setStatusPrivacy(String privacy) async {
    await init();
    await _prefs?.setString(_keyStatusPrivacy, privacy);
  }

  static Future<Map<String, dynamic>?> getMyStatus() async {
    final statuses = await getStatuses();
    try {
      return statuses.firstWhere((s) => s['isMe'] == true);
    } catch (_) {
      return null;
    }
  }
}

