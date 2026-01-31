import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mimu/features/calls/calls_api.dart';
import 'package:mimu/data/services/websocket_service.dart';
import 'package:mimu/features/calls/signal_crypto.dart';
import 'package:mimu/features/calls/signal_crypto_real.dart';
import 'package:mimu/data/services/signal_service.dart';

/// WebRTC P2P calls.
/// Signalling must be E2EE (Signal Protocol) – server only relays opaque blobs.
class WebRTCService {
  final WebSocketService _ws;
  final CallsApi _callsApi;
  final SignalCrypto _crypto;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentPeerId;
  String? _currentCallId;

  // Renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  // callId -> encrypted SDP offer (base64)
  final Map<String, String> _pendingOffers = {};

  void Function(MediaStream stream)? onRemoteStream;
  void Function(String callId, String fromUserId)? onIncomingOffer;
  void Function(String callId)? onHangup;

  WebRTCService(this._ws, this._callsApi, [SignalCrypto? crypto])
      : _crypto = crypto ?? SignalService().crypto;

  Future<void> initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _createPeerConnection({required bool alwaysRelay}) async {
    final turn = await _callsApi.getTurnCredentials();

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': turn.urls,
          'username': turn.username,
          'credential': turn.credential,
        }
      ],
      'iceTransportPolicy': alwaysRelay ? 'relay' : 'all',
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
    };

    _pc = await createPeerConnection(config);

    _pc!.onIceCandidate = (candidate) {
      if (_currentPeerId == null || _currentCallId == null) return; // No active call
      // For RealSignalCrypto, use sync encryptToBase64 (peerId handled internally)
      final encryptedPayload = _crypto.encryptToBase64(jsonEncode(candidate.toMap()));
      _ws.sendJson({
        'type': 'ice_candidate',
        'call_id': _currentCallId,
        'to_user_id': _currentPeerId!,
        'encrypted_payload': encryptedPayload,
      });
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteRenderer.srcObject = _remoteStream;
        onRemoteStream?.call(event.streams[0]);
      }
    };
  }

  Future<void> startCall({
    required String toUserId,
    required String callId,
    required bool video,
    required bool alwaysRelay,
  }) async {
    _currentPeerId = toUserId;
    _currentCallId = callId;
    if (_crypto is RealSignalCrypto) {
      (_crypto as RealSignalCrypto).setPeerId(toUserId);
    }
    _ws.startCallHeartbeat(callId, toUserId);
    await _createPeerConnection(alwaysRelay: alwaysRelay);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    
    _localRenderer.srcObject = _localStream;

    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    // RealSignalCrypto uses setPeerId() context
    final encryptedPayload = _crypto.encryptToBase64(jsonEncode(offer.toMap()));
    
    _ws.sendJson({
      'type': 'call_offer',
      'call_id': callId,
      'to_user_id': toUserId,
      'call_type': video ? 'video' : 'audio',
      'encrypted_payload': encryptedPayload,
    });
  }

  /// Handle inbound WS event (already decrypted by Signal layer, here только JSON).
  Future<void> handleInboundEvent(Map<String, dynamic> event) async {
    switch (event['type']) {
      case 'call_offer':
        final callId = event['call_id'] as String;
        final fromUserId = event['from_user_id'] as String? ?? '';
        _currentCallId = callId;
        _currentPeerId = fromUserId.isNotEmpty ? fromUserId : _currentPeerId;
        if (fromUserId.isNotEmpty && _crypto is RealSignalCrypto) {
          (_crypto as RealSignalCrypto).setPeerId(fromUserId);
        }
        _pendingOffers[callId] = event['encrypted_payload'] as String;
        onIncomingOffer?.call(callId, fromUserId);
        break;
      case 'call_answer':
        if (_pc == null) return;
        final callId = event['call_id'] as String? ?? _currentCallId ?? '';
        if (callId.isNotEmpty) {
          _currentCallId = callId;
        }
        final encrypted = event['encrypted_payload'] as String;
        final fromUserId = event['from_user_id'] as String? ?? _currentPeerId ?? '';
        if (fromUserId.isNotEmpty && _crypto is RealSignalCrypto) {
          (_crypto as RealSignalCrypto).setPeerId(fromUserId);
        }
        final decoded = _crypto.decryptFromBase64(encrypted);
        final decodedMap = jsonDecode(decoded);
        final sdp = RTCSessionDescription(decodedMap['sdp'], decodedMap['type']);
        await _pc!.setRemoteDescription(sdp);
        // Start heartbeat when call is accepted
        if (callId.isNotEmpty && fromUserId.isNotEmpty) {
          _ws.startCallHeartbeat(callId, fromUserId);
        }
        break;
      case 'ice_candidate':
        if (_pc == null) return;
        final callId = event['call_id'] as String? ?? _currentCallId ?? '';
        if (callId.isNotEmpty) {
          _currentCallId = callId;
        }
        final encrypted = event['encrypted_payload'] as String;
        final fromUserId = event['from_user_id'] as String? ?? _currentPeerId ?? '';
        if (fromUserId.isNotEmpty && _crypto is RealSignalCrypto) {
          (_crypto as RealSignalCrypto).setPeerId(fromUserId);
        }
        final decoded = _crypto.decryptFromBase64(encrypted);
        final decodedMap = jsonDecode(decoded);
        final cand = RTCIceCandidate(decodedMap['candidate'], decodedMap['sdpMid'], decodedMap['sdpMLineIndex']);
        await _pc!.addCandidate(cand);
        break;
      case 'call_hangup':
        final callId = event['call_id'] as String;
        _ws.stopCallHeartbeat();
        onHangup?.call(callId);
        await dispose();
        break;
    }
  }

  /// Accept stored incoming offer -> create answer and send call_answer.
  Future<void> acceptIncomingCall({
    required String callId,
    required String fromUserId,
    required bool video,
    required bool alwaysRelay,
  }) async {
    _currentPeerId = fromUserId;
    _currentCallId = callId;
    if (_crypto is RealSignalCrypto) {
      (_crypto as RealSignalCrypto).setPeerId(fromUserId);
    }
    final encrypted = _pendingOffers.remove(callId);
    if (encrypted == null) return;

    await _createPeerConnection(alwaysRelay: alwaysRelay);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    
    _localRenderer.srcObject = _localStream;
    
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    // RealSignalCrypto uses setPeerId() context
    final decoded = _crypto.decryptFromBase64(encrypted);
    
    final decodedMap = jsonDecode(decoded);
    
    final offer = RTCSessionDescription(decodedMap['sdp'], decodedMap['type']);
    await _pc!.setRemoteDescription(offer);

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    // RealSignalCrypto uses setPeerId() context
    final encryptedAnswer = _crypto.encryptToBase64(jsonEncode(answer.toMap()));
    
    _ws.sendJson({
      'type': 'call_answer',
      'call_id': callId,
      'to_user_id': fromUserId,
      'encrypted_payload': encryptedAnswer,
    });
  }

  Future<void> hangup({
    required String callId,
    required String toUserId,
    String reason = 'ended',
  }) async {
    _ws.stopCallHeartbeat();
    _ws.sendJson({
      'type': 'call_hangup',
      'call_id': callId,
      'to_user_id': toUserId,
      'reason': reason,
    });
    await dispose();
  }

  /// Switch audio output (speaker/earpiece/headphones).
  Future<void> setSpeakerphoneOn(bool on) async {
    await Helper.setSpeakerphoneOn(on);
  }

  /// Mute/unmute microphone.
  Future<void> setMicrophoneMute(bool mute) async {
    if (_localStream == null) return;
    final audioTracks = _localStream!.getAudioTracks();
    for (final track in audioTracks) {
      track.enabled = !mute;
    }
  }

  /// Enable/disable camera.
  Future<void> setVideoEnabled(bool enabled) async {
    if (_localStream == null) return;
    final videoTracks = _localStream!.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = enabled;
    }
  }

  /// Switch camera.
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> dispose() async {
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
    await _localStream?.dispose();
    await _pc?.close();
    _localStream = null;
    _pc = null;
    _currentPeerId = null;
    _currentCallId = null;
  }
}


