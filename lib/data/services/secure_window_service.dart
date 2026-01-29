import 'dart:io';
import 'package:flutter/services.dart';

/// Запрет скриншотов в секретных чатах (Android FLAG_SECURE).
/// При входе в секретный чат вызывать [setSecureWindow(true)],
/// при выходе — [setSecureWindow(false)].
class SecureWindowService {
  static const MethodChannel _channel = MethodChannel('mimu/secure_window');

  /// Включить/выключить FLAG_SECURE на окне (Android).
  /// На iOS не делает ничего.
  static Future<void> setSecureWindow(bool secure) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } catch (_) {}
  }
}
