import 'dart:async';
import 'dart:convert';
import 'package:mimu/data/message_api.dart';
import 'package:mimu/data/error_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _queueKey = 'message_queue_v1';

/// Очередь отправки сообщений для оффлайн режима
class MessageQueue {
  static final MessageQueue _instance = MessageQueue._internal();
  factory MessageQueue() => _instance;
  MessageQueue._internal();

  final List<QueuedMessage> _queue = [];
  final MessageApi _messageApi = MessageApi();
  bool _isProcessing = false;
  StreamSubscription<dynamic>? _connectivitySubscription;

  /// Вызывается при неудачной отправке после всех попыток (chatId, messageId). Можно показать SnackBar.
  static void Function(String chatId, String messageId)? onMessageSendFailed;

  /// Добавить сообщение в очередь
  Future<void> enqueue({
    required String chatId,
    required String messageId,
    required Map<String, dynamic> messageData,
  }) async {
    _queue.add(QueuedMessage(
      chatId: chatId,
      messageId: messageId,
      data: messageData,
      timestamp: DateTime.now(),
      retryCount: 0,
    ));
    await _saveQueue();
    _processQueue();
  }

  static bool _hasConnection(dynamic result) {
    if (result is List) return (result as List).any((e) => e != ConnectivityResult.none);
    return result != ConnectivityResult.none;
  }

  /// Обработать очередь
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    final result = await Connectivity().checkConnectivity();
    if (!_hasConnection(result)) return;

    _isProcessing = true;
    while (_queue.isNotEmpty) {
      final message = _queue.first;
      try {
        await ErrorHandler.withRetry(
          operation: () => _sendMessage(message),
          shouldRetry: ErrorHandler.canRetry,
        );
        _queue.removeAt(0);
        await _saveQueue();
      } catch (e) {
        message.retryCount++;
        if (message.retryCount >= 5) {
          _queue.removeAt(0);
          await _saveQueue();
          onMessageSendFailed?.call(message.chatId, message.messageId);
        } else {
          await Future.delayed(Duration(seconds: message.retryCount * 2));
        }
        break;
      }
    }
    _isProcessing = false;
  }

  Future<void> _sendMessage(QueuedMessage message) async {
    await _messageApi.sendTextMessage(
      chatId: message.chatId,
      text: message.data['text'] as String,
      replyToMessageId: message.data['replyToMessageId'] as String?,
    );
  }

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final hasConnection = _hasConnection(result);
      if (hasConnection) _processQueue();
    });
    _loadQueue();
    _processQueue();
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _queue.map((m) => m.toJson()).toList();
      await prefs.setString(_queueKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>?;
      if (list == null) return;
      _queue.clear();
      for (final e in list) {
        final m = QueuedMessage.fromJson(Map<String, dynamic>.from(e as Map));
        if (m != null) _queue.add(m);
      }
    } catch (_) {}
  }

  void clear() {
    _queue.clear();
    _saveQueue();
  }

  int get queueLength => _queue.length;

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

class QueuedMessage {
  final String chatId;
  final String messageId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;

  QueuedMessage({
    required this.chatId,
    required this.messageId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'messageId': messageId,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  static QueuedMessage? fromJson(Map<String, dynamic> json) {
    try {
      final ts = DateTime.tryParse(json['timestamp'] as String? ?? '');
      if (ts == null) return null;
      return QueuedMessage(
        chatId: json['chatId'] as String? ?? '',
        messageId: json['messageId'] as String? ?? '',
        data: Map<String, dynamic>.from(json['data'] is Map ? json['data'] as Map : {}),
        timestamp: ts,
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

