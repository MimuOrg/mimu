import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mimu/data/server_config.dart';
import 'package:mimu/data/user_service.dart';
import 'package:mimu/data/services/crypto_auth_service.dart';
import 'package:mimu/data/services/bip39_wordlists.dart';

/// Authentication method types
enum AuthMethod {
  /// Traditional password-based authentication
  password,
  /// Cryptographic authentication using Ed25519 and BIP-39 recovery phrase
  crypto,
}

/// Authentication state
enum AuthState {
  /// Initial state, not determined yet
  unknown,
  /// User is authenticated
  authenticated,
  /// User is not authenticated
  unauthenticated,
  /// Authentication is in progress
  authenticating,
  /// Token refresh is in progress
  refreshing,
  /// Authentication failed
  failed,
}

/// Result of authentication operations
class AuthResult {
  final bool success;
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final String? fingerprint;
  final String? error;
  final int? statusCode;

  const AuthResult({
    required this.success,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.fingerprint,
    this.error,
    this.statusCode,
  });

  factory AuthResult.success({
    required String userId,
    required String accessToken,
    required String refreshToken,
    String? fingerprint,
  }) {
    return AuthResult(
      success: true,
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      fingerprint: fingerprint,
    );
  }

  factory AuthResult.failure(String error, {int? statusCode}) {
    return AuthResult(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// Comprehensive authentication service supporting both crypto and password auth
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final CryptoAuthService _cryptoService = CryptoAuthService();

  // State management
  final _stateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get stateStream => _stateController.stream;

  AuthState _currentState = AuthState.unknown;
  AuthState get currentState => _currentState;

  bool _isInitialized = false;

  // ==================== Initialization ====================

  /// Initialize the auth service
  Future<void> init() async {
    if (_isInitialized) return;

    await UserService.init();
    await _cryptoService.init();

    // Check current auth state
    if (UserService.isLoggedIn()) {
      if (UserService.isTokenExpired()) {
        // Try to refresh token
        final refreshed = await refreshToken();
        _updateState(refreshed ? AuthState.authenticated : AuthState.unauthenticated);
      } else {
        _updateState(AuthState.authenticated);
      }
    } else {
      _updateState(AuthState.unauthenticated);
    }

    _isInitialized = true;
  }

  void _updateState(AuthState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _currentState == AuthState.authenticated;

  /// Get current auth method
  AuthMethod get authMethod {
    return UserService.isCryptoAuth() ? AuthMethod.crypto : AuthMethod.password;
  }

  // ==================== Crypto Authentication ====================

  /// Generate a new mnemonic phrase for registration
  String generateMnemonic({MnemonicLanguage language = MnemonicLanguage.english}) {
    return _cryptoService.generateMnemonic(language: language);
  }

  /// Get the current mnemonic (for display during registration)
  String? get currentMnemonic => _cryptoService.currentMnemonic;

  /// Get current mnemonic language
  MnemonicLanguage? get currentMnemonicLanguage => _cryptoService.currentLanguage;

  /// Validate a mnemonic phrase
  MnemonicValidationResult validateMnemonic(String mnemonic) {
    return _cryptoService.validateMnemonic(mnemonic);
  }

  /// Register a new account using crypto authentication
  Future<AuthResult> registerWithCrypto({
    required String displayName,
    String? language,
  }) async {
    _updateState(AuthState.authenticating);

    try {
      // Generate keys from current mnemonic
      final keyPair = _cryptoService.generateKeys();

      // Register with server
      final response = await _cryptoService.register(
        displayName: displayName,
        language: language,
      );

      // Save auth data
      await UserService.saveCryptoAuthResponse(
        userId: response.userId,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        fingerprint: response.fingerprint,
        publicKey: keyPair.publicKeyBase64,
        displayName: displayName,
      );

      _updateState(AuthState.authenticated);

      return AuthResult.success(
        userId: response.userId,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        fingerprint: response.fingerprint,
      );
    } on CryptoAuthException catch (e) {
      _updateState(AuthState.failed);
      return AuthResult.failure(e.message, statusCode: e.statusCode);
    } catch (e) {
      _updateState(AuthState.failed);
      return AuthResult.failure(e.toString());
    }
  }

  /// Login/Restore account using recovery phrase
  Future<AuthResult> loginWithRecoveryPhrase(
    String mnemonic, {
    MnemonicLanguage? language,
  }) async {
    _updateState(AuthState.authenticating);

    try {
      // Validate and restore keys from mnemonic
      final keyPair = _cryptoService.restoreKeysFromMnemonic(mnemonic, language: language);

      // Perform challenge-response authentication
      final response = await _cryptoService.authenticate();

      // Save auth data
      await UserService.saveCryptoAuthResponse(
        userId: response.userId,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        fingerprint: response.fingerprint,
        publicKey: keyPair.publicKeyBase64,
      );

      _updateState(AuthState.authenticated);

      return AuthResult.success(
        userId: response.userId,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        fingerprint: response.fingerprint,
      );
    } on CryptoAuthException catch (e) {
      _updateState(AuthState.failed);
      return AuthResult.failure(e.message, statusCode: e.statusCode);
    } on ArgumentError catch (e) {
      _updateState(AuthState.failed);
      return AuthResult.failure(e.message.toString());
    } catch (e) {
      _updateState(AuthState.failed);
      return AuthResult.failure(e.toString());
    }
  }

  // ==================== Legacy Password Authentication ====================

  /// Register with username and password (legacy)
  Future<AuthResult> registerWithPassword({
    required String publicId,
    required String password,
    required String identityKey,
    required String signingPublicKey,
    required int registrationId,
    String? displayName,
    String? language,
  }) async {
    _updateState(AuthState.authenticating);

    try {
      final url = Uri.parse('${ServerConfig.baseUrl}/auth/register');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'public_id': publicId,
          'password': password,
          'identity_key': identityKey,
          'signing_public_key': signingPublicKey,
          'registration_id': registrationId,
          'fingerprint': '', // Will be computed server-side
          'signed_prekey': {
            'key_id': 1,
            'public_key': '', // TODO: Generate proper prekey
            'signature': '',
          },
          'one_time_prekeys': [],
          'display_name': displayName,
          'language': language ?? 'en',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        await UserService.setUserId(data['user_id']);
        await UserService.setAccessToken(data['access_token']);
        await UserService.setRefreshToken(data['refresh_token']);
        await UserService.setFingerprint(data['fingerprint']);
        await UserService.setAuthMethod('password');
        await UserService.setPrId(publicId);

        if (displayName != null) {
          await UserService.setDisplayName(displayName);
        }

        _updateState(AuthState.authenticated);

        return AuthResult.success(
          userId: data['user_id'],
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          fingerprint: data['fingerprint'],
        );
      } else {
        final errorMsg = _parseErrorMessage(response);
        _updateState(AuthState.failed);
        return AuthResult.failure(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      _updateState(AuthState.failed);
      return AuthResult.failure(e.toString());
    }
  }

  /// Login with username and password (legacy)
  Future<AuthResult> loginWithPassword({
    required String publicId,
    required String password,
  }) async {
    _updateState(AuthState.authenticating);

    try {
      final url = Uri.parse('${ServerConfig.baseUrl}/auth/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'public_id': publicId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        await UserService.setUserId(data['user_id']);
        await UserService.setAccessToken(data['access_token']);
        await UserService.setRefreshToken(data['refresh_token']);
        await UserService.setFingerprint(data['fingerprint']);
        await UserService.setAuthMethod('password');
        await UserService.setPrId(publicId);

        _updateState(AuthState.authenticated);

        return AuthResult.success(
          userId: data['user_id'],
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          fingerprint: data['fingerprint'],
        );
      } else {
        final errorMsg = _parseErrorMessage(response);
        _updateState(AuthState.failed);
        return AuthResult.failure(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      _updateState(AuthState.failed);
      return AuthResult.failure(e.toString());
    }
  }

  // ==================== Token Management ====================

  /// Refresh the access token
  Future<bool> refreshToken() async {
    final refreshToken = UserService.getRefreshToken();
    if (refreshToken == null) {
      _updateState(AuthState.unauthenticated);
      return false;
    }

    _updateState(AuthState.refreshing);

    try {
      final url = Uri.parse('${ServerConfig.baseUrl}/auth/refresh');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        await UserService.setAccessToken(data['access_token']);
        await UserService.setRefreshToken(data['refresh_token']);

        _updateState(AuthState.authenticated);
        return true;
      } else {
        // Refresh failed - user needs to re-authenticate
        _updateState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      _updateState(AuthState.unauthenticated);
      return false;
    }
  }

  /// Re-authenticate using stored credentials (for crypto auth)
  Future<AuthResult> reAuthenticate() async {
    if (!UserService.isCryptoAuth()) {
      return AuthResult.failure('Re-authentication requires crypto auth method');
    }

    // For crypto auth, we need the mnemonic phrase
    // This should be called when the user provides their recovery phrase again
    return AuthResult.failure('Please enter your recovery phrase to re-authenticate');
  }

  // ==================== Logout ====================

  /// Logout and clear all auth data
  Future<void> logout() async {
    // Clear crypto service keys
    _cryptoService.clearKeys();

    // Clear stored auth data
    await UserService.logout();

    _updateState(AuthState.unauthenticated);
  }

  /// Full reset - clear everything
  Future<void> fullReset() async {
    _cryptoService.clearKeys();
    await UserService.clearAll();
    _updateState(AuthState.unauthenticated);
  }

  // ==================== Helper Methods ====================

  String _parseErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'Unknown error';
      }
    } catch (_) {}
    return response.body.isNotEmpty ? response.body : 'Unknown error';
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}
