import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/data/settings_service.dart';

/// Современный контейнер в стиле Telegram iOS
/// Упрощенная версия без liquid glass, с аккуратными панелями
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool useBlur;
  final Color? backgroundColor;
  final double? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.margin,
    this.useBlur = false, // По умолчанию без блюра, как в Telegram
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassTheme>();
    final finalDecoration = decoration ?? glassTheme?.baseGlass;
    final isOptimized = SettingsService.getOptimizeMimu();

    final borderRadiusValue = borderRadius ?? 
        (finalDecoration?.borderRadius is BorderRadius 
            ? (finalDecoration!.borderRadius as BorderRadius).topLeft.x 
            : 12.0);
    final borderRadiusTyped = BorderRadius.circular(borderRadiusValue);

    // Telegram iOS стиль - чистая панель с легкой прозрачностью
    final bgColor = backgroundColor ?? 
        finalDecoration?.color ?? 
        const Color(0xFF1C1C1E).withOpacity(0.8); // iOS стиль

    Widget container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadiusTyped,
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    // Telegram iOS стиль - блюр только для модальных окон и bottom sheets
    // Для обычных элементов используем простые панели без блюра
    container = ClipRRect(
      borderRadius: borderRadiusTyped,
      child: container,
    );

    return container;
  }
}

/// Кнопка с иконкой в стиле Telegram iOS
class GlassIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;
  final EdgeInsets? padding;
  final String? tooltip;
  final double? borderRadius;

  const GlassIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.iconColor,
    this.padding,
    this.tooltip,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadiusValue = borderRadius ?? 8.0;
    final borderRadiusTyped = BorderRadius.circular(borderRadiusValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadiusTyped,
        child: Container(
          padding: padding ?? const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: borderRadiusTyped,
          ),
          child: Icon(
            icon,
            size: iconSize ?? 20,
            color: iconColor ?? Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}

/// Кнопка в стиле Telegram iOS
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsets? padding;
  final double? minWidth;
  final double? minHeight;
  final bool enabled;
  final Color? backgroundColor;
  final double? borderRadius;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.minWidth,
    this.minHeight,
    this.enabled = true,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final borderRadiusValue = borderRadius ?? 12.0;
    final borderRadiusTyped = BorderRadius.circular(borderRadiusValue);
    final isEnabled = enabled && onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: borderRadiusTyped,
        splashColor: isEnabled ? Colors.white.withOpacity(0.1) : Colors.transparent,
        highlightColor: isEnabled ? Colors.white.withOpacity(0.05) : Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: BoxConstraints(
            minWidth: minWidth ?? 64,
            minHeight: minHeight ?? 44,
            maxWidth: double.infinity,
            maxHeight: 56,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? 
                (isEnabled 
                    ? primaryColor.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05)),
            borderRadius: borderRadiusTyped,
            border: Border.all(
              color: isEnabled 
                  ? Colors.white.withOpacity(0.12)
                  : Colors.white.withOpacity(0.05),
              width: 0.5,
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.white.withOpacity(isEnabled ? 1.0 : 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double minChildSize = 0.22,
  double maxChildSize = 0.85,
  double initialChildSize = 0.34,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (ctx) => _GlassDraggableSheet(
      builder: builder,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      initialChildSize: initialChildSize,
    ),
  );
}

class _GlassDraggableSheet extends StatelessWidget {
  final double minChildSize;
  final double maxChildSize;
  final double initialChildSize;
  final WidgetBuilder builder;
  const _GlassDraggableSheet({
    required this.builder,
    required this.minChildSize,
    required this.maxChildSize,
    required this.initialChildSize,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: const Color(0xFF1C1C1E), // Telegram iOS стиль
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar в стиле iOS
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.5),
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
