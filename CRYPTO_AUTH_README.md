# Crypto Authentication System

## Overview

Mimu implements a passwordless authentication system based on:
- **BIP-39**: 12-word mnemonic recovery phrases (English & Russian)
- **Ed25519**: Elliptic curve cryptography for digital signatures
- **Challenge-Response**: Server verification without storing secrets

The server **never** knows the user's recovery phrase or private key. Authentication is proven through cryptographic signatures.

---

## Architecture

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         REGISTRATION                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. User selects language (EN/RU)                                   │
│  2. App generates 12-word BIP-39 mnemonic                           │
│  3. Mnemonic → PBKDF2 → Ed25519 Key Pair                           │
│  4. POST /auth/register-crypto { public_key, fingerprint }          │
│  5. Server stores public_key, returns JWT                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      LOGIN / RECOVERY                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. User enters 12-word mnemonic                                    │
│  2. App validates checksum & detects language                       │
│  3. Mnemonic → PBKDF2 → Ed25519 Key Pair                           │
│  4. POST /auth/challenge { public_key } → nonce                     │
│  5. App signs nonce with private key                                │
│  6. POST /auth/verify { public_key, signature } → JWT               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### `POST /auth/register-crypto`

Register a new user with Ed25519 public key.

**Request:**
```json
{
  "public_key": "base64-encoded-32-bytes",
  "fingerprint": "sha256-hex-64-chars",
  "display_name": "John Doe",
  "language": "en"
}
```

**Response (201):**
```json
{
  "user_id": "uuid",
  "access_token": "jwt-token",
  "refresh_token": "hex-token",
  "fingerprint": "sha256-hex"
}
```

---

### `POST /auth/challenge`

Request a nonce for authentication.

**Request:**
```json
{
  "public_key": "base64-encoded-32-bytes"
}
```

**Response (200):**
```json
{
  "nonce": "hex-string-64-chars",
  "expires_in": 300
}
```

**Errors:**
- `404` - User not found

---

### `POST /auth/verify`

Verify signature and get JWT tokens.

**Request:**
```json
{
  "public_key": "base64-encoded-32-bytes",
  "signature": "base64-encoded-64-bytes"
}
```

**Response (200):**
```json
{
  "user_id": "uuid",
  "access_token": "jwt-token",
  "refresh_token": "hex-token",
  "fingerprint": "sha256-hex"
}
```

**Errors:**
- `401` - Invalid signature or challenge expired

---

## Flutter Implementation

### Files

| File | Description |
|------|-------------|
| `lib/data/services/crypto_auth_service.dart` | Core cryptography service |
| `lib/data/services/bip39_wordlists.dart` | BIP-39 wordlist management |
| `lib/data/services/auth_service.dart` | High-level auth orchestration |
| `lib/features/auth_method_screen.dart` | Auth method selection UI |
| `lib/features/recovery_phrase_screen.dart` | Mnemonic display/input UI |
| `assets/wordlists/english.txt` | English BIP-39 wordlist (2048 words) |
| `assets/wordlists/russian.txt` | Russian BIP-39 wordlist (2048 words) |

### Usage Example

```dart
import 'package:mimu/data/services/auth_service.dart';
import 'package:mimu/data/services/bip39_wordlists.dart';

final authService = AuthService();

// Initialize (loads wordlists)
await authService.init();

// === REGISTRATION ===

// 1. Generate mnemonic
final mnemonic = authService.generateMnemonic(
  language: MnemonicLanguage.english,
);
print('Save this phrase: $mnemonic');

// 2. Register with server
final result = await authService.registerWithCrypto(
  displayName: 'John Doe',
  language: 'en',
);

if (result.success) {
  print('Registered! User ID: ${result.userId}');
}

// === LOGIN / RECOVERY ===

// 1. Validate mnemonic
final validation = authService.validateMnemonic(userInput);
if (!validation.isValid) {
  print('Error: ${validation.error}');
  return;
}

// 2. Authenticate
final result = await authService.loginWithRecoveryPhrase(
  userInput,
  language: validation.detectedLanguage,
);

if (result.success) {
  print('Logged in! User ID: ${result.userId}');
}
```

### Key Generation

```dart
// BIP-39 Mnemonic → Seed (PBKDF2-HMAC-SHA512)
// Seed (first 32 bytes) → Ed25519 Private Key
// Ed25519 Private Key → Public Key (32 bytes)

Mnemonic: "abandon ability able about above absent absorb abstract absurd abuse access accident"
    ↓ PBKDF2(mnemonic, "mnemonic", 2048 iterations)
Seed: 64 bytes
    ↓ Take first 32 bytes
Ed25519 Seed: 32 bytes
    ↓ ed25519.newKeyFromSeed()
Key Pair: { privateKey, publicKey }
```

---

## Rust Implementation

### Files

| File | Description |
|------|-------------|
| `server/src/web/auth/crypto_handlers.rs` | Challenge/Verify/Register handlers |
| `server/src/web/auth/mod.rs` | Module exports |
| `server/src/web/router.rs` | Route definitions |
| `server/migrations/0002_add_signing_public_key.sql` | DB migration |
| `server/migrations/0005_crypto_auth_updates.sql` | Auth method column |

### Dependencies (Cargo.toml)

```toml
ed25519-dalek = { version = "2.1", features = ["rand_core"] }
redis = { version = "0.28", features = ["tokio-comp", "connection-manager"] }
base64 = "0.22"
sha2 = "0.10"
hex = "0.4"
```

### Signature Verification

```rust
use ed25519_dalek::{Signature, Verifier, VerifyingKey};

// Decode public key (32 bytes)
let verifying_key = VerifyingKey::from_bytes(&public_key_bytes)?;

// Decode signature (64 bytes)
let signature = Signature::from_bytes(&signature_bytes)?;

// Verify: signature was created by signing `nonce` with matching private key
verifying_key.verify(nonce.as_bytes(), &signature)?;
```

---

## Database Schema

```sql
-- Users table additions
ALTER TABLE users
  ADD COLUMN signing_public_key BYTEA;        -- Ed25519 public key (32 bytes)
  ADD COLUMN auth_method TEXT DEFAULT 'password';  -- 'password' or 'crypto'

-- Constraints
CREATE UNIQUE INDEX idx_users_signing_public_key ON users(signing_public_key);

-- For crypto auth, signing_public_key must not be null
-- For password auth, password_hash must not be empty
```

---

## Security Considerations

### Client-Side
- **Never store mnemonic** in persistent storage
- Display mnemonic only during registration
- Clear keys from memory on logout
- Use secure random for entropy generation

### Server-Side
- Nonce stored in Redis with 5-minute TTL
- Nonce is single-use (deleted after verification)
- Public keys are stored, never private keys
- Rate limiting on challenge endpoint

### Cryptographic Parameters
- **BIP-39**: 128 bits entropy → 12 words + 4-bit checksum
- **PBKDF2**: 2048 iterations, SHA-512, 64-byte output
- **Ed25519**: 256-bit security, 32-byte keys, 64-byte signatures

---

## BIP-39 Wordlists

### English
- 2048 words from official BIP-39 specification
- Source: `https://github.com/bitcoin/bips/blob/master/bip-0039/english.txt`

### Russian
- 2048 words from Trezor implementation
- Source: `https://github.com/trezor/python-mnemonic/blob/master/src/mnemonic/wordlist/russian.txt`

### Language Detection
The system automatically detects the language of an entered phrase by checking each word against both wordlists.

---

## Testing

### Generate Test Mnemonic
```dart
final mnemonic = CryptoAuthService().generateMnemonic();
// Example: "abandon ability able about above absent absorb abstract absurd abuse access accident"
```

### Verify Checksum
```dart
final result = CryptoAuthService().validateMnemonic(mnemonic);
assert(result.isValid == true);
assert(result.detectedLanguage == MnemonicLanguage.english);
```

### Test Challenge-Response
```bash
# 1. Request challenge
curl -X POST http://localhost:8080/auth/challenge \
  -H "Content-Type: application/json" \
  -d '{"public_key": "BASE64_PUBLIC_KEY"}'

# 2. Sign nonce (client-side)
# 3. Verify signature
curl -X POST http://localhost:8080/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"public_key": "BASE64_PUBLIC_KEY", "signature": "BASE64_SIGNATURE"}'
```

---

## Migration Guide

### Existing Users (Password Auth)
- Existing users continue using password authentication
- `auth_method = 'password'` in database
- No changes required to existing flows

### New Users (Crypto Auth)
- New users can choose crypto authentication
- `auth_method = 'crypto'` in database
- Recovery phrase is their only login method

### Hybrid Support
Both authentication methods are supported simultaneously. The `auth_method` column determines which method is used for each user.