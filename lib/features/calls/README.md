# Calls Feature (P2P WebRTC with E2EE Signalling)

## Architecture

- **Signalling**: E2EE через Signal Protocol (WebSocket `/ws`)
- **Media**: P2P WebRTC (DTLS-SRTP), опционально через TURN
- **UI**: CallKit (iOS/Android) для нативного входящего звонка

## Signal Crypto Implementation

### Production: `DoubleRatchetSignalCrypto`

Полноценный Signal Protocol с Forward Secrecy:
- **X25519 ECDH** для key exchange
- **ChaCha20-Poly1305** для authenticated encryption
- **Double Ratchet** для forward secrecy (ключи ротируются каждые 2000 сообщений)
- **X3DH** для initial key exchange (использует PreKey Bundle)

### Usage

```dart
// Initialize with SharedPreferences
final prefs = await SharedPreferences.getInstance();
final crypto = DoubleRatchetSignalCrypto(prefs);

// Before first call, initialize session with PreKey Bundle
final preKeyBundle = await api.getPreKeyBundle(peerPublicId);
await crypto.initializeSession(peerId, preKeyBundle);

// Set peer context
crypto.setPeerId(peerId);

// Encrypt/decrypt (uses Double Ratchet automatically)
final encrypted = crypto.encryptToBase64(jsonString);
final decrypted = crypto.decryptFromBase64(encrypted);
```

### Integration in WebRTCService

```dart
// In startCall():
if (_crypto is DoubleRatchetSignalCrypto) {
  // Request PreKey Bundle if session doesn't exist
  final preKeyBundle = await _usersApi.getPreKeys(toUserId);
  await (_crypto as DoubleRatchetSignalCrypto).initializeSession(toUserId, preKeyBundle);
}
(_crypto as DoubleRatchetSignalCrypto?)?.setPeerId(toUserId);
```

### Fallback: `RealSignalCrypto`

Упрощённая версия (без forward secrecy):
- Используется если Double Ratchet недоступен
- Статические ключи per peer
- Подходит для тестирования

## Call Flow

1. **Caller**: `WebRTCService.startCall()` → создаёт Offer → шифрует → отправляет `call_offer` через WS
2. **Server**: получает `call_offer` → создаёт запись в `call_sessions` (status: `ringing`) → пересылает получателю
3. **Callee**: получает `call_offer` → CallKit показывает входящий звонок
4. **Callee accepts**: `WebRTCService.acceptIncomingCall()` → создаёт Answer → шифрует → отправляет `call_answer`
5. **Server**: обновляет `call_sessions` (status: `accepted`, `accepted_at`)
6. **Both**: обмениваются ICE candidates (зашифрованными)
7. **Hangup**: отправляется `call_hangup` → сервер обновляет статус (`ended`/`rejected`/`missed`)

## Database

Таблица `call_sessions`:
- `id` (UUID) - call_id
- `caller_id`, `callee_id` - участники
- `call_type` - audio/video
- `status` - ringing/accepted/ended/missed/rejected/failed
- `started_at`, `accepted_at`, `ended_at`, `end_reason`

## Security Notes

- Сервер **не видит** содержимое SDP/ICE (только `encrypted_payload`)
- Ключи шифрования **никогда не покидают устройство**
- TURN credentials временные (1 час TTL)
- Опция "Always Relay" скрывает IP от собеседника (но увеличивает задержку)

