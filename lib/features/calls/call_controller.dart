import 'package:mimu/data/services/websocket_service.dart';
import 'package:mimu/features/calls/callkit_service.dart';
import 'package:mimu/features/calls/webrtc_service.dart';

/// High-level controller: WS signalling + CallKit UI + WebRTC engine.
class CallController {
  final WebSocketService ws;
  final CallKitService callKit;
  final WebRTCService webrtc;

  // Simple in-memory mapping: callId -> peer user id
  final Map<String, String> _peers = {};

  CallController({
    required this.ws,
    required this.callKit,
    required this.webrtc,
  });

  Future<void> init() async {
    await callKit.init(
      onAccept: (callId) async {
        final peerId = _peers[callId];
        if (peerId == null) return;
        await webrtc.acceptIncomingCall(
          callId: callId,
          fromUserId: peerId,
          video: true,
          alwaysRelay: false,
        );
      },
      onDecline: (callId) async {
        final peerId = _peers[callId];
        if (peerId != null) {
          await webrtc.hangup(
            callId: callId,
            toUserId: peerId,
            reason: 'rejected',
          );
        }
        await callKit.endAll();
      },
      onEnd: (callId) async {
        await webrtc.dispose();
      },
    );

    ws.inboundEvents.listen((event) async {
      // Incoming call offer triggers CallKit.
      if (event['type'] == 'call_offer') {
        final callId = event['call_id'].toString();
        final fromUserId = (event['from_user_id'] ?? '').toString();
        if (fromUserId.isNotEmpty) {
          _peers[callId] = fromUserId;
        }
        await callKit.showIncoming(
          callId: callId,
          nameCaller: fromUserId.isEmpty ? 'Unknown' : fromUserId,
          hasVideo: true,
        );
      }

      await webrtc.handleInboundEvent(event);
    });
  }
}


