import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mimu/features/chat_screen.dart';
import 'package:mimu/features/shell_ui.dart';
import 'package:mimu/features/profile_screen.dart';
import 'package:mimu/features/create_entities.dart';
import 'package:mimu/features/auth_screen.dart';

class AppRoutes {
  static const String auth = '/auth';
  static const String shell = '/';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String createGroup = '/create_group';
  static const String createChannel = '/create_channel';
  static const String codeVerification = '/code_verification';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case auth:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      case shell:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ShellUI(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return CupertinoPageRoute(builder: (context) => ChatScreen(chatId: args['chatId'] as String));
      case profile:
        final args = settings.arguments as Map<String, dynamic>;
        return CupertinoPageRoute(builder: (context) => ProfileScreen(userName: args['userName'] as String, avatarAsset: args['avatarAsset'] as String));
      case createGroup:
        return CupertinoPageRoute(builder: (context) => const CreateGroupScreen(), fullscreenDialog: true);
      case createChannel:
        return CupertinoPageRoute(builder: (context) => const CreateChannelScreen(), fullscreenDialog: true);
      default:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
    }
  }
}