import 'package:flutter/material.dart';
import 'package:mimu/data/settings_service.dart';
import 'package:mimu/app/routes.dart';

class NavigationService {
  static void navigateToChat(BuildContext context, String chatId) {
    Navigator.of(context).pushNamed(AppRoutes.chat, arguments: {'chatId': chatId});
  }
  static Route createSlideTransitionRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final isOptimized = SettingsService.getOptimizeMimu();
        final shouldAnimate = !isOptimized || SettingsService.getAnimationsEnabled();
        
        if (!shouldAnimate) {
          return child;
        }
        
        // Telegram iOS style: быстрый и плавный переход
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250), // Telegram iOS: быстрее
    );
  }
}
