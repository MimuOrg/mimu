# Полное руководство по реализации Production-Ready элементов

## 📦 Созданные файлы

### Backend (Rust)

1. **Push-уведомления**
   - `server/src/web/notifications/mod.rs`
   - `server/src/web/notifications/handlers.rs` - регистрация device tokens
   - `server/migrations/0004_device_tokens.sql` - таблица для токенов

2. **Background Worker**
   - `server/src/workers/expiring_messages.rs` - удаление просроченных сообщений
   - `server/src/workers/mod.rs`

### Frontend (Flutter)

#### Сервисы данных
1. `lib/data/services/notification_service.dart` - Push-уведомления
2. `lib/data/error_handler.dart` - Обработка ошибок
3. `lib/data/message_queue.dart` - Очередь сообщений
4. `lib/data/local_storage.dart` - Локальная БД (Hive)
5. `lib/data/validators.dart` - Валидация данных
6. `lib/data/media_processor.dart` - Обработка медиа
7. `lib/data/backup_service.dart` - Backup/восстановление
8. `lib/data/analytics_service.dart` - Мониторинг (Sentry)
9. `lib/data/draft_service.dart` - Черновики (уже создан ранее)

#### UI компоненты
10. `lib/features/pinned_message_widget.dart` - Закрепленные сообщения
11. `lib/features/link_preview_widget.dart` - Превью ссылок
12. `lib/features/disappearing_timer_widget.dart` - Таймер исчезающих сообщений
13. `lib/features/dev_mode_screen.dart` - Режим разработчика (уже создан)

## 🔧 Интеграция в существующий код

### 1. Инициализация сервисов в main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация локального хранилища
  await LocalStorage.initialize();
  
  // Инициализация уведомлений
  await NotificationService().initialize();
  
  // Инициализация Sentry (опционально)
  await AnalyticsService.initializeSentry();
  
  // Инициализация очереди сообщений
  MessageQueue().initialize();
  
  // Инициализация ServerConfig
  await ServerConfig.init();
  
  runApp(MyApp());
}
```

### 2. Интеграция ErrorHandler в ApiService

```dart
// В lib/data/api_service.dart
Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
  return await ErrorHandler.withRetry(
    operation: () async {
      // Существующий код запроса
    },
    shouldRetry: ErrorHandler.canRetry,
  );
}
```

### 3. Интеграция MessageQueue в ChatStore

```dart
// В lib/data/chat_store.dart при отправке сообщения
Future<void> _sendMessageToServer(String chatId, ChatMessage message) async {
  try {
    // Попытка отправки
    await MessageApi().sendTextMessage(...);
  } catch (e) {
    // Если ошибка, добавляем в очередь
    await MessageQueue().enqueue(
      chatId: chatId,
      messageId: message.id,
      messageData: {...},
    );
  }
}
```

### 4. Интеграция LocalStorage в ChatStore

```dart
// При загрузке чата
final localMessages = LocalStorage.loadMessages(chatId);
if (localMessages.isNotEmpty) {
  // Показываем локальные сообщения сразу
  // Затем синхронизируем с сервером
}

// При сохранении
await LocalStorage.saveMessages(chatId, messages);
await LocalStorage.saveChat(chat);
```

### 5. Интеграция PinnedMessageWidget в ChatScreen

```dart
// В lib/features/chat_screen.dart после AppBar
if (chat.pinnedMessageId != null) {
  final pinnedMsg = chat.messages.firstWhere(
    (m) => m.id == chat.pinnedMessageId,
    orElse: () => null,
  );
  if (pinnedMsg != null) {
    PinnedMessageWidget(
      message: pinnedMsg,
      onTap: () {
        // Прокрутка к сообщению
      },
      onUnpin: () async {
        // Открепить сообщение
        await MessageApi().unpinMessage(chatId: chat.id);
      },
    ),
  }
}
```

### 6. Интеграция валидации в формы

```dart
// При отправке сообщения
final validation = Validators.validateMessage(text);
if (!validation.isValid) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(validation.errorMessage!)),
  );
  return;
}

// Санитизация текста перед отправкой
final sanitized = Validators.sanitizeText(text);
```

### 7. Интеграция MediaProcessor

```dart
// При отправке изображения
if (await MediaProcessor.shouldCompress(imageFile)) {
  final compressed = await MediaProcessor.compressImage(imageFile);
  if (compressed != null) {
    imageFile = compressed;
  }
}

// Создание thumbnail
final thumbnail = await MediaProcessor.createThumbnail(imageFile);
```

## 📋 Оставшиеся задачи

### Критические (требуют реализации)

1. **Синхронизация данных** - улучшить `lib/data/sync_service.dart`
   - Добавить пагинацию
   - Разрешение конфликтов
   - Индикатор синхронизации

2. **Производительность** - оптимизировать `lib/features/chat_screen.dart`
   - Виртуализация списка (ListView.builder)
   - Ленивая загрузка сообщений
   - Кеширование изображений

3. **Тестирование**
   - Unit тесты для сервисов
   - Integration тесты для API
   - E2E тесты

### Важные (требуют реализации)

4. **Edit/Delete UI** - добавить в `chat_screen.dart`
5. **Глобальный поиск** - создать `search_screen.dart`
6. **Улучшенные группы** - доработать `group_settings_screen.dart`
7. **Статусы доставки** - улучшить индикаторы

### Желательные

8. **Мультиаккаунт** - создать сервис и UI
9. **Saved Messages** - создать экран
10. **Защита от скриншотов** - нативные плагины
11. **Panic Mode** - реализация
12. **Темы** - расширить theme.dart
13. **Статистика** - создать экран

## 🚀 Быстрый старт

1. **Установить зависимости:**
   ```bash
   flutter pub get
   ```

2. **Настроить Firebase:**
   - Создать проект в Firebase Console
   - Добавить `google-services.json` (Android) и `GoogleService-Info.plist` (iOS)
   - Обновить DSN в `analytics_service.dart`

3. **Настроить Sentry:**
   - Создать проект в Sentry
   - Обновить DSN в `analytics_service.dart`

4. **Применить миграции БД:**
   ```bash
   cd server
   psql -d mimu -f migrations/0004_device_tokens.sql
   ```

5. **Интегрировать сервисы:**
   - Следовать инструкциям выше
   - Протестировать каждый компонент

## 📝 Примечания

- Все сервисы созданы как singleton для удобства использования
- ErrorHandler использует exponential backoff для retry
- MessageQueue автоматически обрабатывается при восстановлении связи
- LocalStorage использует Hive для быстрого доступа
- BackupService шифрует данные простым XOR (для production использовать AES)

## 🔒 Безопасность

- Все валидаторы проверяют входные данные
- Санитизация текста предотвращает XSS
- Backup шифруется (можно улучшить)
- Device tokens хранятся безопасно в БД

## ⚡ Производительность

- Hive для быстрого локального доступа
- Кеширование изображений через cached_network_image
- Сжатие медиа перед отправкой
- Ленивая загрузка сообщений (требует реализации)

