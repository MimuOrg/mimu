import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для хранения черновиков сообщений
class DraftService {
  static const String _draftPrefix = 'draft_';

  /// Сохранить черновик для чата
  static Future<void> saveDraft(String chatId, String text) async {
    if (text.trim().isEmpty) {
      await deleteDraft(chatId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_draftPrefix$chatId', text);
  }

  /// Получить черновик для чата
  static Future<String?> getDraft(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_draftPrefix$chatId');
  }

  /// Удалить черновик для чата
  static Future<void> deleteDraft(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftPrefix$chatId');
  }

  /// Получить все черновики (для синхронизации)
  static Future<Map<String, String>> getAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_draftPrefix));
    final drafts = <String, String>{};
    for (final key in keys) {
      final chatId = key.substring(_draftPrefix.length);
      final text = prefs.getString(key);
      if (text != null) {
        drafts[chatId] = text;
      }
    }
    return drafts;
  }
}

