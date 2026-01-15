import 'dart:convert';
import 'package:mimu/data/api_service.dart';
import 'package:mimu/data/models/chat_models.dart';
import 'package:mimu/data/server_config.dart';

/// API для работы с сообщениями
class MessageApi {
  static final MessageApi _instance = MessageApi._internal();
  factory MessageApi() => _instance;
  MessageApi._internal();

  final ApiService _api = ApiService();

  /// Отправить текстовое сообщение
  Future<Map<String, dynamic>> sendTextMessage({
    required String chatId,
    required String text,
    String? replyToMessageId,
  }) async {
    final result = await _api.retryRequest(() => _api.post(
      '/api/v1/messages',
      body: {
        'chatId': chatId,
        'type': 'text',
        'text': text,
        'replyToMessageId': replyToMessageId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    if (result['success'] == true && result['data'] != null) {
      return {
        'success': true,
        'messageId': result['data']['messageId'],
        'serverTimestamp': result['data']['timestamp'],
      };
    }

    return result;
  }

  /// Отправить медиа сообщение (изображение, видео)
  Future<Map<String, dynamic>> sendMediaMessage({
    required String chatId,
    required String fileId,
    required String type, // 'image' или 'video'
    String? caption,
    String? replyToMessageId,
  }) async {
    final result = await _api.retryRequest(() => _api.post(
      '/api/v1/messages',
      body: {
        'chatId': chatId,
        'type': type,
        'fileId': fileId,
        'caption': caption,
        'replyToMessageId': replyToMessageId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    if (result['success'] == true && result['data'] != null) {
      return {
        'success': true,
        'messageId': result['data']['messageId'],
        'serverTimestamp': result['data']['timestamp'],
      };
    }

    return result;
  }

  /// Отправить голосовое сообщение
  Future<Map<String, dynamic>> sendVoiceMessage({
    required String chatId,
    required String fileId,
    required int durationSeconds,
    String? replyToMessageId,
  }) async {
    final result = await _api.retryRequest(() => _api.post(
      '/api/v1/messages',
      body: {
        'chatId': chatId,
        'type': 'voice',
        'fileId': fileId,
        'durationSeconds': durationSeconds,
        'replyToMessageId': replyToMessageId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    if (result['success'] == true && result['data'] != null) {
      return {
        'success': true,
        'messageId': result['data']['messageId'],
        'serverTimestamp': result['data']['timestamp'],
      };
    }

    return result;
  }

  /// Отправить файл
  Future<Map<String, dynamic>> sendFileMessage({
    required String chatId,
    required String fileId,
    required String fileName,
    required int fileSize,
    String? caption,
    String? replyToMessageId,
  }) async {
    final result = await _api.retryRequest(() => _api.post(
      '/api/v1/messages',
      body: {
        'chatId': chatId,
        'type': 'file',
        'fileId': fileId,
        'fileName': fileName,
        'fileSize': fileSize,
        'caption': caption,
        'replyToMessageId': replyToMessageId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    if (result['success'] == true && result['data'] != null) {
      return {
        'success': true,
        'messageId': result['data']['messageId'],
        'serverTimestamp': result['data']['timestamp'],
      };
    }

    return result;
  }

  /// Редактировать сообщение
  Future<Map<String, dynamic>> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    final result = await _api.retryRequest(() => _api.put(
      '/api/v1/messages/$messageId',
      body: {
        'chatId': chatId,
        'text': newText,
        'editedAt': DateTime.now().toIso8601String(),
      },
    ));

    return result;
  }

  /// Удалить сообщение
  Future<Map<String, dynamic>> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final result = await _api.retryRequest(() => _api.delete(
      '/api/v1/messages/$messageId',
      headers: {'X-ChatId': chatId},
    ));

    return result;
  }

  /// Добавить реакцию на сообщение
  Future<Map<String, dynamic>> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    final result = await _api.retryRequest(() => _api.post(
      '/api/v1/messages/$messageId/reactions',
      body: {
        'chatId': chatId,
        'emoji': emoji,
      },
    ));

    return result;
  }

  /// Удалить реакцию с сообщения
  Future<Map<String, dynamic>> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    final result = await _api.retryRequest(() => _api.delete(
      '/api/v1/messages/$messageId/reactions',
      headers: {
        'X-ChatId': chatId,
        'X-Emoji': emoji,
      },
    ));

    return result;
  }

  /// Получить сообщения чата
  Future<Map<String, dynamic>> getMessages({
    required String chatId,
    int? limit,
    String? beforeMessageId,
  }) async {
    final queryParams = <String, String>{
      'chatId': chatId,
      if (limit != null) 'limit': limit.toString(),
      if (beforeMessageId != null) 'before': beforeMessageId,
    };

    final result = await _api.retryRequest(() => _api.get(
      '/api/v1/messages',
      queryParams: queryParams,
    ));

    if (result['success'] == true && result['data'] != null) {
      final messages = (result['data']['messages'] as List<dynamic>)
          .map((m) => _messageFromJson(m as Map<String, dynamic>))
          .toList();

      return {
        'success': true,
        'messages': messages,
        'hasMore': result['data']['hasMore'] ?? false,
      };
    }

    return result;
  }

  /// Отметить сообщения как прочитанные
  Future<Map<String, dynamic>> markAsRead({
    required String chatId,
    required String messageId,
  }) async {
    final result = await _api.retryRequest(() => _api.post(
      '/api/v1/messages/$messageId/read',
      body: {
        'chatId': chatId,
      },
    ));

    return result;
  }

  /// Переслать сообщение
  Future<Map<String, dynamic>> forwardMessage({
    required String fromChatId,
    required String messageId,
    required List<String> toChatIds,
  }) async {
    final result = await _api.retryRequest(() => _api.post(
      '/api/v1/messages/$messageId/forward',
      body: {
        'fromChatId': fromChatId,
        'toChatIds': toChatIds,
      },
    ));

    return result;
  }

  /// Преобразовать JSON в ChatMessage
  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      type: _messageTypeFromString(json['type'] as String),
      text: json['text'] as String?,
      mediaPath: json['mediaPath'] as String?,
      voiceDurationSeconds: json['voiceDurationSeconds'] as int?,
      isMe: json['isMe'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      reactions: Map<String, int>.from(json['reactions'] as Map? ?? {}),
      editedText: json['editedText'] as String?,
    );
  }

  /// Преобразовать строку в ChatMessageType
  ChatMessageType _messageTypeFromString(String type) {
    switch (type) {
      case 'text':
        return ChatMessageType.text;
      case 'image':
        return ChatMessageType.image;
      case 'video':
        return ChatMessageType.image; // Используем image для видео тоже
      case 'voice':
        return ChatMessageType.voice;
      case 'file':
        return ChatMessageType.file;
      case 'call':
        return ChatMessageType.call;
      case 'location':
        return ChatMessageType.location;
      case 'poll':
        return ChatMessageType.poll;
      case 'sticker':
        return ChatMessageType.sticker;
      default:
        return ChatMessageType.text;
    }
  }
}

