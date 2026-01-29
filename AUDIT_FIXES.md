# Исправления по аудиту (~100 пунктов)

Краткая сводка внесённых изменений.

## Критические (1–5)

1. **`ApiError::forbidden`** — добавлен в `server/src/web/error.rs` (`StatusCode::FORBIDDEN`, `code: "forbidden"`).
2. **`ServerConfig.baseUrl`** — уже был (`get baseUrl => getApiBaseUrl()`); проверено использование в auth/crypto.
3. **Crypto-auth роуты** — уже подключены в `router.rs` (`/auth/challenge`, `/auth/verify`, `/auth/register-crypto`).
4. **Wordlists в assets** — в `pubspec.yaml` добавлено `assets/wordlists/`.
5. **S3 в env.example** — добавлены `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`; комментарии про смену секретов.

## Сервер: API и бизнес-логика

6. **IP в сессиях** — уже сохраняется при логине (X-Forwarded-For, X-Real-IP, ConnectInfo).
7. **Кик сессии** — blacklist в Redis по `session_id` уже был; TODO по WebSocket force-logout уточнён в комментарии.
8. **TODO в sessions** — зафиксировано в коде (WS force-logout требует session→conn mapping).
9. **Поиск пользователей** — `GET /users/search` теперь требует `Authorization` (JWT).
10. **mark_as_read** — добавлена проверка участия в чате перед записью в `message_reads`.
11. **view_message** — проверка участника уже была.
12. **get_messages has_more** — оставлено сравнение по `messages.len() == limit` (корректно).
13. **forward_message** — лимит `to_chat_ids` 20 (`FORWARD_TO_CHAT_IDS_CAP`).
14. **Редактирование 48ч** — без изменений (жёстко 48ч); при необходимости вынести в конфиг.
15. **Secret chat в Redis** — без изменений; при необходимости документировать TTL/потери.
16. **list_sessions** — пагинация `limit`/`offset` (по умолчанию 50, макс. 100).
17. **list_blocked** — пагинация `limit`/`offset`.
18. **reports decrypted_content** — лимит 64 KB (`MAX_DECRYPTED_CONTENT_BYTES`).
19. **Rate limit** — только auth (без изменений); при необходимости расширить.
20. **JWT jti/revocation** — без изменений; blacklist по session_id при кике есть.
21. **CORS** — при заданном `ALLOWED_ORIGINS` (comma-separated) используется allowlist; иначе `Any`.
22. **TURN_SECRET / JWT_SECRET** — в `env.example` добавлены предупреждения о смене в проде.

## Сервер: БД и миграции

26. **Миграции 0002/0002a** — без изменений; порядок по имени файлов.
27. **reports reporter_id** — в `0010_reports_sessions_index` FK переведён на `ON DELETE RESTRICT` (сохранение для аудита).
28. **user_sessions last_used_at** — добавлен индекс `idx_user_sessions_last_used_at` в миграции 0010.
29. **Таблица files** — добавлена миграция `0009_files.sql`.
30. **message_hides** — уже есть `PRIMARY KEY (message_id, user_id)`.

## Клиент: API и данные

31. **Channel «Пожаловаться»** — вызов `UserApi().report` уже был; `chatId` по-прежнему `null` при отсутствии chatId канала.
32. **Жалоба на сообщение** — есть в `chat_screen` (report с message_id и decrypted_content).
35. **editMessage двойной вызов** — убран дублирующий вызов `MessageApi().editMessage` в `ChatStore.editMessage`.
36. **deleteMessage mode** — добавлен параметр `mode` (`me`|`all`); для чужих сообщений всегда `me`.
38. **DioApiClient Bearer** — добавлены пути `/users/me`, `/users/search`, `/users/.../verify` для Bearer.
43. **ServerConfig init** — в `main.dart` `ServerConfig.init()` вызывается до `UserService.init()`.
45. **auth_method_screen** — переход на legacy через `AppRoutes.authLegacy` вместо строки `'/auth/legacy'`.

## Клиент: прочее

52. **Экран «Чёрный список»** — есть `BlockedUsersScreen`, маршрут `AppRoutes.blockedUsers`, навигация из настроек.
59. **Дубликаты «Новая папка»** — добавлен `README_LEGACY.md`, помечена как legacy/backup.

## UserApi

- `listSessions` и `listBlocked` поддерживают опциональные `limit`/`offset` для пагинации.

## Дополнительно (продолжение)

- **Pin/Unpin:** в `MessageApi` добавлены `pinMessage(chatId, messageId)` и `unpinMessage(chatId)`. В чате при откреплении вызывается `unpinMessage`, пин-бар скрывается до перезагрузки (`_unpinnedChatIds`).
- **Mute в канале:** для подписчиков канала Mute/Unmute переключает `SettingsService.setChatMuted` (локально), показываются «Уведомления отключены» / «Уведомления включены». API mute на сервере нет.
- **Dev mode:** «Показать статистику» — диалог с сервером и `ConnectivityResult`; «Сбросить сессию» — `UserService.logout()` и переход на `AppRoutes.auth`.
- **Экран «Устройства»:** признак «Это устройство» уже есть (эвристика по user_agent).

## Ещё (продолжение)

- **MessageQueue:** очередь сохраняется в SharedPreferences (`message_queue_v1`); при неудачной отправке после 5 попыток вызывается `MessageQueue.onMessageSendFailed` (в ShellUI показывается SnackBar «Не удалось отправить сообщение»).
- **SettingsService:** при `setHideLastSeenTime` и `setShowOnline` на сервер уходит полная карта настроек `_serverSettingsMap()` (show_online, hide_last_seen), чтобы не затирать другие ключи.
- **README сервера:** добавлено примечание про откат миграций (бэкап и ручной откат).
- **X-Client-Version:** в ApiService добавлен комментарий о поднятии версии при релизе.

## Дополнительный проход (продолжение)

- **JWT в secure storage:** добавлен `flutter_secure_storage`; в `UserService` access_token и refresh_token хранятся в FlutterSecureStorage (Keystore/Keychain), кэш в памяти для синхронных getters; при init() миграция с SharedPreferences; logout/clearAll очищают secure storage.
- **pinnedMessageId в ChatThread:** в модель добавлено поле `pinnedMessageId`; copyWith с флагом `clearPinnedMessage` для отпинки; закреплённое сообщение в чате берётся по `chat.pinnedMessageId` или fallback на первое сообщение.
- **«Закрепить» в контекстном меню:** в меню сообщения добавлен пункт «Закрепить»; вызов `MessageApi().pinMessage` и `ChatStore.setPinnedMessage`; при откреплении — `setPinnedMessage(chatId, null)`.
- **Логи без чувствительных данных:** в `ApiService._handleResponse` при kDebugMode вывод тела и данных идёт через `_redactForLog`, маскирующий access_token, refresh_token, encrypted_payload, decrypted_content и т.д.
- **Мнемоника:** проверено — в `CryptoAuthService.generateMnemonic` используется `Random.secure()` (BIP-39).

## Не охвачено в этом проходе

- Расширение тестов (сервер: auth/messages/chats; клиент: критические потоки).
- OpenAPI/Swagger, единый обзор документации.
- Ряд мелких и косметических пунктов (97–100).

При необходимости можно точечно доработать оставшиеся пункты по списку аудита.
