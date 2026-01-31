import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
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

      if (e == Event.actionCallAccept) {
        await _stopRingtone();
        await onAccept(callId);
      } else if (e == Event.actionCallDecline) {
        await _stopRingtone();
        await onDecline(callId);
      } else if (e == Event.actionCallEnded) {
        await _stopRingtone();
        await _stopDialTone();
        await onEnd(callId);
      }
    });
  }

  Future<void> showIncoming({
    required String callId,
    required String nameCaller,
    required bool hasVideo,
  }) async {
    await _playRingtone();
    await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
      id: callId,
      nameCaller: nameCaller,
      appName: 'Mimu',
      type: hasVideo ? 1 : 0,
      duration: 60000,
      textAccept: 'Принять',
      textDecline: 'Отклонить',
      android: AndroidParams(
        isCustomNotification: false,
        ringtonePath: 'system_default',
      ),
      ios: IOSParams(
        supportsVideo: hasVideo,
        ringtonePath: 'system_default',
      ),
    ));
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


