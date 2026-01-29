import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/chat_models.dart';
import 'settings_service.dart';
import 'message_api.dart';
import 'file_api.dart';
import 'services/websocket_service.dart';
import 'local_storage.dart';
import 'message_queue.dart';
import 'error_handler.dart';
import 'e2ee/message_e2ee.dart';

class ChatStore extends ChangeNotifier {
  static const _threadsKey = 'chat_threads_v1';
  static const _cloudThreadsKey = 'chat_cloud_threads_v1';
  static const _contactsKey = 'chat_contacts_v1';
  static const _blockedContactsKey = 'chat_blocked_contacts_v1';
  static const _ignoredContactsKey = 'chat_ignored_contacts_v1';
  static const _customContactNamesKey = 'chat_custom_names_v1';

  final List<ChatThread> _threads = [];
  final List<ChatContact> _contacts = [];
  bool _isInitialized = false;
  final Map<String, bool> _blockedContacts = {};
  final Map<String, bool> _ignoredContacts = {};
  final Map<String, String> _customNames = {};
  final WebSocketService _webSocketService = WebSocketService();
  final MessageQueue _messageQueue = MessageQueue();
  final Set<String> _syncingChatIds = {};

  List<ChatThread> get threads => List.unmodifiable(_threads);
  bool isSyncingChat(String chatId) => _syncingChatIds.contains(chatId);
  List<ChatContact> get contacts => List.unmodifiable(_contacts);

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Инициализация локального хранилища
    await LocalStorage.initialize();
    
    final prefs = await SharedPreferences.getInstance();

    final threadsData = prefs.getString(_threadsKey);
    final cloudThreadsData = prefs.getString(_cloudThreadsKey);
    final contactsData = prefs.getString(_contactsKey);
    final blockedData = prefs.getString(_blockedContactsKey);
    final ignoredData = prefs.getString(_ignoredContactsKey);
    final customNamesData = prefs.getString(_customContactNamesKey);

    // Пытаемся загрузить из LocalStorage (приоритет), затем из SharedPreferences
    final localChats = LocalStorage.loadAllChats();
    if (localChats.isNotEmpty) {
      _threads
        ..clear()
        ..addAll(localChats);
      // Загружаем сообщения для каждого чата
      for (final chat in _threads) {
        final messages = LocalStorage.loadMessages(chat.id);
        if (messages.isNotEmpty) {
          final index = _threads.indexWhere((t) => t.id == chat.id);
          if (index != -1) {
            _threads[index] = chat.copyWith(messages: messages);
          }
        }
      }
    } else if (threadsData != null && threadsData.isNotEmpty) {
      final decoded = (jsonDecode(threadsData) as List<dynamic>)
          .map((e) => ChatThread.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _threads
        ..clear()
        ..addAll(decoded);
      // Сохраняем в LocalStorage для будущего использования
      for (final chat in _threads) {
        await LocalStorage.saveChat(chat);
        if (chat.messages.isNotEmpty) {
          await LocalStorage.saveMessages(chat.id, chat.messages);
        }
      }
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

    if (blockedData != null && blockedData.isNotEmpty) {
      final Map<String, dynamic> decoded = jsonDecode(blockedData) as Map<String, dynamic>;
      _blockedContacts
        ..clear()
        ..addAll(decoded.map((key, value) => MapEntry(key, value == true)));
    }
    if (ignoredData != null && ignoredData.isNotEmpty) {
      final Map<String, dynamic> decoded = jsonDecode(ignoredData) as Map<String, dynamic>;
      _ignoredContacts
        ..clear()
        ..addAll(decoded.map((key, value) => MapEntry(key, value == true)));
    }
    if (customNamesData != null && customNamesData.isNotEmpty) {
      final Map<String, dynamic> decoded = jsonDecode(customNamesData) as Map<String, dynamic>;
      _customNames
        ..clear()
        ..addAll(decoded.map((key, value) => MapEntry(key, value.toString())));
      // Применяем пользовательские имена
      for (int i = 0; i < _contacts.length; i++) {
        final custom = _customNames[_contacts[i].id];
        if (custom != null && custom.isNotEmpty) {
          _contacts[i] = _contacts[i].copyWith(name: custom);
        }
      }
      for (int i = 0; i < _threads.length; i++) {
        final chat = _threads[i];
        if (!chat.isGroup && chat.participantIds.isNotEmpty) {
          final participantId = chat.participantIds.first;
          final custom = _customNames[participantId];
          if (custom != null && custom.isNotEmpty) {
            _threads[i] = chat.copyWith(title: custom);
          }
        }
      }
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

  Future<void> _persistContactFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_blockedContactsKey, jsonEncode(_blockedContacts));
    await prefs.setString(_ignoredContactsKey, jsonEncode(_ignoredContacts));
    await prefs.setString(_customContactNamesKey, jsonEncode(_customNames));
  }

  ChatThread? threadById(String id) {
    try {
      return _threads.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  ChatContact? contactById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  ChatContact? contactByName(String name) {
    try {
      return _contacts.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<String> createChat({
    required String title,
    bool isGroup = false,
    ChatType chatType = ChatType.regular,
    List<String>? participantIds,
    String? avatarAsset,
  }) async {
    final id = 'chat-${DateTime.now().millisecondsSinceEpoch}';
    final chat = ChatThread(
      id: id,
      title: title,
      avatarAsset: avatarAsset ?? 'assets/images/avatar_placeholder.png',
      isGroup: isGroup,
      chatType: chatType,
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

    final thread = _threads[index];
    if (thread.messages.any((m) => m.id == message.id)) return;

    ChatMessage finalMessage = message;
    if (thread.chatType == ChatType.secret && message.text != null) {
      final encodedText = base64Url.encode(utf8.encode(message.text!));
      finalMessage = message.copyWith(text: encodedText);
    }

    final updatedMessages = List<ChatMessage>.from(thread.messages)..add(finalMessage);
    _threads[index] = thread.copyWith(
      messages: updatedMessages,
      updatedAt: message.timestamp,
    );
    _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    // Сохраняем в LocalStorage
    await LocalStorage.saveChat(_threads[index]);
    await LocalStorage.saveMessages(chatId, updatedMessages);
    
    await _persistThreads();
    notifyListeners();

    // Отправка на сервер (если сообщение от пользователя)
    if (message.isMe) {
      _sendMessageToServer(chatId, finalMessage).catchError((error) {
        ErrorHandler.logError(error, StackTrace.current, context: 'sendMessageToServer');
      });
    }

    // Simulated replies disabled; use real WS events when available.

    // Periodic check for auto-deletion
    if (updatedMessages.length % 10 == 0) {
      await _checkAndDeleteOldMessages();
    }
  }

  /// Заменить локальный id сообщения на server message_id (для edit/delete по API)
  void _updateMessageId(String chatId, String oldId, String newId) {
    final index = _threads.indexWhere((t) => t.id == chatId);
    if (index == -1) return;
    final thread = _threads[index];
    final messages = thread.messages.map((m) {
      if (m.id == oldId) return m.copyWith(id: newId);
      return m;
    }).toList();
    _threads[index] = thread.copyWith(messages: messages);
    notifyListeners();
  }

  /// Отправка сообщения на сервер с обработкой ошибок
  Future<void> _sendMessageToServer(String chatId, ChatMessage message) async {
    try {
      final messageApi = MessageApi();
      
      if (message.type == ChatMessageType.text) {
        final encrypted = await MessageE2EE.encryptJsonForChat(chatId, {
          't': 'text',
          'text': message.text ?? '',
        });
        final result = await messageApi.sendMessage(
          chatId: chatId,
          messageType: 'text',
          encryptedPayloadBase64: encrypted,
        );
        
        if (result['success'] != true) {
          throw Exception(result['error'] ?? 'Failed to send message');
        }
        // Сервер возвращает message_id (UUID) — обновляем локальное сообщение, чтобы edit/delete работали
        final data = result['data'] as Map<String, dynamic>?;
        final serverMessageId = data?['message_id']?.toString();
        if (serverMessageId != null && serverMessageId.isNotEmpty) {
          _updateMessageId(chatId, message.id, serverMessageId);
        }
      }
      // TODO: Обработка других типов сообщений
    } catch (error) {
      // Если ошибка сети, добавляем в очередь
      if (ErrorHandler.isNetworkError(error)) {
        await _messageQueue.enqueue(
          chatId: chatId,
          messageId: message.id,
          messageData: {
            'type': message.type.name,
            'text': message.text,
            'replyToMessageId': null,
          },
        );
      } else {
        // Другие ошибки логируем
        ErrorHandler.logError(error, StackTrace.current, context: '_sendMessageToServer');
      }
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    
    // Проверяем, можно ли редактировать (48 часов)
    final message = _threads[index].messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );
    
    final age = DateTime.now().difference(message.timestamp);
    if (age.inHours > 48) {
      throw Exception('Сообщение слишком старое для редактирования');
    }
    
    // Обновляем локально
    final messages = _threads[index].messages.map((message) {
      if (message.id != messageId) return message;
      return message.copyWith(
        text: newText,
        editedText: newText,
        isEdited: true,
      );
    }).toList();
    
    // Сохраняем в LocalStorage
    await LocalStorage.saveMessages(chatId, messages);
    
    _threads[index] = _threads[index].copyWith(messages: messages);
    await _persistThreads();
    notifyListeners();

    // Отправка на сервер (один вызов)
    try {
      final encrypted = await MessageE2EE.encryptJsonForChat(chatId, {
        't': 'text',
        'text': newText,
      });
      await MessageApi().editMessage(messageId: messageId, encryptedPayloadBase64: encrypted);
    } catch (error) {
      ErrorHandler.logError(error, StackTrace.current, context: 'editMessage');
    }
  }

  /// [mode] "me" — удалить только у себя (hide); "all" — у всех (только свои).
  Future<void> deleteMessage(String chatId, String messageId, {String mode = 'all'}) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    if (mode != 'me' && mode != 'all') mode = 'all';

    final message = _threads[index].messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => ChatMessage(
        id: messageId,
        type: ChatMessageType.text,
        isMe: false,
        timestamp: DateTime.now(),
      ),
    );
    final effectiveMode = message.isMe ? mode : 'me';

    final messages = List<ChatMessage>.from(_threads[index].messages)
      ..removeWhere((m) => m.id == messageId);
    _threads[index] = _threads[index].copyWith(messages: messages);
    await LocalStorage.saveMessages(chatId, messages);
    await _persistThreads();
    notifyListeners();

    try {
      await MessageApi().deleteMessage(messageId: messageId, mode: effectiveMode);
    } catch (error) {
      ErrorHandler.logError(error, StackTrace.current, context: 'deleteMessage');
    }
  }

  /// Синхронизировать сообщения с сервером
  Future<void> syncMessages(String chatId) async {
    _syncingChatIds.add(chatId);
    notifyListeners();
    try {
      final messageApi = MessageApi();
      final result = await messageApi.getMessages(chatId: chatId, limit: 50);

      final data = result['data'];
      if (result['success'] == true && data is Map && data['messages'] is List) {
        final rawMessages = (data['messages'] as List).cast<dynamic>();
        final serverMessages = <ChatMessage>[];
        for (final m in rawMessages) {
          if (m is! Map) continue;
          final id = (m['id'] ?? '').toString();
          final encryptedPayload = (m['encrypted_payload'] ?? '').toString();
          final createdAt = DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now();

          String? text;
          try {
            final clear = await MessageE2EE.decryptJsonForChat(chatId, encryptedPayload);
            if (clear['t'] == 'text') {
              text = (clear['text'] ?? '').toString();
            }
          } catch (_) {
            text = null;
          }

          serverMessages.add(
            ChatMessage(
              id: id.isEmpty ? 'srv-${createdAt.millisecondsSinceEpoch}' : id,
              type: ChatMessageType.text,
              text: text ?? '[encrypted]',
              isMe: false,
              timestamp: createdAt,
              isRead: true,
            ),
          );
        }
        final threadIndex = _threads.indexWhere((t) => t.id == chatId);
        
        if (threadIndex != -1) {
          // Объединяем локальные и серверные сообщения
          final localMessages = _threads[threadIndex].messages;
          final allMessages = <ChatMessage>[];
          final seenIds = <String>{};

          // Добавляем серверные сообщения
          for (final msg in serverMessages) {
            if (!seenIds.contains(msg.id)) {
              allMessages.add(msg);
              seenIds.add(msg.id);
            }
          }

          // Добавляем локальные сообщения, которых нет на сервере
          for (final msg in localMessages) {
            if (!seenIds.contains(msg.id)) {
              allMessages.add(msg);
            }
          }

          // Сортируем по времени
          allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          _threads[threadIndex] = _threads[threadIndex].copyWith(
            messages: allMessages,
            updatedAt: allMessages.isNotEmpty 
                ? allMessages.last.timestamp 
                : _threads[threadIndex].updatedAt,
          );

          await _persistThreads();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing messages: $e');
    } finally {
      _syncingChatIds.remove(chatId);
      notifyListeners();
    }
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
        // Server reactions API not implemented; local-only for now.
      } else {
        updatedReactions[emoji] = 1;
        // Server reactions API not implemented; local-only for now.
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

  /// Set pinned message for chat (after pin via API). Pass null to unpin. Updates local state.
  Future<void> setPinnedMessage(String chatId, String? messageId) async {
    final index = _threads.indexWhere((element) => element.id == chatId);
    if (index == -1) return;
    _threads[index] = messageId == null
        ? _threads[index].copyWith(clearPinnedMessage: true)
        : _threads[index].copyWith(pinnedMessageId: messageId);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> deleteChat(String chatId) async {
    _threads.removeWhere((element) => element.id == chatId);
    await _persistThreads();
    notifyListeners();
  }

  Future<void> addContact(ChatContact contact) async {
    if (_contacts.any((c) => c.id == contact.id)) return;
    _contacts.add(contact);
    await _persistContacts();
    notifyListeners();
  }

  bool isContactBlocked(String contactId) => _blockedContacts[contactId] ?? false;
  bool isContactIgnored(String contactId) => _ignoredContacts[contactId] ?? false;

  Future<void> setContactBlocked(String contactId, bool blocked) async {
    _blockedContacts[contactId] = blocked;
    await _persistContactFlags();
    notifyListeners();
  }

  Future<void> setContactIgnored(String contactId, bool ignored) async {
    _ignoredContacts[contactId] = ignored;
    await _persistContactFlags();
    notifyListeners();
  }

  Future<void> renameContact(String contactId, String newName) async {
    if (newName.isEmpty) return;
    final contactIndex = _contacts.indexWhere((c) => c.id == contactId);
    if (contactIndex != -1) {
      _contacts[contactIndex] = _contacts[contactIndex].copyWith(name: newName);
    }
    _customNames[contactId] = newName;

    for (int i = 0; i < _threads.length; i++) {
      final chat = _threads[i];
      if (!chat.isGroup && chat.participantIds.contains(contactId)) {
        _threads[i] = chat.copyWith(title: newName);
      }
    }

    await _persistContacts();
    await _persistContactFlags();
    await _persistThreads();
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

      MessageApi().forwardMessage(
        messageId: messageId,
        toChatIds: [toChatId],
      ).catchError((error) {
        debugPrint('Failed to forward message on server: $error');
      });
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

  Future<void> addParticipant(String chatId, String participantId) async {
    final index = _threads.indexWhere((t) => t.id == chatId);
    if (index == -1 || !_threads[index].isGroup) return;

    final thread = _threads[index];
    if (thread.participantIds.contains(participantId)) return;

    final updatedParticipants = List<String>.from(thread.participantIds)..add(participantId);
    _threads[index] = thread.copyWith(participantIds: updatedParticipants);

    await _persistThreads();
    notifyListeners();
  }

  Future<void> removeParticipant(String chatId, String participantId) async {
    final index = _threads.indexWhere((t) => t.id == chatId);
    if (index == -1 || !_threads[index].isGroup) return;

    final thread = _threads[index];
    if (!thread.participantIds.contains(participantId)) return;

    final updatedParticipants = List<String>.from(thread.participantIds)..remove(participantId);
    _threads[index] = thread.copyWith(participantIds: updatedParticipants);

    await _persistThreads();
    notifyListeners();
  }

  Future<void> updateChatDescription(String chatId, String newDescription) async {
    final index = _threads.indexWhere((t) => t.id == chatId);
    if (index == -1 || !_threads[index].isGroup) return;

    _threads[index] = _threads[index].copyWith(description: newDescription);

    await _persistThreads();
    notifyListeners();
  }
}
