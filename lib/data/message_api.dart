import 'package:dio/dio.dart';
import 'package:mimu/data/services/dio_api_client.dart';
import 'package:mimu/data/e2ee/message_e2ee.dart';

/// API для работы с сообщениями
class MessageApi {
  static final MessageApi _instance = MessageApi._internal();
  factory MessageApi() => _instance;
  MessageApi._internal();

  final Dio _dio = DioApiClient().dio;

  /// Send encrypted message (server stores encrypted_payload as-is).
  /// Contract:
  /// Header: Authorization: Bearer <jwt>
  /// Body: { chat_id, message_type, encrypted_payload, reply_to?, expires_at? }
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String messageType,
    required String encryptedPayloadBase64,
    String? replyToMessageId,
    DateTime? expiresAt,
  }) async {
    final resp = await _dio.post(
      '/api/v1/messages',
      data: {
        'chat_id': chatId,
        'message_type': messageType,
        'encrypted_payload': encryptedPayloadBase64,
        if (replyToMessageId != null) 'reply_to': replyToMessageId,
        if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
      },
    );
    // Server returns 201 with { message_id, chat_id, created_at } (snake_case)
    final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
    return {'success': true, 'data': data};
  }

  /// Fetch messages (encrypted_payload is base64 from server).
  Future<Map<String, dynamic>> getMessages({
    required String chatId,
    int? limit,
    String? beforeMessageId,
  }) async {
    final resp = await _dio.get(
      '/api/v1/messages',
      queryParameters: {
        'chat_id': chatId,
        if (limit != null) 'limit': limit,
        if (beforeMessageId != null) 'before': beforeMessageId,
      },
    );
    return {'success': true, 'data': resp.data};
  }

  /// Edit message (encrypted payload replaced). Backend: POST /api/v1/messages/{id}/edit
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String encryptedPayloadBase64,
  }) async {
    await _dio.post(
      '/api/v1/messages/$messageId/edit',
      data: {'encrypted_payload': encryptedPayloadBase64},
    );
  }

  /// Delete message. Backend: DELETE /api/v1/messages/{id}?mode=me|all
  Future<void> deleteMessage({
    required String messageId,
    required String mode, // "me" | "all"
  }) async {
    await _dio.delete(
      '/api/v1/messages/$messageId',
      queryParameters: {'mode': mode},
    );
  }

  Future<void> markAsRead({required String messageId}) async {
    await _dio.post('/api/v1/messages/$messageId/read');
  }

  Future<void> forwardMessage({
    required String messageId,
    required List<String> toChatIds,
  }) async {
    await _dio.post(
      '/api/v1/messages/$messageId/forward',
      data: {'to_chat_ids': toChatIds},
    );
  }

  /// Pin message in chat. Backend: POST /api/v1/chats/{id}/pin
  Future<void> pinMessage({required String chatId, required String messageId}) async {
    await _dio.post(
      '/api/v1/chats/$chatId/pin',
      data: {'message_id': messageId},
    );
  }

  /// Unpin message in chat. Backend: DELETE /api/v1/chats/{id}/pin
  Future<void> unpinMessage(String chatId) async {
    await _dio.delete('/api/v1/chats/$chatId/pin');
  }

  /// Add reaction. Backend: POST /api/v1/messages/{id}/reactions
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    await _dio.post(
      '/api/v1/messages/$messageId/reactions',
      data: {'emoji': emoji},
    );
  }

  /// Remove reaction. Backend: DELETE /api/v1/messages/{id}/reactions
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    await _dio.delete(
      '/api/v1/messages/$messageId/reactions',
      queryParameters: {'emoji': emoji},
    );
  }

  /// Send plain text (encrypts via E2EE then sendMessage). For queue/offline use.
  /// Warning: Assumes 1-to-1 chat where chatId is the recipient User ID.
  Future<Map<String, dynamic>> sendTextMessage({
    required String chatId,
    required String text,
    String? replyToMessageId,
  }) async {
    final encrypted = await MessageE2EE.encryptJsonForOneToOne(chatId, {'t': 'text', 'text': text});
    return sendMessage(
      chatId: chatId,
      messageType: 'text',
      encryptedPayloadBase64: encrypted,
      replyToMessageId: replyToMessageId,
    );
  }
}

