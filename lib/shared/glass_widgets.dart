import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mimu/app/theme.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

// Helper function to convert BorderRadiusGeometry to LiquidShape
LiquidShape _borderRadiusToLiquidShape(BorderRadiusGeometry? borderRadius) {
  // Try to cast to BorderRadius to get radius values
  final border = borderRadius is BorderRadius ? borderRadius : BorderRadius.zero;
  final radius = border.topLeft.x;
  
  // If all corners have the same radius, use rounded rectangle
  // For zero radius, still use LiquidRoundedRectangle (works like rectangle)
  if (border.topLeft == border.topRight &&
      border.topLeft == border.bottomLeft &&
      border.topLeft == border.bottomRight) {
    return LiquidRoundedRectangle(borderRadius: radius);
  }
  
  // For different radii or non-BorderRadius, use zero radius as fallback
  return const LiquidRoundedRectangle(borderRadius: 0);
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool useFakeGlass;

  const GlassContainer({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.margin,
    this.useFakeGlass = true, // Используем FakeGlass по умолчанию для производительности
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassTheme>()!;
    final finalDecoration = decoration ?? glassTheme.baseGlass;

    final borderRadius = finalDecoration.borderRadius;
    final borderRadiusTyped = borderRadius is BorderRadius ? borderRadius : BorderRadius.zero;
    
    Widget glassWidget = ClipRRect(
      borderRadius: borderRadiusTyped,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: finalDecoration.copyWith(
            color: finalDecoration.color ?? Colors.white.withOpacity(0.03),
          ),
          child: child,
        ),
      ),
    );

    // Применяем FakeGlass для легковесного эффекта стекла
    if (useFakeGlass) {
      glassWidget = FakeGlass(
        shape: _borderRadiusToLiquidShape(borderRadius),
        child: glassWidget,
      );
    }

    return Container(
      margin: margin,
      child: glassWidget,
    );
  }
}

// Обертка для IconButton с fakeglass
class GlassIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;
  final EdgeInsets? padding;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.iconColor,
    this.padding,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding ?? const EdgeInsets.all(8),
      child: IconButton(
        icon: Icon(icon, size: iconSize ?? 20, color: iconColor ?? Colors.white.withOpacity(0.9)),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final EdgeInsets? padding;
  final double? minWidth;
  final double? minHeight;

  const GlassButton({
    super.key, 
    required this.onPressed, 
    required this.child,
    this.padding,
    this.minWidth,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassTheme>()!;
    final primaryColor = Theme.of(context).primaryColor;
    final borderRadius = glassTheme.interactiveGlass.borderRadius as BorderRadius;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: primaryColor.withOpacity(0.2),
        highlightColor: primaryColor.withOpacity(0.1),
        borderRadius: borderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            minWidth: minWidth ?? 64,
            minHeight: minHeight ?? 40,
            maxWidth: double.infinity,
            maxHeight: 56,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FakeGlass(
                shape: _borderRadiusToLiquidShape(borderRadius),
                child: Container(
                  padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: glassTheme.interactiveGlass.copyWith(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.03),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
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
    barrierColor: Colors.black.withOpacity(0.37),
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
      builder: (context, scrollController) => AnimatedContainer(
        duration: const Duration(milliseconds: 330),
        curve: Curves.easeOutQuint,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        padding: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 33, spreadRadius: 0, offset: const Offset(0, 12))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: FakeGlass(
              shape: const LiquidRoundedRectangle(borderRadius: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 6,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),
                      builder(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}