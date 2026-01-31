import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mimu/shared/enhanced_ui_components.dart';

/// Расширенные анимации с богатым черным дизайном
class RichBlackAnimations {
  /// Плавное появление с масштабированием
  static Widget fadeScaleIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration, curve: Curves.easeOutCubic)
        .scale(
          delay: delay,
          duration: duration,
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutCubic,
        );
  }

  /// Скольжение снизу с затемнением
  static Widget slideUpFade({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration)
        .slideY(
          delay: delay,
          duration: duration,
          begin: 0.2,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }

  /// Пульсирующее свечение
  static Widget pulseGlow({
    required Widget child,
    Color? glowColor,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
      duration: duration,
      color: glowColor ?? RichBlackPalette.charcoalBlack.withOpacity(0.3),
    );
  }

  /// Вращение с масштабированием
  static Widget rotateScale({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return child
        .animate()
        .scale(
          delay: delay,
          duration: duration,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutBack,
        )
        .rotate(
          delay: delay,
          duration: duration,
          begin: -0.1,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }

  /// Эффект волны
  static Widget wave({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration)
        .slideX(
          delay: delay,
          duration: duration,
          begin: -0.1,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }

  /// Эффект появления снизу с отскоком
  static Widget bounceUp({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration)
        .slideY(
          delay: delay,
          duration: duration,
          begin: 0.3,
          end: 0,
          curve: Curves.easeOutBack,
        );
  }

  /// Эффект масштабирования при нажатии
  static Widget pressScale({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) {},
      onTap: onTap,
      child: child
          .animate()
          .scale(
            duration: const Duration(milliseconds: 100),
            begin: const Offset(1.0, 1.0),
            end: const Offset(0.95, 0.95),
          )
          .then()
          .scale(
            duration: const Duration(milliseconds: 100),
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.0, 1.0),
          ),
    );
  }

  /// Каскадное появление для списков
  static Widget staggeredList({
    required List<Widget> children,
    Duration baseDelay = const Duration(milliseconds: 50),
    Duration itemDuration = const Duration(milliseconds: 300),
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return fadeScaleIn(
          child: child,
          delay: baseDelay * index,
          duration: itemDuration,
        );
      }).toList(),
    );
  }

  /// Эффект свечения при наведении
  static Widget hoverGlow({
    required Widget child,
    Color? glowColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? RichBlackPalette.charcoalBlack).withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  /// Эффект размытия при загрузке
  static Widget loadingBlur({
    required Widget child,
    required bool isLoading,
  }) {
    return AnimatedOpacity(
      opacity: isLoading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}

/// Расширенные переходы между экранами
class RichBlackTransitions {
  /// Плавный переход с затемнением
  static PageRouteBuilder fadeTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Переход с масштабированием
  static PageRouteBuilder scaleTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  /// Переход с поворотом
  static PageRouteBuilder rotationTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }
}

/// Микроинтеракции с богатым черным дизайном
class RichBlackMicroInteractions {
  /// Тактильная обратная связь с вибрацией
  static void hapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.lightImpact,
  }) {
    switch (type) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// Анимация успешного действия
  static Widget successAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return child
        .animate()
        .scale(
          duration: duration,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          curve: Curves.easeOut,
        )
        .then()
        .scale(
          duration: duration,
          begin: const Offset(1.1, 1.1),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeIn,
        );
  }

  /// Анимация ошибки
  static Widget errorAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return child
        .animate()
        .shake(
          duration: duration,
          hz: 4,
          curve: Curves.easeInOut,
        );
  }
}

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
}

