import 'dart:async';
import 'dart:convert';

import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/user_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Real WS client for Mimu backend.
/// IMPORTANT: payloads for calls must be E2EE-encrypted on device (Signal Protocol) BEFORE sending.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeatTimer;
  String? _activeCallId;

  final _inbound = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get inboundEvents => _inbound.stream;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    await UserService.init();
    final token = UserService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('No access token. Login/register first.');
    }

    final base = ServerConfig.getApiBaseUrl()
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final baseUri = Uri.parse('$base/ws');
    final uri = baseUri.replace(queryParameters: {
      ...baseUri.queryParameters,
      'token': token,
    });

    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen((msg) {
      try {
        final decoded = jsonDecode(msg as String) as Map<String, dynamic>;
        _inbound.add(decoded);
      } catch (_) {
        // ignore invalid frames
      }
    }, onDone: () {
      _channel = null;
      _stopHeartbeat();
    }, onError: (_) {
      _channel = null;
      _stopHeartbeat();
    });
  }

  /// Start heartbeat for active call (sends ping every 30s).
  void startCallHeartbeat(String callId, String toUserId) {
    _activeCallId = callId;
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_activeCallId != null && isConnected) {
        sendJson({
          'type': 'call_heartbeat',
          'call_id': _activeCallId,
          'to_user_id': toUserId,
        });
      }
    });
  }

  /// Stop heartbeat when call ends.
  void stopCallHeartbeat() {
    _activeCallId = null;
    _stopHeartbeat();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    await _sub?.cancel();
    await _inbound.close();
    _channel?.sink.close();
    _channel = null;
  }

  void sendJson(Map<String, dynamic> event) {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(jsonEncode(event));
  }

  /// Send typing indicator
  void sendTyping({
    required String chatId,
    required String toUserId,
    required bool isTyping,
  }) {
    sendJson({
      'type': 'typing',
      'chat_id': chatId,
      'to_user_id': toUserId,
      'is_typing': isTyping,
    });
  }
}
