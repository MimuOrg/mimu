import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:mimu/data/local_storage.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для backup и восстановления данных
class BackupService {
  /// Создать backup всех данных
  static Future<File> createBackup({String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    final chats = LocalStorage.loadAllChats();
    
    final backupData = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'chats': chats.map((c) => c.toJson()).toList(),
      'settings': _exportSettings(prefs),
    };
    
    final jsonString = jsonEncode(backupData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    
    // Шифруем если указан пароль
    final encryptedBytes = password != null 
        ? _encrypt(bytes, password)
        : bytes;
    
    // Сохраняем в файл
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/mimu_backup_$timestamp.mimu');
    await file.writeAsBytes(encryptedBytes);
    
    return file;
  }

  /// Восстановить данные из backup
  static Future<bool> restoreBackup(File backupFile, {String? password}) async {
    try {
      final bytes = await backupFile.readAsBytes();
      final bytesList = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      
      // Расшифровываем если был пароль
      final decryptedBytes = password != null
          ? _decrypt(bytesList, password)
          : bytesList;
      
      final jsonString = utf8.decode(decryptedBytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Восстанавливаем чаты
      final chats = (data['chats'] as List)
          .map((json) => ChatThread.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      for (final chat in chats) {
        await LocalStorage.saveChat(chat);
        // Восстанавливаем сообщения
        if (chat.messages.isNotEmpty) {
          await LocalStorage.saveMessages(chat.id, chat.messages);
        }
      }
      
      // Восстанавливаем настройки
      if (data['settings'] != null) {
        await _importSettings(data['settings'] as Map<String, dynamic>);
      }
      
      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  /// Проверить целостность backup
  static Future<bool> verifyBackup(File backupFile) async {
    try {
      final bytes = await backupFile.readAsBytes();
      if (bytes.isEmpty) return false;
      
      // Пытаемся декодировать JSON
      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Проверяем наличие обязательных полей
      return data.containsKey('version') &&
             data.containsKey('timestamp') &&
             data.containsKey('chats');
    } catch (e) {
      return false;
    }
  }

  /// Экспорт настроек
  static Map<String, dynamic> _exportSettings(SharedPreferences prefs) {
    final settings = <String, dynamic>{};
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        settings[key] = value;
      }
    }
    
    return settings;
  }

  /// Импорт настроек
  static Future<void> _importSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final entry in settings.entries) {
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(entry.key, value.cast<String>());
      }
    }
  }

  /// Простое шифрование (для production использовать более надежное)
  static Uint8List _encrypt(Uint8List data, String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;
    final encrypted = Uint8List(data.length);
    
    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ key[i % key.length];
    }
    
    return encrypted;
  }

  /// Расшифровка
  static Uint8List _decrypt(Uint8List encrypted, String password) {
    return _encrypt(encrypted, password); // XOR обратим
  }
}

