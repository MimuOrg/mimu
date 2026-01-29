# Контракт API: что принимает сервер и что отправляет клиент

Краткая справка по каждому эндпоинту: заголовки, тело запроса/ответа и код клиента.

---

## 1. Сообщения (Messages)

### 1.1 Отправка сообщения

| | Сервер (принимает) | Клиент (отправляет) |
|---|-------------------|---------------------|
| **Метод** | `POST /api/v1/messages` | `_dio.post('/api/v1/messages', data: {...})` |
| **Заголовки** | `Authorization: Bearer <jwt>` | DioApiClient добавляет Bearer из UserService |
| **Тело (JSON)** | `SendMessageRequest`: | `data`: |
| | `chat_id` — UUID (string) | `'chat_id': chatId` |
| | `message_type` — string | `'message_type': messageType` |
| | `encrypted_payload` — string (base64) | `'encrypted_payload': encryptedPayloadBase64` |
| | `reply_to?` — UUID (string), опционально | `if (replyToMessageId != null) 'reply_to': replyToMessageId` |
| | `expires_at?` — ISO 8601 datetime, опционально | `if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String()` |

**Ответ сервера (201):**
```json
{
  "message_id": "uuid-v7",
  "chat_id": "uuid",
  "created_at": "2026-01-29T12:00:00Z"
}
```
Клиент: `resp.data` → `{'success': true, 'data': { message_id, chat_id, created_at }}`, в ChatStore подставляется `message_id` в локальное сообщение.

---

### 1.2 Получение списка сообщений

| | Сервер (принимает) | Клиент (отправляет) |
|---|-------------------|---------------------|
| **Метод** | `GET /api/v1/messages` | `_dio.get('/api/v1/messages', queryParameters: {...})` |
| **Заголовки** | `Authorization: Bearer <jwt>` | через DioApiClient |
| **Query** | `GetMessagesQuery`: | `queryParameters`: |
| | `chat_id` — UUID | `'chat_id': chatId` |
| | `limit?` — i64, опционально | `if (limit != null) 'limit': limit` |
| | `before?` — UUID (id сообщения), опционально | `if (beforeMessageId != null) 'before': beforeMessageId` |

**Ответ сервера (200):**
```json
{
  "messages": [
    {
      "id": "uuid",
      "chat_id": "uuid",
      "sender_id": "uuid",
      "message_type": "text",
      "encrypted_payload": "base64",
      "metadata": {},
      "reply_to": null,
      "forwarded_from": null,
      "edited_at": null,
      "deleted_at": null,
      "expires_at": null,
      "created_at": "2026-01-29T12:00:00Z"
    }
  ],
  "has_more": true
}
```

---

### 1.3 Редактирование сообщения

| | Сервер | Клиент |
|---|--------|--------|
| **Метод** | `POST /api/v1/messages/{id}/edit` | `_dio.post('/api/v1/messages/$messageId/edit', data: {...})` |
| **Заголовки** | `Authorization: Bearer <jwt>` | через DioApiClient |
| **Тело** | `EditMessageRequest`: `encrypted_payload` — string (base64) | `data: {'encrypted_payload': encryptedPayloadBase64}` |
| **Ответ** | 204 No Content | — |

---

### 1.4 Удаление сообщения

| | Сервер | Клиент |
|---|--------|--------|
| **Метод** | `DELETE /api/v1/messages/{id}?mode=me\|all` | `_dio.delete('/api/v1/messages/$messageId', queryParameters: {'mode': mode})` |
| **Query** | `mode` — "me" (скрыть у себя) или "all" (удалить для всех) | `'mode': mode` |
| **Ответ** | 204 No Content | — |

---

### 1.5 Пересылка сообщения

| | Сервер | Клиент |
|---|--------|--------|
| **Метод** | `POST /api/v1/messages/{id}/forward` | `_dio.post('/api/v1/messages/$messageId/forward', data: {...})` |
| **Тело** | `ForwardMessageRequest`: `to_chat_ids` — `Vec<Uuid>` | `data: {'to_chat_ids': toChatIds}` (список UUID-строк) |
| **Ответ** | 200 + `{ "success": true, "forwarded_message_ids": [...] }` | — |

---

### 1.6 Отметка прочтения

| | Сервер | Клиент |
|---|--------|--------|
| **Метод** | `POST /api/v1/messages/{id}/read` | `_dio.post('/api/v1/messages/$messageId/read')` |
| **Ответ** | 204 No Content | — |

---

## 2. Файлы (Files)

Сервер не принимает multipart-загрузку. Схема: **presign → PUT в S3 → confirm**.

### 2.1 Presign (получить URL для загрузки)

| | Сервер (принимает) | Клиент (отправляет) |
|---|-------------------|---------------------|
| **Метод** | `POST /api/v1/files/presign` | `_dio.post('/api/v1/files/presign', data: {...})` |
| **Заголовки** | `Authorization: Bearer <jwt>` | через DioApiClient |
| **Тело** | `PresignUploadRequest`: | `data`: |
| | `size` — i64 (байты) | `'size': fileSize` |
| | `content_type` — string (MIME) | `'content_type': contentType` |
| | `filename?` — string | `'filename': name` |
| | `file_type` — enum: "image" \| "video" \| "audio" \| "voice" \| "document" | `'file_type': _serverFileType(type)` (клиент: 'file' → 'document') |

**Ответ сервера (200):**
```json
{
  "file_id": "uuid-v7",
  "upload_url": "https://s3.../presigned-put-url",
  "file_key": "images/uuid.jpg",
  "expires_in": 900
}
```
Клиент сохраняет `file_id` и `upload_url` для следующего шага.

---

### 2.2 Загрузка файла в S3 (клиент → S3, не в API сервера)

| | Сервер не участвует | Клиент |
|---|---------------------|--------|
| **Метод** | — | `http.put(Uri.parse(uploadUrl), headers: {...}, body: bytes)` |
| **URL** | — | из ответа presign: `upload_url` |
| **Заголовки** | — | `Content-Type: <тот же, что в presign>`, `Content-Length: bytes.length` |
| **Тело** | — | сырые байты файла |

---

### 2.3 Confirm (подтвердить загрузку)

| | Сервер (принимает) | Клиент (отправляет) |
|---|-------------------|---------------------|
| **Метод** | `POST /api/v1/files/confirm` | `_dio.post('/api/v1/files/confirm', data: {...})` |
| **Заголовки** | `Authorization: Bearer <jwt>` | через DioApiClient |
| **Тело** | `ConfirmUploadRequest`: | `data`: |
| | `file_id` — UUID (из presign) | `'file_id': fileId` |
| | `actual_size` — i64 | `'actual_size': bytes.length` |
| | `checksum?`, `thumbnail_key?`, `duration_seconds?`, `width?`, `height?` — опционально | клиент отправляет только `file_id` и `actual_size` |

**Ответ сервера (200):**
```json
{
  "file_id": "uuid",
  "status": "confirmed",
  "download_url": "https://s3.../presigned-get-url"
}
```
Клиент возвращает вызывающему коду: `fileId`, `url` (download_url), `size`, `mimeType`.

---

### 2.4 Скачивание (получить presigned URL, затем GET)

| | Сервер (принимает) | Клиент (отправляет) |
|---|-------------------|---------------------|
| **Метод** | `GET /api/v1/files/{id}/presign` | `_dio.get('/api/v1/files/$fileId/presign')` |
| **Заголовки** | `Authorization: Bearer <jwt>` | через DioApiClient |

**Ответ сервера (200):**
```json
{
  "file_id": "uuid",
  "download_url": "https://s3.../presigned-get-url",
  "content_type": "image/jpeg",
  "size": 12345,
  "expires_in": 3600
}
```
Клиент: берёт `download_url`, делает `http.get(Uri.parse(downloadUrl))`, сохраняет байты в файл.

---

### 2.5 Информация о файле

| | Сервер | Клиент |
|---|--------|--------|
| **Метод** | `GET /api/v1/files/{id}/info` | `_dio.get('/api/v1/files/$fileId/info')` |
| **Ответ** | 200 + `FileInfoResponse` (file_id, file_type, content_type, size, filename, checksum, thumbnail_url, duration_seconds, width, height, uploaded_by, created_at) | парсит `resp.data` |

---

### 2.6 Удаление файла

| | Сервер | Клиент |
|---|--------|--------|
| **Метод** | `DELETE /api/v1/files/{id}` | `_dio.delete('/api/v1/files/$fileId')` |
| **Ответ** | 204 No Content | — |

---

## 3. Звонки (Calls) — TURN-учётные данные

| | Сервер (принимает) | Клиент (отправляет) |
|---|-------------------|---------------------|
| **Метод** | `GET /calls/turn-credentials` | `_dio.get('/calls/turn-credentials')` |
| **Заголовки** | `Authorization: Bearer <jwt>` | DioApiClient добавляет Bearer для путей `/calls/` |
| **Тело** | нет | нет |

**Ответ сервера (200):**
```json
{
  "urls": [
    "turn:host:3478?transport=udp",
    "turn:host:3478?transport=tcp",
    "turns:host:5349?transport=tcp"
  ],
  "username": "timestamp:user_id",
  "credential": "base64(hmac_sha1(turn_secret, username))",
  "ttl": 3600
}
```
Клиент: `TurnConfig.fromJson(data)` ожидает ключи `urls`, `username`, `credential`, `ttl` (snake_case совпадает с сервером).

---

## 4. Pin / Unpin сообщения в чате

### 4.1 Закрепить сообщение

| | Сервер (принимает) | Клиент |
|---|-------------------|--------|
| **Метод** | `POST /api/v1/chats/{id}/pin` | вызов из UI/логики чата (если реализован) |
| **Заголовки** | `Authorization: Bearer <jwt>` | через DioApiClient |
| **Тело** | `PinMessageRequest`: `message_id` — UUID | `data: { 'message_id': messageId }` |
| **Ответ** | 204 No Content | — |

### 4.2 Открепить сообщение

| | Сервер (принимает) | Клиент |
|---|-------------------|--------|
| **Метод** | `DELETE /api/v1/chats/{id}/pin` | вызов из UI (если реализован) |
| **Заголовки** | `Authorization: Bearer <jwt>` | через DioApiClient |
| **Тело** | нет | нет |
| **Ответ** | 204 No Content | — |

---

## Общее

- **Base URL** на клиенте: `ServerConfig.getApiBaseUrl()` (тот же для сообщений, файлов и звонков при использовании Dio).
- **Авторизация**: все запросы к `/api/v1/*` и `/calls/*` идут через `DioApiClient` с заголовком `Authorization: Bearer <token>` (токен из UserService).
- **Имена полей**: сервер везде использует **snake_case** (`message_id`, `chat_id`, `created_at`, `file_id`, `upload_url`, `download_url`, `to_chat_ids` и т.д.). Клиент при формировании запросов тоже отправляет snake_case и при разборе ответов читает snake_case.
