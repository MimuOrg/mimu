import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mimu/features/chat_screen.dart';
import 'package:mimu/features/shell_ui.dart';
import 'package:mimu/features/profile_screen.dart';
import 'package:mimu/features/create_entities.dart';
import 'package:mimu/features/auth_screen.dart';
import 'package:mimu/features/auth_method_screen.dart';
import 'package:mimu/features/premium_screen.dart';
import 'package:mimu/features/join_by_link_screen.dart';
import 'package:mimu/features/devices_screen.dart';
import 'package:mimu/features/blocked_users_screen.dart';

class AppRoutes {
  // Auth routes
  static const String auth = '/auth';
  static const String authLegacy = '/auth/legacy';
  static const String authCrypto = '/auth/crypto';

  // Main routes
  static const String home = '/home';
  static const String shell = '/';
  static const String chat = '/chat';
  static const String profile = '/profile';

  // Creation routes
  static const String createGroup = '/create_group';
  static const String createChannel = '/create_channel';

  // Other routes
  static const String codeVerification = '/code_verification';
  static const String premium = '/premium';
  /// Вход по invite-ссылке: t.mimu.app/join/{token}
  static const String joinByLink = '/join';
  /// Активные сессии (устройства)
  static const String devices = '/devices';
  /// Заблокированные пользователи
  static const String blockedUsers = '/blocked';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // New crypto auth method selection (default auth entry)
      case auth:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthMethodScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

      // Legacy password-based auth
      case authLegacy:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

      // Crypto auth flow (same as auth for now, but explicit)
      case authCrypto:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthMethodScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

      // Home/Shell - main app after login
      case home:
      case shell:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ShellUI(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

      // Chat screen with arguments
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return CupertinoPageRoute(
          builder: (context) => ChatScreen(chatId: args['chatId'] as String),
        );

      // Profile screen with arguments
      case profile:
        final args = settings.arguments as Map<String, dynamic>;
        return CupertinoPageRoute(
          builder: (context) => ProfileScreen(
            userName: args['userName'] as String,
            avatarAsset: args['avatarAsset'] as String,
          ),
        );

      // Create group dialog
      case createGroup:
        return CupertinoPageRoute(
          builder: (context) => const CreateGroupScreen(),
          fullscreenDialog: true,
        );

      // Create channel dialog
      case createChannel:
        return CupertinoPageRoute(
          builder: (context) => const CreateChannelScreen(),
          fullscreenDialog: true,
        );

      // Premium subscription screen
      case premium:
        return CupertinoPageRoute(
          builder: (context) => const PremiumScreen(),
          fullscreenDialog: true,
        );

      // Join by invite link: /join or /join?token=xxx (deep link t.mimu.app/join/xxx)
      case joinByLink:
        final args = settings.arguments as Map<String, dynamic>?;
        final pathSegments = Uri.parse(settings.name ?? '').pathSegments;
        final token = args?['token'] as String? ??
            (pathSegments.length >= 2 ? pathSegments[1] : pathSegments.lastOrNull ?? '');
        return CupertinoPageRoute(
          builder: (context) => JoinByLinkScreen(inviteToken: token),
          fullscreenDialog: true,
        );

      case devices:
        return CupertinoPageRoute(
          builder: (context) => const DevicesScreen(),
        );

      case blockedUsers:
        return CupertinoPageRoute(
          builder: (context) => const BlockedUsersScreen(),
        );

      // Default fallback to auth
      default:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthMethodScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
    }
  }

  /// Navigate to home and clear navigation stack
  static void navigateToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
  }

  /// Navigate to auth and clear navigation stack
  static void navigateToAuth(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(auth, (route) => false);
  }

  /// Navigate to legacy auth
  static void navigateToLegacyAuth(BuildContext context) {
    Navigator.of(context).pushNamed(authLegacy);
  }
}
