import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Сервис аналитики и мониторинга (опциональный, с согласия пользователя)
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isEnabled = false;
  bool _crashReportingEnabled = true; // Crash reporting всегда включен

  /// Инициализация Sentry для crash reporting
  static Future<void> initializeSentry() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = 'YOUR_SENTRY_DSN'; // TODO: Добавить реальный DSN
        options.environment = kDebugMode ? 'development' : 'production';
        options.tracesSampleRate = 0.1; // 10% трассировок
      },
      appRunner: () {
        // App запускается здесь
      },
    );
  }

  /// Логировать ошибку
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        'context': context,
        ...?extra,
      }),
    );
  }

  /// Логировать событие
  void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;
    
    // TODO: Интеграция с Firebase Analytics или другим сервисом
    debugPrint('Event: $eventName, Parameters: $parameters');
  }

  /// Включить/выключить аналитику
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Включить/выключить crash reporting
  void setCrashReportingEnabled(bool enabled) {
    _crashReportingEnabled = enabled;
  }

  /// Логировать производительность
  static Future<void> logPerformance(
    String operation,
    Duration duration,
  ) async {
    if (duration.inMilliseconds > 1000) {
      // Логируем только медленные операции
      await Sentry.captureMessage(
        'Slow operation: $operation took ${duration.inMilliseconds}ms',
        level: SentryLevel.warning,
      );
    }
  }
}

