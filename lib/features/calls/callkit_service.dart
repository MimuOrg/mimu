import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:audioplayers/audioplayers.dart';

/// CallKit/ConnectionService wrapper with enhanced UX.
class CallKitService {
  StreamSubscription? _sub;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _dialTonePlayer = AudioPlayer();
  bool _isRinging = false;

  Future<void> init({
    required Future<void> Function(String callId) onAccept,
    required Future<void> Function(String callId) onDecline,
    required Future<void> Function(String callId) onEnd,
  }) async {
    _sub = FlutterCallkitIncoming.onEvent.listen((event) async {
      final e = event?.event;
      final body = event?.body ?? {};
      final callId = (body['id'] ?? body['callId'] ?? '').toString();
      if (callId.isEmpty) return;

      switch (e) {
        case Event.actionCallAccept:
          await _stopRingtone();
          // Open app if needed (CallKit handles this automatically)
          await onAccept(callId);
          break;
        case Event.actionCallDecline:
          await _stopRingtone();
          // Don't open app, just send hangup
          await onDecline(callId);
          break;
        case Event.actionCallEnded:
          await _stopRingtone();
          await _stopDialTone();
          await onEnd(callId);
          break;
      }
    });
  }

  Future<void> showIncoming({
    required String callId,
    required String nameCaller,
    required bool hasVideo,
  }) async {
    await _playRingtone();
    await FlutterCallkitIncoming.showCallkitIncoming({
      'id': callId,
      'nameCaller': nameCaller,
      'appName': 'Mimu',
      'type': hasVideo ? 1 : 0, // 0 audio, 1 video
      'duration': 60000, // 60 seconds timeout
      'textAccept': 'Принять',
      'textDecline': 'Отклонить',
      'android': {
        'isCustomNotification': false,
        'ringtonePath': 'system_default', // Use system ringtone
        'vibrationPattern': [0, 1000, 500, 1000], // Vibrate pattern
      },
      'ios': {
        'supportsVideo': hasVideo,
        'ringtonePath': 'system_default',
      },
    });
  }

  Future<void> startOutgoing({required String callId}) async {
    await _playDialTone();
  }

  Future<void> _playRingtone() async {
    if (_isRinging) return;
    _isRinging = true;
    try {
      // Play system ringtone (in production, use asset ringtone)
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      // Note: In production, load from assets
      // await _ringtonePlayer.play(AssetSource('sounds/incoming_call.mp3'));
    } catch (e) {
      // Fallback: use system sound
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _stopRingtone() async {
    if (!_isRinging) return;
    _isRinging = false;
    await _ringtonePlayer.stop();
  }

  Future<void> _playDialTone() async {
    try {
      await _dialTonePlayer.setReleaseMode(ReleaseMode.loop);
      // Note: In production, load from assets
      // await _dialTonePlayer.play(AssetSource('sounds/dial_tone.mp3'));
    } catch (e) {
      // Fallback: silent (dial tone is usually handled by system)
    }
  }

  Future<void> _stopDialTone() async {
    await _dialTonePlayer.stop();
  }

  Future<void> endAll() async {
    await _stopRingtone();
    await _stopDialTone();
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _ringtonePlayer.dispose();
    await _dialTonePlayer.dispose();
  }
}


