import 'package:flutter/services.dart';

/// Platform channel for audio routing (speaker/earpiece/headphones).
class AudioManager {
  static const MethodChannel _channel = MethodChannel('mimu.audio');

  /// Enable/disable speakerphone.
  /// Returns true if successful, false otherwise.
  static Future<bool> setSpeakerphoneOn(bool on) async {
    try {
      final result = await _channel.invokeMethod<bool>('setSpeakerphoneOn', {'on': on});
      return result ?? false;
    } catch (e) {
      // Fallback: return false if platform channel not available
      return false;
    }
  }

  /// Get current speakerphone state.
  static Future<bool> isSpeakerphoneOn() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSpeakerphoneOn');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Set audio mode for calls.
  /// mode: 'normal' | 'speaker' | 'earpiece' | 'bluetooth'
  static Future<bool> setAudioMode(String mode) async {
    try {
      final result = await _channel.invokeMethod<bool>('setAudioMode', {'mode': mode});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}

