import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mimu/data/api_service.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mimu/app/navigator_key.dart';
import 'package:mimu/app/routes.dart';
import 'package:flutter/material.dart';

/// Сервис для работы с push-уведомлениями
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  bool _isInitialized = false;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Настройка локальных уведомлений
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Запрос разрешений
    await _requestPermissions();

    // Получение FCM токена
    _fcmToken = await _fcm.getToken();
    if (_fcmToken != null) {
      await _registerDeviceToken(_fcmToken!);
    }

    // Обработка обновления токена
    _fcm.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _registerDeviceToken(newToken);
    });

    // Обработка уведомлений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатия на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Проверка, было ли приложение открыто из уведомления
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Разрешение получено
    }
  }

  static const _keyDeviceId = 'notification_device_id';

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = 'mimu_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(0x7FFFFFFF)}';
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  Future<void> _registerDeviceToken(String token) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final api = ApiService();
      await api.post(
        '/api/v1/notifications/register',
        body: {
          'device_token': token,
          'device_id': deviceId,
          'platform': await _getPlatform(),
        },
      );
    } catch (e) {
      // Ошибка регистрации токена
      print('Failed to register device token: $e');
    }
  }

  Future<String> _getPlatform() async {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (!SettingsService.getNotificationsEnabled()) return;

    // Показываем локальное уведомление
    _showLocalNotification(message);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'mimu_messages',
      'Mimu Messages',
      channelDescription: 'Уведомления о новых сообщениях',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      groupKey: message.data['chat_id'],
      setAsGroupSummary: false,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Mimu',
      notification.body ?? '',
      details,
      payload: message.data['chat_id'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final chatId = message.data['chat_id'];
    if (chatId != null) {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.chat,
        arguments: {'chatId': chatId},
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final chatId = response.payload;
    if (chatId != null) {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.chat,
        arguments: {'chatId': chatId},
      );
    }
  }

  /// Отправить тестовое уведомление
  Future<void> sendTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'mimu_messages',
      'Mimu Messages',
      channelDescription: 'Уведомления о новых сообщениях',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      'Тестовое уведомление',
      'Это тестовое уведомление от Mimu',
      details,
    );
  }

  /// Отключить уведомления
  Future<void> disable() async {
    if (_fcmToken != null) {
      try {
        final api = ApiService();
        await api.post(
          '/api/v1/notifications/unregister',
          body: {'device_token': _fcmToken},
        );
      } catch (e) {
        print('Failed to unregister device token: $e');
      }
    }
  }
}

