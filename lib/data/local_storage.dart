import 'package:hive_flutter/hive_flutter.dart';
import 'package:mimu/data/models/chat_models.dart';

/// Локальное хранилище для оффлайн режима
class LocalStorage {
  static const String _messagesBox = 'messages';
  static const String _chatsBox = 'chats';
  static const String _contactsBox = 'contacts';
  
  static bool _isInitialized = false;

  /// Инициализация Hive
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // Регистрация адаптеров
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatThreadAdapter());
    }
    
    // Открытие боксов
    await Hive.openBox(_messagesBox);
    await Hive.openBox(_chatsBox);
    await Hive.openBox(_contactsBox);
    
    _isInitialized = true;
  }

  /// Сохранить сообщения чата
  static Future<void> saveMessages(String chatId, List<ChatMessage> messages) async {
    final box = Hive.box(_messagesBox);
    await box.put(chatId, messages.map((m) => m.toJson()).toList());
  }

  /// Загрузить сообщения чата
  static List<ChatMessage> loadMessages(String chatId) {
    final box = Hive.box(_messagesBox);
    final data = box.get(chatId);
    if (data == null) return [];
    
    return (data as List)
        .map((json) => ChatMessage.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Сохранить чат
  static Future<void> saveChat(ChatThread chat) async {
    final box = Hive.box(_chatsBox);
    await box.put(chat.id, chat.toJson());
  }

  /// Загрузить чат
  static ChatThread? loadChat(String chatId) {
    final box = Hive.box(_chatsBox);
    final data = box.get(chatId);
    if (data == null) return null;
    
    return ChatThread.fromJson(Map<String, dynamic>.from(data));
  }

  /// Загрузить все чаты
  static List<ChatThread> loadAllChats() {
    final box = Hive.box(_chatsBox);
    return box.values
        .map((data) => ChatThread.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Очистить данные чата
  static Future<void> clearChat(String chatId) async {
    final messagesBox = Hive.box(_messagesBox);
    final chatsBox = Hive.box(_chatsBox);
    await messagesBox.delete(chatId);
    await chatsBox.delete(chatId);
  }

  /// Получить размер хранилища
  static int getStorageSize() {
    int size = 0;
    size += Hive.box(_messagesBox).length;
    size += Hive.box(_chatsBox).length;
    size += Hive.box(_contactsBox).length;
    return size;
  }
}

// Адаптеры для Hive (упрощенные версии)
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 0;

  @override
  ChatMessage read(BinaryReader reader) {
    return ChatMessage.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer.writeMap(obj.toJson());
  }
}

class ChatThreadAdapter extends TypeAdapter<ChatThread> {
  @override
  final int typeId = 1;

  @override
  ChatThread read(BinaryReader reader) {
    return ChatThread.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, ChatThread obj) {
    writer.writeMap(obj.toJson());
  }
}

