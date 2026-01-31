import 'package:flutter/material.dart';
import 'package:mimu/app/navigator_key.dart';
import 'package:mimu/app/routes.dart';
import 'package:mimu/data/services/websocket_service.dart';
import 'package:mimu/features/calls/callkit_service.dart';
import 'package:mimu/features/calls/webrtc_service.dart';
import 'package:mimu/features/calls/calls_api.dart';
import 'package:mimu/features/call_screen.dart';

/// High-level controller: WS signalling + CallKit UI + WebRTC engine.
class CallController {
  static final CallController _instance = CallController._internal();
  factory CallController() => _instance;
  
  late final WebSocketService ws;
  late final CallKitService callKit;
  late final WebRTCService webrtc;

  // Simple in-memory mapping: callId -> peer user id
  final Map<String, String> _peers = {};

  CallController._internal() {
    ws = WebSocketService();
    callKit = CallKitService();
    // webrtc needs ws and callsApi
    // CallsApi is simple class
    webrtc = WebRTCService(ws, CallsApi());
  }

  Future<void> init() async {
    await webrtc.initializeRenderers();
    
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
        
        _navigateToCallScreen(peerId, isIncoming: true);
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
        
        // Show CallKit UI
        await callKit.showIncoming(
          callId: callId,
          nameCaller: fromUserId.isEmpty ? 'Unknown' : fromUserId,
          hasVideo: true,
        );
        
        // Also handle WebRTC signalling (decryption etc)
        // But we wait for user accept to create answer
        await webrtc.handleInboundEvent(event);
      } else {
        await webrtc.handleInboundEvent(event);
      }
    });
  }
  
  /// Start an outgoing call
  Future<void> startCall(String toUserId, {bool video = true}) async {
    final callId = DateTime.now().millisecondsSinceEpoch.toString(); // Simple ID
    _peers[callId] = toUserId;
    
    await webrtc.startCall(
      toUserId: toUserId,
      callId: callId,
      video: video,
      alwaysRelay: false,
    );
    
    await callKit.startOutgoing(callId: callId);
    
    _navigateToCallScreen(toUserId, isIncoming: false);
  }

  void _navigateToCallScreen(String userId, {required bool isIncoming}) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          userName: userId, // TODO: Resolve name
          avatarAsset: 'assets/images/avatar_placeholder.png',
          isIncoming: isIncoming,
          isVideoCall: true,
        ),
      ),
    );
  }
}


