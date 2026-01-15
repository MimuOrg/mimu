import 'package:flutter/material.dart';
import 'package:mimu/data/settings_service.dart';

class NavigationService {
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
