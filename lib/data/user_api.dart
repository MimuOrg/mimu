import 'package:mimu/data/services/dio_api_client.dart';

/// API: блокировки, жалобы, сессии
class UserApi {
  static final UserApi _instance = UserApi._internal();
  factory UserApi() => _instance;
  UserApi._internal();

  final _dio = DioApiClient().dio;

  /// Профиль пользователя (публичный; is_online/last_seen с учётом settings.show_online)
  Future<Map<String, dynamic>> getProfile(String publicId) async {
    final resp = await _dio.get('/users/$publicId');
    return resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
  }

  /// Заблокировать пользователя (blocked_id UUID или public_id в теле)
  Future<void> blockUser({String? blockedId, String? publicId}) async {
    final data = <String, dynamic>{};
    if (blockedId != null) data['blocked_id'] = blockedId;
    if (publicId != null) data['public_id'] = publicId;
    await _dio.post('/api/v1/users/block', data: data);
  }

  /// Разблокировать (identifier = UUID или public_id в path)
  Future<void> unblockUser(String identifier) async {
    await _dio.delete('/api/v1/users/block/$identifier');
  }

  /// Пожаловаться: отправить расшифрованный контент для модератора
  Future<Map<String, dynamic>> report({
    String? messageId,
    String? chatId,
    required String decryptedContent,
    String? reason,
  }) async {
    final resp = await _dio.post(
      '/api/v1/report',
      data: {
        if (messageId != null) 'message_id': messageId,
        if (chatId != null) 'chat_id': chatId,
        'decrypted_content': decryptedContent,
        if (reason != null) 'reason': reason,
      },
    );
    return resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
  }

  /// Список активных сессий (устройств). [limit] 1–100, [offset] для пагинации.
  Future<List<Map<String, dynamic>>> listSessions({int? limit, int? offset}) async {
    final q = <String, dynamic>{};
    if (limit != null) q['limit'] = limit;
    if (offset != null) q['offset'] = offset;
    final resp = await _dio.get('/api/v1/sessions', queryParameters: q.isEmpty ? null : q);
    final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
    final list = data['sessions'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Завершить сессию (кик устройства)
  Future<void> kickSession(String sessionId) async {
    await _dio.delete('/api/v1/sessions/$sessionId');
  }

  /// Список заблокированных пользователей. [limit] 1–100, [offset] для пагинации.
  Future<List<Map<String, dynamic>>> listBlocked({int? limit, int? offset}) async {
    final q = <String, dynamic>{};
    if (limit != null) q['limit'] = limit;
    if (offset != null) q['offset'] = offset;
    final resp = await _dio.get('/api/v1/users/blocked', queryParameters: q.isEmpty ? null : q);
    final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
    final list = data['blocked'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Обновить профиль пользователя (включая настройки)
  Future<void> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? language,
    Map<String, dynamic>? settings,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (language != null) data['language'] = language;
    if (settings != null) data['settings'] = settings;
    await _dio.put('/users/me', data: data);
  }
}
