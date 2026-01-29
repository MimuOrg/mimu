import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mimu/data/server_config.dart';

/// Централизованная обработка ошибок
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Обработать ошибку и вернуть понятное сообщение для пользователя
  static String getUserFriendlyMessage(dynamic error) {
    if (error is SocketException) {
      return 'Нет подключения к интернету. Проверьте соединение.';
    }
    
    if (error is TimeoutException) {
      return 'Превышено время ожидания. Попробуйте позже.';
    }
    
    if (error is HttpException) {
      return 'Ошибка сети. Попробуйте позже.';
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Сессия истекла. Войдите снова.';
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Доступ запрещен.';
    }
    
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Ресурс не найден.';
    }
    
    if (errorString.contains('429') || errorString.contains('rate limit')) {
      return 'Слишком много запросов. Подождите немного.';
    }
    
    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Ошибка сервера. Попробуйте позже.';
    }
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Проблемы с сетью. Проверьте подключение.';
    }
    
    // Общая ошибка
    return 'Произошла ошибка. Попробуйте позже.';
  }

  /// Логировать критическую ошибку
  static void logError(dynamic error, StackTrace? stackTrace, {String? context}) {
    if (kDebugMode) {
      debugPrint('Error${context != null ? " in $context" : ""}: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
    
    // TODO: Отправка в Sentry/Firebase Crashlytics
    // Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Обработать ошибку с автоматическим retry
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        // Проверяем, нужно ли повторять
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }
        
        // Если это последняя попытка, пробрасываем ошибку
        if (attempt >= maxRetries) {
          logError(error, StackTrace.current, context: 'withRetry (final attempt)');
          rethrow;
        }
        
        // Ждем перед следующей попыткой (exponential backoff)
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 2).clamp(0, 30000));
        
        logError(error, StackTrace.current, context: 'withRetry (attempt $attempt)');
      }
    }
    
    throw StateError('Retry logic failed');
  }

  /// Проверить, является ли ошибка сетевой
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
           error is TimeoutException ||
           error is HttpException ||
           error.toString().toLowerCase().contains('network') ||
           error.toString().toLowerCase().contains('connection');
  }

  /// Проверить, можно ли повторить запрос
  static bool canRetry(dynamic error) {
    // Не повторяем для ошибок авторизации и запрета доступа
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('401') || 
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return false;
    }
    
    // Повторяем для сетевых ошибок и ошибок сервера
    return isNetworkError(error) ||
           errorString.contains('500') ||
           errorString.contains('502') ||
           errorString.contains('503') ||
           errorString.contains('504');
  }
}

