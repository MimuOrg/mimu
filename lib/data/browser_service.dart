import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BrowserService {
  static const String _keyHistory = 'browser_history';
  static const String _keyBookmarks = 'browser_bookmarks';
  static const String _keyBookmarkFolders = 'browser_bookmark_folders';
  static const String _keyDownloads = 'browser_downloads';
  static const String _keyIncognitoMode = 'browser_incognito';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    await init();
    final data = _prefs?.getString(_keyHistory);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> addToHistory(String title, String url) async {
    await init();
    final history = await getHistory();
    history.insert(0, {
      'title': title,
      'url': url,
      'time': DateTime.now().toIso8601String(),
    });
    // Keep only last 100 items
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    await _prefs?.setString(_keyHistory, jsonEncode(history));
  }

  static Future<void> clearHistory() async {
    await init();
    await _prefs?.remove(_keyHistory);
  }

  static Future<void> removeFromHistory(int index) async {
    await init();
    final history = await getHistory();
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      await _prefs?.setString(_keyHistory, jsonEncode(history));
    }
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    await init();
    final data = _prefs?.getString(_keyBookmarks);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> addBookmark(String title, String url) async {
    await init();
    final bookmarks = await getBookmarks();
    if (!bookmarks.any((b) => b['url'] == url)) {
      bookmarks.add({
        'title': title,
        'url': url,
        'icon': '🌐',
        'time': DateTime.now().toIso8601String(),
      });
      await _prefs?.setString(_keyBookmarks, jsonEncode(bookmarks));
    }
  }

  static Future<void> removeBookmark(String url) async {
    await init();
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b['url'] == url);
    await _prefs?.setString(_keyBookmarks, jsonEncode(bookmarks));
  }

  static Future<bool> isBookmarked(String url) async {
    await init();
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b['url'] == url);
  }

  static String _formatTime(String isoString) {
    try {
      final time = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return 'Сейчас';
        }
        return 'Сегодня, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Вчера, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} дня назад';
      } else {
        return '${time.day}.${time.month}.${time.year}';
      }
    } catch (_) {
      return isoString;
    }
  }

  static String formatTime(String isoString) => _formatTime(isoString);

  // Закладки с папками
  static Future<List<Map<String, dynamic>>> getBookmarkFolders() async {
    await init();
    final data = _prefs?.getString(_keyBookmarkFolders);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> addBookmarkFolder(String name) async {
    await init();
    final folders = await getBookmarkFolders();
    folders.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'time': DateTime.now().toIso8601String(),
    });
    await _prefs?.setString(_keyBookmarkFolders, jsonEncode(folders));
  }

  static Future<void> addBookmarkToFolder(String url, String folderId) async {
    await init();
    final bookmarks = await getBookmarks();
    final index = bookmarks.indexWhere((b) => b['url'] == url);
    if (index != -1) {
      bookmarks[index]['folderId'] = folderId;
      await _prefs?.setString(_keyBookmarks, jsonEncode(bookmarks));
    }
  }

  // Загрузки
  static Future<List<Map<String, dynamic>>> getDownloads() async {
    await init();
    final data = _prefs?.getString(_keyDownloads);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> addDownload(String fileName, String url, String path) async {
    await init();
    final downloads = await getDownloads();
    downloads.insert(0, {
      'fileName': fileName,
      'url': url,
      'path': path,
      'time': DateTime.now().toIso8601String(),
      'size': 0, // Можно добавить реальный размер
    });
    if (downloads.length > 50) {
      downloads.removeRange(50, downloads.length);
    }
    await _prefs?.setString(_keyDownloads, jsonEncode(downloads));
  }

  static Future<void> removeDownload(int index) async {
    await init();
    final downloads = await getDownloads();
    if (index >= 0 && index < downloads.length) {
      downloads.removeAt(index);
      await _prefs?.setString(_keyDownloads, jsonEncode(downloads));
    }
  }

  // Режим инкогнито
  static bool getIncognitoMode() {
    return _prefs?.getBool(_keyIncognitoMode) ?? false;
  }

  static Future<void> setIncognitoMode(bool value) async {
    await init();
    await _prefs?.setBool(_keyIncognitoMode, value);
  }
}

