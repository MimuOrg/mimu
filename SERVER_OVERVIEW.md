# Полная сводка по серверу Mimu (Rust Backend)

## 📋 Общая информация

**Технологический стек:**
- **Язык:** Rust (edition 2021)
- **Веб-фреймворк:** Axum 0.8
- **Асинхронность:** Tokio 1.44
- **База данных:** PostgreSQL 16 (через sqlx 0.8)
- **Кэш/Очереди:** Redis 7
- **Хранилище файлов:** MinIO (S3-совместимое)
- **TURN сервер:** Coturn (для WebRTC)
- **Мониторинг:** Prometheus метрики

**Архитектура:**
- RESTful API (HTTP/HTTPS)
- WebSocket для real-time коммуникации (звонки, события)
- Многопоточность через Tokio runtime
- Rate limiting через Governor
- CORS поддержка для Flutter клиента

---

## 📁 Структура проекта

```
server/
├── src/
│   ├── main.rs              # Точка входа, инициализация сервера
│   ├── state.rs             # AppState - глобальное состояние приложения
│   ├── web/                 # HTTP REST API
│   │   ├── router.rs        # Маршрутизация всех endpoints
│   │   ├── error.rs         # Обработка ошибок API
│   │   ├── validate.rs      # Валидация входных данных
│   │   ├── auth/            # Аутентификация и авторизация
│   │   │   ├── handlers.rs  # Регистрация, логин, сброс пароля, refresh
│   │   │   ├── jwt.rs       # JWT токены (выдача и проверка)
│   │   │   ├── password.rs  # Хеширование паролей (Argon2)
│   │   │   └── validate.rs  # Валидация полей регистрации
│   │   ├── users/           # Управление пользователями
│   │   │   ├── handlers.rs  # Поиск, профиль, PreKeys, верификация
│   │   │   └── mod.rs
│   │   ├── subscriptions/   # Премиум подписки
│   │   │   ├── handlers.rs  # Покупка, восстановление, валидация
│   │   │   └── mod.rs
│   │   └── calls/           # Звонки (WebRTC)
│   │       ├── handlers.rs  # TURN credentials
│   │       ├── history.rs   # История звонков
│   │       └── mod.rs
│   └── ws/                  # WebSocket обработка
│       ├── handler.rs        # WebSocket соединения и маршрутизация событий
│       ├── events.rs         # Структуры событий звонков
│       ├── redis_listener.rs # Redis pub/sub для multi-instance
│       ├── call_timeout.rs   # Фоновые задачи для таймаутов звонков
│       └── mod.rs
├── migrations/               # SQL миграции базы данных
│   ├── 0001_init.sql        # Основная схема (users, chats, messages, subscriptions)
│   ├── 0002_add_signing_public_key.sql
│   └── 0003_calls.sql        # Таблица call_sessions
├── tests/                   # Интеграционные тесты
│   ├── integration_calls.rs
│   └── README.md
├── Cargo.toml               # Зависимости Rust
├── docker-compose.yml       # Инфраструктура (Postgres, Redis, MinIO, Coturn)
├── Dockerfile               # Docker образ для production
├── env.example              # Пример переменных окружения
├── turnserver.conf          # Конфигурация Coturn
├── README.md                # Основная документация
├── README_CALLS.md          # Документация по звонкам
└── TESTING_CALLS.md         # Гайд по тестированию звонков
```

---

## 🔧 Конфигурация и запуск

### Переменные окружения (env.example)

```bash
HOST=0.0.0.0                    # IP для прослушивания
PORT=8080                        # Порт HTTP сервера
RUST_LOG=info                    # Уровень логирования

# PostgreSQL
DATABASE_URL=postgres://mimu:mimu@localhost:5432/mimu
DATABASE_MAX_CONNECTIONS=20

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=change_me_super_secret
JWT_EXPIRATION_HOURS=24

# TURN (Coturn)
TURN_HOST=localhost
TURN_SECRET=change_me_turn_secret
```

### Docker Compose сервисы

1. **postgres** (PostgreSQL 16)
   - Порт: 5432
   - База: `mimu`
   - Пользователь: `mimu` / `mimu`

2. **redis** (Redis 7)
   - Порт: 6379
   - Используется для: refresh tokens, WebSocket pub/sub, кэширование

3. **minio** (MinIO S3)
   - Порт: 9000 (API), 9001 (Console)
   - Хранилище файлов (изображения, видео, документы)

4. **coturn** (TURN сервер)
   - Порт: 3478 (UDP/TCP), 5349 (TLS)
   - Для WebRTC звонков через NAT

5. **migrate** (одноразовый контейнер)
   - Запускает SQL миграции при старте

### Запуск

```bash
# 1. Поднять инфраструктуру
docker compose -f server/docker-compose.yml up -d

# 2. Установить переменные окружения (см. README.md)

# 3. Запустить миграции
cargo install sqlx-cli --no-default-features --features postgres,rustls
sqlx migrate run --source server/migrations

# 4. Запустить сервер
cd server
cargo run
```

---

## 🌐 API Endpoints

### Health & Metrics

- `GET /health` - Проверка состояния (DB, Redis, uptime)
- `GET /metrics` - Prometheus метрики

### Аутентификация (`/auth`)

**POST `/auth/register`**
- Регистрация нового пользователя
- **Rate limit:** 3 запроса/час
- **Тело запроса:**
  ```json
  {
    "public_id": "alice_crypto",
    "password": "secure_password",
    "identity_key": "base64...",      // X25519 public key (32 bytes)
    "fingerprint": "sha256 hex...",   // SHA256(identity_key)
    "signing_public_key": "base64...", // Ed25519 public key (32 bytes)
    "registration_id": 12345,
    "signed_prekey": {
      "key_id": 1,
      "public_key": "base64...",
      "signature": "base64..."
    },
    "one_time_prekeys": [
      {"key_id": 1, "public_key": "base64..."},
      ...
    ],
    "display_name": "Alice",
    "language": "ru"
  }
  ```
- **Ответ:**
  ```json
  {
    "user_id": "uuid",
    "access_token": "jwt...",
    "refresh_token": "hex...",
    "fingerprint": "sha256..."
  }
  ```

**POST `/auth/login`**
- Вход по public_id и паролю
- **Rate limit:** 5 запросов/15 минут
- **Тело:** `{"public_id": "...", "password": "..."}`
- **Ответ:** То же что и register

**POST `/auth/reset-password`**
- Сброс пароля по identity_key
- **Rate limit:** 3 запроса/час
- **Тело:** `{"identity_key": "base64...", "new_password": "..."}`

**POST `/auth/refresh`**
- Обновление access_token через refresh_token
- **Тело:** `{"refresh_token": "hex..."}`
- **Ответ:** `{"access_token": "...", "refresh_token": "..."}`

### Пользователи (`/users`)

**GET `/users/search?q=query`**
- Поиск пользователей по public_id (ILIKE)
- Лимит: 50 результатов
- **Ответ:** Массив `UserSearchItem`

**GET `/users/{public_id}`**
- Профиль пользователя
- **Ответ:** `UserProfile` (public_id, display_name, fingerprint, avatar_url, bio, is_online, last_seen, language, created_at)

**GET `/users/{public_id}/prekeys`**
- Получить PreKey Bundle для Signal Protocol
- **Ответ:**
  ```json
  {
    "identity_key": "base64...",
    "registration_id": 12345,
    "fingerprint": "sha256...",
    "signed_prekey": {
      "id": "uuid",
      "key_id": 1,
      "public_key": "base64...",
      "signature": "base64..."
    },
    "one_time_prekey": {
      "id": "uuid",
      "key_id": 1,
      "public_key": "base64..."
    }
  }
  ```
- **Важно:** One-time prekey атомарно помечается как `used`

**POST `/users/{public_id}/verify`** (требует JWT)
- Верификация контакта (QR код, голос, ручная)
- **Тело:** `{"verified_fingerprint": "...", "method": "qr_code|voice|manual", "notes": "..."}`
- Сохраняется в `user_verifications`

**PUT `/users/me`** (требует JWT)
- Обновление своего профиля
- **Тело:** `{"display_name": "...", "bio": "...", "avatar_url": "...", "language": "...", "settings": {...}}`

### Подписки (`/subscriptions`)

**POST `/subscriptions/purchase`**
- Покупка премиум подписки
- **Тело:**
  ```json
  {
    "prid_hash": "sha256 hex...",      // SHA256(PRID)
    "subscription_tier": "premium|ultra",
    "user_fingerprint": "sha256...",
    "signature": "base64...",          // Ed25519 подпись
    "payment_proof": "...",
    "payment_method": "stripe|crypto|voucher"
  }
  ```
- **Валидация:** Проверка Ed25519 подписи над `"mimu-sub-v1|{prid_hash}|{tier}"`
- **Ответ:** `{"subscription_id": "uuid", "tier": "...", "activated_at": "...", "expires_at": "...", "status": "active"}`

**GET `/subscriptions/restore`** (требует JWT)
- Восстановление активных подписок по fingerprint
- **Ответ:** Массив `RestoreItem`

**POST `/subscriptions/validate`**
- Проверка валидности подписки по PRID
- **Тело:** `{"prid": "uuid string", "signature": "base64..."}`
- **Ответ:** `{"valid": true|false, "tier": "...", "expires_at": "..."}`

### Звонки (`/calls`)

**GET `/calls/turn-credentials`** (требует JWT)
- Получить временные TURN credentials (TTL: 1 час)
- **Ответ:**
  ```json
  {
    "urls": [
      "turn:host:3478?transport=udp",
      "turn:host:3478?transport=tcp",
      "turns:host:5349?transport=tcp"
    ],
    "username": "timestamp:user_id",
    "credential": "base64(hmac_sha1)",
    "ttl": 3600
  }
  ```

**GET `/calls`** (требует JWT)
- История звонков пользователя
- **Ответ:** Массив `CallSession`

**GET `/calls/{id}`** (требует JWT)
- Детали конкретного звонка

### WebSocket (`/ws`)

**Подключение:** `ws://host:8080/ws` с заголовком `Authorization: Bearer {access_token}`

**События звонков:**
- `call_offer` - Исходящий звонок
- `call_answer` - Принятие звонка
- `ice_candidate` - ICE кандидаты для WebRTC
- `call_hangup` - Завершение звонка
- `call_heartbeat` - Пульс активного звонка (каждые 30 сек)

**Формат события:**
```json
{
  "type": "call_offer",
  "call_id": "uuid",
  "from_user_id": "uuid",
  "to_user_id": "uuid",
  "call_type": "audio|video",
  "encrypted_payload": "base64..."  // Зашифрованный SDP/ICE
}
```

**Маршрутизация:**
- События доставляются через in-memory `DashMap` (локально) и Redis pub/sub (multi-instance)
- Канал Redis: `ws:user:{user_id}`

---

## 🗄️ База данных (PostgreSQL)

### Основные таблицы

#### `users`
- `id` (UUID, PK) - Внутренний ID
- `public_id` (TEXT, UNIQUE) - Публичный идентификатор (username)
- `password_hash` (TEXT) - Argon2 хеш пароля
- `identity_key` (BYTEA, UNIQUE) - X25519 публичный ключ (32 bytes)
- `signing_public_key` (BYTEA) - Ed25519 публичный ключ (32 bytes)
- `registration_id` (INTEGER) - Signal Protocol registration ID
- `fingerprint` (TEXT, UNIQUE) - SHA256(identity_key) в hex
- `display_name`, `bio`, `avatar_url`, `language`
- `settings` (JSONB) - Пользовательские настройки
- `is_online`, `last_seen`
- `created_at`, `updated_at`

#### `signed_prekeys`
- `id` (UUID, PK)
- `user_id` (UUID, FK → users)
- `key_id` (INTEGER)
- `public_key` (BYTEA)
- `signature` (BYTEA)
- `created_at`

#### `one_time_prekeys`
- `id` (UUID, PK)
- `user_id` (UUID, FK → users)
- `key_id` (INTEGER)
- `public_key` (BYTEA)
- `used` (BOOLEAN) - Атомарно помечается при использовании
- `used_at`, `created_at`

#### `subscriptions`
- `id` (UUID, PK)
- `prid_hash` (TEXT, UNIQUE) - SHA256(PRID)
- `user_fingerprint` (TEXT) - Связь с пользователем через fingerprint
- `tier` (ENUM: premium, ultra)
- `status` (ENUM: active, expired, cancelled)
- `activated_at`, `expires_at`
- `payment_proof`, `payment_method`
- `signature` (BYTEA) - Ed25519 подпись
- `signature_verified` (BOOLEAN)
- `metadata` (JSONB)

#### `user_verifications`
- `id` (UUID, PK)
- `verifier_id` (UUID, FK → users)
- `verified_user_id` (UUID, FK → users)
- `method` (TEXT) - qr_code, voice, manual
- `verified_fingerprint` (TEXT)
- `trust_level` (ENUM: unverified, verified, trusted)
- `notes` (TEXT)
- `verified_at`
- **UNIQUE:** (verifier_id, verified_user_id)

#### `chat_threads`
- `id` (UUID, PK)
- `type` (ENUM: direct, group, channel, secret, cloud)
- `title`, `avatar_url`
- `created_by` (UUID, FK → users)
- `settings` (JSONB)
- `created_at`, `updated_at`

#### `chat_participants`
- `chat_id` (UUID, FK → chat_threads)
- `user_id` (UUID, FK → users)
- `role` (ENUM: owner, admin, member, restricted)
- `joined_at`
- **PK:** (chat_id, user_id)

#### `messages`
- `id` (UUID, PK)
- `chat_id` (UUID, FK → chat_threads)
- `sender_id` (UUID, FK → users, nullable) - NULL для Sealed Sender
- `encrypted_payload` (BYTEA) - Зашифрованное содержимое
- `message_type` (TEXT)
- `metadata` (JSONB)
- `reply_to` (UUID, FK → messages)
- `forwarded_from` (UUID, FK → messages)
- `delivered`, `edited_at`, `deleted_at`, `expires_at`
- `created_at`

#### `message_reads`
- `message_id` (UUID, FK → messages)
- `user_id` (UUID, FK → users)
- `read_at`
- **PK:** (message_id, user_id)

#### `message_reactions`
- `message_id` (UUID, FK → messages)
- `user_id` (UUID, FK → users)
- `emoji` (TEXT)
- `created_at`
- **PK:** (message_id, user_id, emoji)

#### `call_sessions`
- `id` (UUID, PK) - call_id
- `caller_id` (UUID, FK → users)
- `callee_id` (UUID, FK → users)
- `call_type` (ENUM: audio, video)
- `status` (ENUM: ringing, accepted, ended, missed, rejected, failed)
- `started_at`, `accepted_at`, `ended_at`
- `end_reason` (TEXT)
- `last_heartbeat` (TIMESTAMPTZ) - Обновляется на `call_heartbeat`
- `created_at`

---

## 🔐 Безопасность

### Аутентификация
- **JWT токены:** HS256, содержат `user_id` и `fingerprint`
- **Refresh tokens:** Хранятся в Redis (TTL: 30 дней), ротируются при обновлении
- **Пароли:** Argon2 хеширование

### Шифрование
- **Signal Protocol:** E2EE для сообщений и звонков
  - X25519 для key exchange
  - Ed25519 для подписей
  - Double Ratchet для forward secrecy
- **PreKeys:** Signed PreKey + One-Time PreKeys для X3DH
- **Подписки:** Ed25519 подписи для проверки владения ключом

### Rate Limiting
- `/auth/register`: 3 запроса/час
- `/auth/login`: 5 запросов/15 минут
- `/auth/reset-password`: 3 запроса/час
- Через библиотеку `governor` + `tower_governor`

### Валидация
- `public_id`: 3-32 символа, alphanumeric + underscore
- `password`: минимум 8 символов
- `fingerprint`: SHA256 hex (64 символа)
- Base64 декодирование для всех ключей

---

## 📞 Система звонков (WebRTC)

### Архитектура

1. **Signalling:** E2EE через WebSocket (`/ws`)
   - SDP (Offer/Answer) и ICE кандидаты шифруются Signal Protocol
   - Сервер видит только `encrypted_payload` (opaque base64)

2. **Media:** P2P WebRTC (DTLS-SRTP)
   - Прямое соединение между устройствами
   - TURN сервер (Coturn) для NAT traversal

3. **CallKit/ConnectionService:** Нативный UI на iOS/Android

### Поток звонка

1. **Caller:** `WebRTCService.startCall()` → создаёт Offer → шифрует → отправляет `call_offer`
2. **Server:** Создаёт запись в `call_sessions` (status: `ringing`) → пересылает получателю
3. **Callee:** Получает `call_offer` → CallKit показывает входящий звонок
4. **Callee accepts:** Создаёт Answer → шифрует → отправляет `call_answer`
5. **Server:** Обновляет `call_sessions` (status: `accepted`, `accepted_at`)
6. **Both:** Обмениваются ICE candidates (зашифрованными)
7. **Hangup:** Отправляется `call_hangup` → сервер обновляет статус

### Фоновые задачи

**Call Timeout Task** (`src/ws/call_timeout.rs`):
- Запускается каждые 30 секунд
- `ringing > 60s` → статус `missed`
- `accepted > 1h` без heartbeat → статус `ended`

**Heartbeat:**
- Клиент отправляет `call_heartbeat` каждые 30 секунд во время активного звонка
- Обновляет `last_heartbeat` в `call_sessions`

### TURN Credentials

- Генерируются через HMAC-SHA1 (Coturn REST API)
- `username = "{timestamp}:{user_id}"`
- `credential = base64(hmac_sha1(turn_secret, username))`
- TTL: 1 час

---

## 🔄 WebSocket обработка

### Подключение

1. Клиент подключается к `/ws` с JWT токеном
2. Сервер проверяет токен, извлекает `user_id`
3. Создаётся WebSocket соединение
4. `user_id` → `UnboundedSender<Message>` сохраняется в `DashMap`

### Маршрутизация событий

1. **Локальная доставка:** Проверка `DashMap` для `to_user_id`
2. **Redis pub/sub:** Публикация в канал `ws:user:{to_user_id}`
3. **Redis Listener:** Другие инстансы сервера подписываются на каналы своих пользователей

### События

Все события звонков (`CallEvent`) содержат:
- `from_user_id` (добавляется сервером)
- `to_user_id`
- `call_id`
- `encrypted_payload` (base64) - зашифрованный SDP/ICE

**Типы событий:**
- `CallOffer` - Исходящий звонок
- `CallAnswer` - Принятие звонка
- `IceCandidate` - ICE кандидаты
- `CallHangup` - Завершение звонка
- `CallHeartbeat` - Пульс активного звонка

---

## 📊 Мониторинг

### Prometheus метрики

- Доступны на `/metrics`
- Через `axum-prometheus`
- Метрики HTTP запросов (latency, status codes)

### Логирование

- Формат: JSON (через `tracing-subscriber`)
- Уровень: настраивается через `RUST_LOG`
- Примеры: `RUST_LOG=info`, `RUST_LOG=debug`

### Health Check

`GET /health` возвращает:
```json
{
  "status": "healthy|unhealthy",
  "database": "ok|error",
  "redis": "ok|error",
  "uptime_seconds": 12345
}
```

---

## 🧪 Тестирование

### Интеграционные тесты

- `tests/integration_calls.rs` - Тесты звонков
- Запуск: `cargo test`

### Ручное тестирование

См. `TESTING_CALLS.md` для сценариев:
- Звонок между устройствами в разных сетях (TURN)
- Создание Signal сессии "с нуля"
- Таймауты звонков
- Валидация hangup (только участники)
- CallKit UX тесты

---

## 🚀 Production Deployment

### Docker

- `Dockerfile` для сборки Rust приложения
- Multi-stage build для уменьшения размера образа

### Переменные окружения (production)

**Важно изменить:**
- `JWT_SECRET` - Случайная строка (минимум 32 символа)
- `TURN_SECRET` - Секрет для Coturn
- `DATABASE_URL` - Production PostgreSQL
- `REDIS_URL` - Production Redis

### Безопасность

- CORS: Настроить `allow_origin` на конкретные домены
- Rate limiting: Уже настроено, можно ужесточить
- HTTPS: Использовать reverse proxy (nginx/traefik)
- Secrets: Хранить в секретах (Kubernetes Secrets, AWS Secrets Manager)

---

## 📝 Зависимости (Cargo.toml)

### Основные

- `axum` - HTTP фреймворк
- `tokio` - Асинхронный runtime
- `sqlx` - PostgreSQL драйвер
- `redis` - Redis клиент
- `jsonwebtoken` - JWT
- `argon2` - Хеширование паролей
- `ed25519-dalek` - Ed25519 подписи
- `ring` - Криптография (HMAC-SHA1 для TURN)
- `sha2` - SHA256
- `uuid` - UUID генерация
- `serde` / `serde_json` - Сериализация

### Middleware

- `tower` / `tower-http` - Middleware (CORS, tracing)
- `governor` / `tower_governor` - Rate limiting
- `axum-prometheus` - Prometheus метрики
- `tracing` / `tracing-subscriber` - Логирование

### Утилиты

- `anyhow` - Обработка ошибок
- `thiserror` - Типизированные ошибки
- `dashmap` - Concurrent HashMap для WebSocket соединений
- `futures-util` - WebSocket streams
- `dotenvy` - Загрузка .env файлов

---

## 🔗 Связь с Flutter клиентом

### Конфигурация

Клиент должен использовать:
- `baseUrl = "http://10.147.17.50:8080"` (или production URL)
- `timeout = 15 секунд`

### Заголовки

Все запросы (кроме `/auth/*`) требуют:
```
Authorization: Bearer {access_token}
X-PrID: {public_id}
X-Client-Version: 1.0.0
X-Platform: android|ios
```

### WebSocket

- Подключение: `ws://10.147.17.50:8080/ws`
- Заголовок: `Authorization: Bearer {access_token}`
- Формат сообщений: JSON (`CallEvent`)

---

## 📚 Дополнительная документация

- `README.md` - Быстрый старт
- `README_CALLS.md` - Детали системы звонков
- `TESTING_CALLS.md` - Гайд по тестированию звонков
- `tests/README.md` - Документация по тестам

---

## ⚠️ Важные замечания

1. **E2EE:** Сервер НЕ видит содержимое сообщений и SDP/ICE (только `encrypted_payload`)
2. **PreKeys:** One-time prekeys атомарно помечаются как `used` при выдаче
3. **Подписки:** Связь с пользователем через `fingerprint`, не через `user_id` (приватность)
4. **Multi-instance:** WebSocket события доставляются через Redis pub/sub
5. **Таймауты:** Фоновые задачи автоматически завершают зависшие звонки
6. **Валидация:** Hangup может отправить только участник звонка (caller или callee)

---

## 🎯 Текущий статус

**Реализовано:**
- ✅ Регистрация/логин с Signal Protocol ключами
- ✅ JWT аутентификация
- ✅ Управление пользователями
- ✅ PreKey Bundle для E2EE
- ✅ Премиум подписки с Ed25519 подписями
- ✅ WebSocket для звонков
- ✅ TURN credentials
- ✅ История звонков
- ✅ Фоновые задачи для таймаутов
- ✅ Multi-instance поддержка через Redis

**В разработке / TODO:**
- ⏳ Сообщения (таблицы есть, API endpoints нужно добавить)
- ⏳ Файлы (MinIO интеграция)
- ⏳ Группы/каналы (таблицы есть, логика частично)
- ⏳ Уведомления (push notifications)

