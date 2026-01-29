import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user data and authentication state.
/// JWT access/refresh tokens are stored in FlutterSecureStorage (Keystore/Keychain).
class UserService {
  // Legacy keys
  static const String _keyUsername = 'user_username';
  static const String _keyDisplayName = 'user_display_name';
  static const String _keyAvatarPath = 'user_avatar_path';
  static const String _keyPrId = 'user_prid';

  // Auth keys (sensitive — in secure storage)
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  // Non-sensitive auth metadata in SharedPreferences
  static const String _keyUserId = 'auth_user_id';
  static const String _keyFingerprint = 'auth_fingerprint';
  static const String _keyPublicKey = 'auth_public_key';
  static const String _keyAuthMethod = 'auth_method'; // 'password' or 'crypto'
  static const String _keyLanguage = 'user_language';
  static const String _keyTokenExpiry = 'auth_token_expiry';

  static SharedPreferences? _prefs;
  static FlutterSecureStorage? _secureStorage;
  static bool _isInitialized = false;
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;

  /// Initialize the service
  static Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    // Load tokens from secure storage into cache (sync getters use cache)
    _cachedAccessToken = await _secureStorage?.read(key: _keyAccessToken);
    _cachedRefreshToken = await _secureStorage?.read(key: _keyRefreshToken);
    // One-time migration from SharedPreferences
    if (_cachedAccessToken == null) {
      final legacy = _prefs?.getString(_keyAccessToken);
      if (legacy != null) {
        await _secureStorage?.write(key: _keyAccessToken, value: legacy);
        _cachedAccessToken = legacy;
        await _prefs?.remove(_keyAccessToken);
      }
    }
    if (_cachedRefreshToken == null) {
      final legacy = _prefs?.getString(_keyRefreshToken);
      if (legacy != null) {
        await _secureStorage?.write(key: _keyRefreshToken, value: legacy);
        _cachedRefreshToken = legacy;
        await _prefs?.remove(_keyRefreshToken);
      }
    }
    _isInitialized = true;
  }

  /// Ensure service is initialized
  static void _ensureInitialized() {
    if (!_isInitialized || _prefs == null) {
      throw StateError('UserService not initialized. Call init() first.');
    }
  }

  // ==================== Legacy Getters/Setters ====================

  static String getUsername() {
    _ensureInitialized();
    return _prefs?.getString(_keyUsername) ?? 'usermimu';
  }

  static Future<void> setUsername(String username) async {
    _ensureInitialized();
    await _prefs?.setString(_keyUsername, username);
  }

  static String getDisplayName() {
    _ensureInitialized();
    return _prefs?.getString(_keyDisplayName) ?? 'Username';
  }

  static Future<void> setDisplayName(String name) async {
    _ensureInitialized();
    await _prefs?.setString(_keyDisplayName, name);
  }

  static String? getAvatarPath() {
    _ensureInitialized();
    return _prefs?.getString(_keyAvatarPath);
  }

  static Future<void> setAvatarPath(String? path) async {
    _ensureInitialized();
    if (path == null) {
      await _prefs?.remove(_keyAvatarPath);
    } else {
      await _prefs?.setString(_keyAvatarPath, path);
    }
  }

  static String? getPrId() {
    _ensureInitialized();
    return _prefs?.getString(_keyPrId);
  }

  static Future<void> setPrId(String prid) async {
    _ensureInitialized();
    await _prefs?.setString(_keyPrId, prid);
  }

  // ==================== Auth Getters/Setters ====================

  /// Get current access token (from in-memory cache, backed by secure storage)
  static String? getAccessToken() {
    _ensureInitialized();
    return _cachedAccessToken;
  }

  /// Set access token (writes to secure storage and cache)
  static Future<void> setAccessToken(String? token) async {
    _ensureInitialized();
    _cachedAccessToken = token;
    if (token == null) {
      await _secureStorage?.delete(key: _keyAccessToken);
    } else {
      await _secureStorage?.write(key: _keyAccessToken, value: token);
    }
  }

  /// Get refresh token (from in-memory cache, backed by secure storage)
  static String? getRefreshToken() {
    _ensureInitialized();
    return _cachedRefreshToken;
  }

  /// Set refresh token (writes to secure storage and cache)
  static Future<void> setRefreshToken(String? token) async {
    _ensureInitialized();
    _cachedRefreshToken = token;
    if (token == null) {
      await _secureStorage?.delete(key: _keyRefreshToken);
    } else {
      await _secureStorage?.write(key: _keyRefreshToken, value: token);
    }
  }

  /// Get user ID
  static String? getUserId() {
    _ensureInitialized();
    return _prefs?.getString(_keyUserId);
  }

  /// Set user ID
  static Future<void> setUserId(String? userId) async {
    _ensureInitialized();
    if (userId == null) {
      await _prefs?.remove(_keyUserId);
    } else {
      await _prefs?.setString(_keyUserId, userId);
    }
  }

  /// Get user fingerprint (SHA256 of public key)
  static String? getFingerprint() {
    _ensureInitialized();
    return _prefs?.getString(_keyFingerprint);
  }

  /// Set user fingerprint
  static Future<void> setFingerprint(String? fingerprint) async {
    _ensureInitialized();
    if (fingerprint == null) {
      await _prefs?.remove(_keyFingerprint);
    } else {
      await _prefs?.setString(_keyFingerprint, fingerprint);
    }
  }

  /// Get public key (base64 encoded)
  static String? getPublicKey() {
    _ensureInitialized();
    return _prefs?.getString(_keyPublicKey);
  }

  /// Set public key
  static Future<void> setPublicKey(String? publicKey) async {
    _ensureInitialized();
    if (publicKey == null) {
      await _prefs?.remove(_keyPublicKey);
    } else {
      await _prefs?.setString(_keyPublicKey, publicKey);
    }
  }

  /// Get auth method ('password' or 'crypto')
  static String getAuthMethod() {
    _ensureInitialized();
    return _prefs?.getString(_keyAuthMethod) ?? 'password';
  }

  /// Set auth method
  static Future<void> setAuthMethod(String method) async {
    _ensureInitialized();
    await _prefs?.setString(_keyAuthMethod, method);
  }

  /// Check if user is using crypto auth
  static bool isCryptoAuth() {
    return getAuthMethod() == 'crypto';
  }

  /// Get user language preference
  static String getLanguage() {
    _ensureInitialized();
    return _prefs?.getString(_keyLanguage) ?? 'en';
  }

  /// Set user language preference
  static Future<void> setLanguage(String language) async {
    _ensureInitialized();
    await _prefs?.setString(_keyLanguage, language);
  }

  /// Get token expiry timestamp
  static int? getTokenExpiry() {
    _ensureInitialized();
    return _prefs?.getInt(_keyTokenExpiry);
  }

  /// Set token expiry timestamp
  static Future<void> setTokenExpiry(int? expiry) async {
    _ensureInitialized();
    if (expiry == null) {
      await _prefs?.remove(_keyTokenExpiry);
    } else {
      await _prefs?.setInt(_keyTokenExpiry, expiry);
    }
  }

  // ==================== Auth State Management ====================

  /// Check if user is logged in
  static bool isLoggedIn() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if access token is expired (with 5 min buffer)
  static bool isTokenExpired() {
    final expiry = getTokenExpiry();
    if (expiry == null) return true;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    final buffer = DateTime.now().add(const Duration(minutes: 5));
    return expiryDate.isBefore(buffer);
  }

  /// Save auth response from crypto auth
  static Future<void> saveCryptoAuthResponse({
    required String userId,
    required String accessToken,
    required String refreshToken,
    required String fingerprint,
    required String publicKey,
    String? displayName,
  }) async {
    await setUserId(userId);
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
    await setFingerprint(fingerprint);
    await setPublicKey(publicKey);
    await setAuthMethod('crypto');

    if (displayName != null) {
      await setDisplayName(displayName);
    }

    // Parse JWT to get expiry (simple extraction)
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        // JWT payload is base64 encoded
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final exp = json['exp'] as int?;
        if (exp != null) {
          await setTokenExpiry(exp);
        }
      }
    } catch (e) {
      // Ignore JWT parsing errors
    }
  }

  /// Clear all auth data (logout)
  static Future<void> logout() async {
    _ensureInitialized();
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _secureStorage?.delete(key: _keyAccessToken);
    await _secureStorage?.delete(key: _keyRefreshToken);
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyFingerprint);
    await _prefs?.remove(_keyPublicKey);
    await _prefs?.remove(_keyTokenExpiry);
    await _prefs?.remove(_keyAuthMethod);
  }

  /// Clear all user data (full reset)
  static Future<void> clearAll() async {
    _ensureInitialized();
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _secureStorage?.deleteAll();
    await _prefs?.clear();
  }

  // ==================== Utility Methods ====================

  /// Generate a random PrId (legacy)
  static String generateRandomPrId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }
    return buffer.toString();
  }

  /// Get authorization header value
  static String? getAuthorizationHeader() {
    final token = getAccessToken();
    if (token == null || token.isEmpty) return null;
    return 'Bearer $token';
  }

  /// Get all auth-related headers
  static Map<String, String> getAuthHeaders() {
    final headers = <String, String>{};

    final authHeader = getAuthorizationHeader();
    if (authHeader != null) {
      headers['Authorization'] = authHeader;
    }

    final fingerprint = getFingerprint();
    if (fingerprint != null) {
      headers['X-Fingerprint'] = fingerprint;
    }

    final prId = getPrId();
    if (prId != null) {
      headers['X-PrID'] = prId;
    }

    return headers;
  }
}
