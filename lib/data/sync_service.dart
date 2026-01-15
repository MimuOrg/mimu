import 'dart:async';
import 'package:mimu/data/message_api.dart';
import 'package:mimu/data/chat_store.dart';
import 'package:mimu/data/settings_service.dart';

/// Сервис для синхронизации данных с сервером
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final MessageApi _messageApi = MessageApi();
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Начать автоматическую синхронизацию
  void startAutoSync(ChatStore chatStore) {
    stopAutoSync();
    
    // Синхронизация каждые 30 секунд
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isSyncing) {
        syncAllChats(chatStore);
      }
    });
  }

  /// Остановить автоматическую синхронизацию
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Синхронизировать все чаты
  Future<void> syncAllChats(ChatStore chatStore) async {
    if (_isSyncing) return;
    
    final syncEnabled = SettingsService.getSyncEnabled();
    if (!syncEnabled) return;

    _isSyncing = true;
    
    try {
      final threads = chatStore.threads;
      for (final thread in threads) {
        await chatStore.syncMessages(thread.id);
        // Небольшая задержка между чатами
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // Ошибка синхронизации не критична
    } finally {
      _isSyncing = false;
    }
  }

  /// Синхронизировать конкретный чат
  Future<void> syncChat(ChatStore chatStore, String chatId) async {
    if (_isSyncing) return;
    
    final syncEnabled = SettingsService.getSyncEnabled();
    if (!syncEnabled) return;

    _isSyncing = true;
    
    try {
      await chatStore.syncMessages(chatId);
    } catch (e) {
      // Ошибка синхронизации не критична
    } finally {
      _isSyncing = false;
    }
  }

  /// Принудительная синхронизация
  Future<void> forceSync(ChatStore chatStore, {String? chatId}) async {
    _isSyncing = true;
    
    try {
      if (chatId != null) {
        await chatStore.syncMessages(chatId);
      } else {
        await syncAllChats(chatStore);
      }
    } finally {
      _isSyncing = false;
    }
  }
}

