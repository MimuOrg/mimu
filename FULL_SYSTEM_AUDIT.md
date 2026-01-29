# Mimu System Audit & Implementation Guide

This document provides a comprehensive audit of the implemented functions in the Mimu server (`mimu-server`) and the expected behavior for the client application (Flutter). It covers authentication, messaging, encryption, media handling, and real-time communication.

---

## 1. Authentication & Identity (`/auth`)

### 1.1 Registration (`POST /auth/register`)
*   **Purpose:** Creates a new user account with cryptographic identity.
*   **Server Implementation:**
    *   Validates `public_id` (username) uniqueness.
    *   Validates `identity_key` (X25519, 32 bytes) and `signing_public_key` (Ed25519, 32 bytes).
    *   Computes `fingerprint` as `sha256(identity_key)` to ensure integrity.
    *   Stores the **password hash** (Argon2/bcrypt) for secondary authentication.
    *   Stores `signed_prekey` and a batch of `one_time_prekeys` for the Signal Protocol (X3DH).
    *   Issues an initial JWT `access_token` and `refresh_token`.
*   **Client Responsibility:**
    *   Generate Identity Keypair (X25519) and Signing Keypair (Ed25519).
    *   Generate Prekeys and Signed Prekey (signed by Signing Key).
    *   Upload public parts of these keys.
    *   Store private keys securely (KeyStore/Keychain).

### 1.2 Login (`POST /auth/login`)
*   **Purpose:** Authenticates a user using password.
*   **Server Implementation:**
    *   Verifies password hash against the database.
    *   Issues new JWT `access_token` and `refresh_token`.
    *   Returns the user's `fingerprint` and `user_id`.
*   **Client Responsibility:**
    *   Send credentials.
    *   Store tokens securely.
    *   **Note:** Login alone does *not* recover private keys. Keys must be restored via backup (not yet implemented) or stored locally.

### 1.3 Token Refresh (`POST /auth/refresh`)
*   **Purpose:** Rotates access tokens without re-entering credentials.
*   **Server Implementation:**
    *   Validates the opaque `refresh_token` against Redis.
    *   Rotates the refresh token (Single Use Token pattern) to prevent replay attacks.
    *   Issues a new pair of tokens.

### 1.4 Password Reset (`POST /auth/reset-password`)
*   **Purpose:** Resets password using cryptographic proof of identity.
*   **Server Implementation:**
    *   **Security:** Requires `signature` of `new_password + timestamp` signed by the user's `signing_private_key`.
    *   Verifies the timestamp is within a 5-minute window (anti-replay).
    *   Verifies the Ed25519 signature against the stored `signing_public_key`.
    *   Updates the password hash if valid.
*   **Client Responsibility:**
    *   Must possess the private key on the device to reset the password.
    *   Sign the payload and send it.

---

## 2. User Management (`/users`)

### 2.1 Search (`GET /users/search`)
*   **Purpose:** Find other users by `public_id` (username).
*   **Server Implementation:**
    *   Performs a prefix search in the database.
    *   Returns public profiles (ID, Display Name, Avatar).

### 2.2 Profile Fetch (`GET /users/{public_id}`)
*   **Purpose:** Get details of a specific user.
*   **Server Implementation:**
    *   Returns public info.
*   **Client Responsibility:**
    *   Used to verify contact identity before starting a chat.

### 2.3 Prekey Fetch (`GET /users/{public_id}/prekeys`)
*   **Purpose:** Retrieve keys needed to start an encrypted session (X3DH).
*   **Server Implementation:**
    *   Returns the user's `identity_key`, `signed_prekey`, and consumes one `one_time_prekey` (if available) from the database.
*   **Client Responsibility:**
    *   Fetch these keys *before* the first message.
    *   Build the Signal Protocol session.
    *   Encrypt the initial message using this session.

---

## 3. Chat Management (`/api/v1/chats`)

### 3.1 Create Chat (`POST /api/v1/chats`)
*   **Purpose:** Initialize a conversation thread.
*   **Server Implementation:**
    *   Creates a row in `chat_threads`.
    *   Adds entries to `chat_participants` for the creator and listed `participant_ids`.
    *   Returns the new `chat_id`.
*   **Client Responsibility:**
    *   Call this when the user taps "Start Chat".
    *   Ensure encryption sessions exist for all participants.

### 3.2 Add Participant (`POST .../participants`)
*   **Purpose:** Add a user to an existing group.
*   **Server Implementation:**
    *   Checks if the requester is already a participant (ACL).
    *   Adds the new user to `chat_participants`.
*   **Client Responsibility:**
    *   **Critical:** Must send the `SenderKey` (Group Encryption) to the new participant via a 1-to-1 encrypted message so they can read future messages.

### 3.3 Remove Participant (`DELETE .../participants/{id}`)
*   **Purpose:** Kick a user or leave a group.
*   **Server Implementation:**
    *   Removes the record from `chat_participants`.
*   **Client Responsibility:**
    *   **Critical:** Rotate the `SenderKey` and distribute it to remaining members so the removed user cannot read future messages.

---

## 4. Messaging & E2EE (`/api/v1/messages`)

### 4.1 Send Message (`POST /api/v1/messages`)
*   **Purpose:** Transport encrypted payload.
*   **Server Implementation:**
    *   **Agnostic:** Does not know the content.
    *   Stores `encrypted_payload` (Base64), `message_type` (metadata), and `reply_to` reference.
    *   Updates `chat_threads.updated_at`.
*   **Client Responsibility:**
    *   **Encryption:** Encrypt content using the Signal Session (1:1) or Sender Key (Group).
    *   **Padding:** Add padding to hide message length metadata.

### 4.2 Get Messages (`GET /api/v1/messages`)
*   **Purpose:** Sync chat history.
*   **Server Implementation:**
    *   Supports pagination via `limit` (clamped 1-100) and `before` (cursor).
    *   Filters out soft-deleted messages.
*   **Client Responsibility:**
    *   Download, Decrypt, Render.
    *   Handle "undecryptable" messages (e.g., request session reset).

### 4.3 Forward Message (`POST .../forward`)
*   **Purpose:** Send an existing message to other chats.
*   **Server Implementation:**
    *   Accepts a list of `targets` ({ chat_id, encrypted_payload }).
    *   Copies metadata (type, etc.) but uses the *new* payloads provided by the client.
    *   Links the new message to the original via `forwarded_from`.
*   **Client Responsibility:**
    *   Decrypt original message.
    *   **Re-encrypt** the content for each target chat (using that chat's unique session keys).
    *   Send the list of re-encrypted payloads.

### 4.4 Edit Message (`POST .../edit`)
*   **Purpose:** Modify sent message content.
*   **Server Implementation:**
    *   Verifies ownership and age (< 48 hours).
    *   Overwrites `encrypted_payload` and sets `edited_at`.
*   **Client Responsibility:**
    *   Send the full new encrypted payload.

---

## 5. Media Handling (`/api/v1/media`)

### 5.1 Upload Media (`POST /api/v1/media/upload`)
*   **Purpose:** Secure file storage (Images/Video/Audio).
*   **Server Implementation:**
    *   **Presigned URLs:** Does not accept file bytes directly.
    *   Generates a PUT URL for S3/MinIO compatible storage.
    *   Enforces size limits (100MB).
    *   Returns `upload_url` and `file_key`.
*   **Client Responsibility:**
    *   1. Generate a random symmetrical key (AES-256-GCM).
    *   2. Encrypt the file bytes.
    *   3. Request upload URL from server.
    *   4. PUT encrypted bytes to the `upload_url`.
    *   5. Send a chat message (Type: Image) containing the `file_key`, the `decryption_key`, and `iv` (Initialization Vector) inside the **encrypted** message payload.

---

## 6. Voice & Video Calls (`/calls`)

### 6.1 TURN Credentials (`GET /calls/turn-credentials`)
*   **Purpose:** Allow P2P connections to traverse NAT/Firewalls.
*   **Server Implementation:**
    *   Generates time-limited credentials for the TURN server (coturn).
*   **Client Responsibility:**
    *   Use these credentials to initialize WebRTC `RTCPeerConnection`.

### 6.2 Signaling (via WebSocket)
*   **Purpose:** Exchange SDP offers/answers and ICE candidates.
*   **Server Implementation:**
    *   Relays WebSocket messages between `user_id`s transparently.
*   **Client Responsibility:**
    *   Handle WebRTC state machine (Offer -> Answer -> Connected).

---

## 7. Real-time Communication (`/ws`)

### 7.1 WebSocket Connection
*   **Purpose:** Instant delivery of messages, signals, and notifications.
*   **Server Implementation:**
    *   Authenticates via JWT (in Query param).
    *   Maintains a mapping of `user_id` -> `socket`.
    *   Uses Redis Pub/Sub to scale across multiple server instances (if clustered).
*   **Client Responsibility:**
    *   Maintain a persistent connection.
    *   Handle reconnection with exponential backoff.
    *   Listen for `NewMessage`, `CallOffer`, `TypingIndicator` events.

---

## 8. Subscriptions (`/subscriptions`)

### 8.1 Purchase & Validation
*   **Purpose:** Monetization (Premium features).
*   **Server Implementation:**
    *   Validates receipts (Apple/Google).
    *   Updates user status in DB.
    *   `validate` endpoint checks current status.

---

## 9. Notifications (`/api/v1/notifications`)

### 9.1 Device Registration
*   **Purpose:** Push notifications (FCM/APNs) when the app is backgrounded.
*   **Server Implementation:**
    *   Stores FCM/APNs tokens mapping to users.
    *   Triggers push via worker when a message arrives and the user is disconnected from WebSocket.