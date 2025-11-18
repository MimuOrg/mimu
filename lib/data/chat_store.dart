import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/chat_models.dart';
import 'settings_service.dart';

class ChatStore extends ChangeNotifier {
  static const _threadsKey = 'chat_threads_v1';
  static const _contactsKey = 'chat_contacts_v1';

  final List<ChatThread> _threads = [];
  final List<ChatContact> _contacts = [];
  bool _isInitialized = false;

  List<ChatThread> get threads => List.unmodifiable(_threads);
  List<ChatContact> get contacts => List.unmodifiable(_contacts);

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();

    final threadsData = prefs.getString(_threadsKey);
    final contactsData = prefs.getString(_contactsKey);

    if (threadsData != null && threadsData.isNotEmpty) {
      final decoded = (jsonDecode(threadsData) as List<dynamic>)
          .map((e) => ChatThread.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _threads
        ..clear()
        ..addAll(decoded);
    } else {
      _seedDemoChats();
      await _persistThreads();
    }

    if (contactsData != null && contactsData.isNotEmpty) {
      final decodedContacts = (jsonDecode(contactsData) as List<dynamic>)
          .map((e) => ChatContact.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _contacts
        ..clear()
        ..addAll(decodedContacts);
    } else {
      _seedDemoContacts();
      await _persistContacts();
    }

    // Проверка автоудаления сообщений
    await _checkAndDeleteOldMessages();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _checkAndDeleteOldMessages() async {
    final autoDeleteEnabled = SettingsService.getAutoDeleteMessages();
    if (!autoDeleteEnabled) return;

    final deleteTimeHours = SettingsService.getAutoDeleteTime();
    final deleteThreshold = DateTime.now().subtract(Duration(hours: deleteTimeHours));

    bool hasChanges = false;
    for (int i = 0; i < _threads.length; i++) {
      final messages = _threads[i].messages;
      final filteredMessages = messages.where((msg) => msg.timestamp.isAfter(deleteThreshold)).toList();
      
      if (filteredMessages.length != messages.length) {
        _threads[i] = _threads[i].copyWith(messages: filteredMessages);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _persistThreads();
      notifyListeners();
    }
  }

  void _seedDemoContacts() {
    _contacts
      ..clear()
      ..addAll([
        const ChatContact(id: 'friend', name: 'Друг', avatarAsset: 'assets/images/avatar_placeholder.png'),
        const ChatContact(id: 'designer', name: 'Дизайнер', avatarAsset: 'assets/images/avatar_placeholder.png'),
        const ChatContact(id: 'pm', name: 'Менеджер', avatarAsset: 'assets/images/avatar_placeholder.png'),
      ]);
  }

  void _seedDemoChats() {
    final now = DateTime.now();
    _threads
      ..clear()
      ..add(
        ChatThread(
          id: 'friend-chat',
          title: 'Друг',
          avatarAsset: 'assets/images/avatar_placeholder.png',
          isGroup: false,
          participantIds: const ['friend'],
          messages: [
            ChatMessage(
              id: 'm1',
              type: ChatMessageType.text,
              text: 'привет. мессенджер прикольный',
              isMe: false,
              timestamp: now.subtract(const Duration(minutes: 5)),
              isRead: true,
              reactions: const {'👍': 1},
            ),
            ChatMessage(
              id: 'm2',
              type: ChatMessageType.text,
              text: 'лучше макса, всем почти',
              isMe: false,
              timestamp: now.subtract(const Duration(minutes: 4, seconds: 30)),
              isRead: true,
            ),
            ChatMessage(
              id: 'm3',
              type: ChatMessageType.text,
              text: 'почти не считается',
              isMe: true,
              timestamp: now.subtract(const Duration(minutes: 4)),
              isRead: true,
            ),
          ],
          updatedAt: now,
        ),
      );
  }

  Future<void> _persistThreads() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _threadsKey,
      jsonEncode(_threads.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> persistThreads() async => _persistThreads();

  Future<void> _persistContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _contactsKey,
      jsonEncode(_contacts.map((e) => e.toJson()).toList()),
    );
  }

  ChatThread? threadById(String id) {
    try {
      return _threads.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> createChat({
    required String title,
    bool isGroup = false,
    List<String>? participantIds,
    String? avatarAsset,
  }) async {
    final id = 'chat-${DateTime.now().millisecondsSinceEpoch}';
    final chat = ChatThread(
      id: id,
      title: title,
      avatarAsset: avatarAsset ?? 'assets/images/avatar_placeholder.png',
      isGroup: isGroup,
      participantIds: participantIds ?? const [],
      messages: const [],
      updatedAt: DateTime.now(),
    );
    _threads.insert(0, chat);
    await _persistThreads();
    notifyListeners();
    return id;
  }

  Future<void> addMessage(String chatId, ChatMessage message) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    final updatedMessages = List<ChatMessage>.from(_threads[index].messages)..add(message);
    _threads[index] = _threads[index].copyWith(
      messages: updatedMessages,
      updatedAt: message.timestamp,
    );
    _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _persistThreads();
    notifyListeners();
    
    // Периодическая проверка автоудаления (каждые 10 сообщений)
    if (updatedMessages.length % 10 == 0) {
      await _checkAndDeleteOldMessages();
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    final messages = _threads[index].messages.map((message) {
      if (message.id != messageId) return message;
      return message.copyWith(
        text: newText,
        editedText: newText,
        isEdited: true,
      );
    }).toList();
    _threads[index] = _threads[index].copyWith(messages: messages);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    final messages = List<ChatMessage>.from(_threads[index].messages)
      ..removeWhere((message) => message.id == messageId);
    _threads[index] = _threads[index].copyWith(messages: messages);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> addReaction(String chatId, String messageId, String emoji) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    final messages = _threads[index].messages.map((message) {
      if (message.id != messageId) return message;
      final updatedReactions = Map<String, int>.from(message.reactions);
      final currentCount = updatedReactions[emoji] ?? 0;
      if (currentCount > 0) {
        updatedReactions.remove(emoji);
      } else {
        updatedReactions[emoji] = 1;
      }
      return message.copyWith(reactions: updatedReactions);
    }).toList();
    _threads[index] = _threads[index].copyWith(messages: messages);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> updateChatAvatar(String chatId, String avatarAsset) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    _threads[index] = _threads[index].copyWith(avatarAsset: avatarAsset);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> updateChatTitle(String chatId, String title) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    _threads[index] = _threads[index].copyWith(title: title);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> addContact(ChatContact contact) async {
    if (_contacts.any((c) => c.id == contact.id)) return;
    _contacts.add(contact);
    await _persistContacts();
    notifyListeners();
  }

  Future<void> forwardMessage(String fromChatId, String messageId, String toChatId) async {
    final fromThread = threadById(fromChatId);
    if (fromThread == null) return;
    
    try {
      final message = fromThread.messages.firstWhere((m) => m.id == messageId);
    
    // Создаем новое сообщение для пересылки
    final forwardedMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: message.type,
      text: message.text,
      mediaPath: message.mediaPath,
      voiceDurationSeconds: message.voiceDurationSeconds,
      isMe: true,
      timestamp: DateTime.now(),
      isRead: false,
    );
    
      await addMessage(toChatId, forwardedMessage);
    } catch (_) {
      // Сообщение не найдено
      return;
    }
  }

  Future<void> clearChatHistory(String chatId) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    _threads[index] = _threads[index].copyWith(messages: []);
    await _persistThreads();
    notifyListeners();
  }

  List<ChatMessage> getMediaMessages(String chatId) {
    final thread = threadById(chatId);
    if (thread == null) return [];
    return thread.messages.where((m) => 
      m.type == ChatMessageType.image || 
      m.type == ChatMessageType.voice ||
      m.type == ChatMessageType.sticker
    ).toList();
  }

  List<ChatMessage> getFileMessages(String chatId) {
    final thread = threadById(chatId);
    if (thread == null) return [];
    return thread.messages.where((m) => m.type == ChatMessageType.file).toList();
  }

  List<ChatMessage> searchInChat(String chatId, String query) {
    final thread = threadById(chatId);
    if (thread == null) return [];
    final lowerQuery = query.toLowerCase();
    return thread.messages.where((m) => 
      m.text?.toLowerCase().contains(lowerQuery) ?? false
    ).toList();
  }
}
