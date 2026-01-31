import 'package:flutter/material.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/shared/app_styles.dart';

/// Solid surface container. No glassmorphism. Per .cursorrules: "Strict Boxy Black".
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassTheme>();
    final finalDecoration = decoration ?? glassTheme?.baseGlass;

    final borderRadiusValue = borderRadius ??
        (finalDecoration?.borderRadius is BorderRadius
            ? (finalDecoration!.borderRadius as BorderRadius).topLeft.x
            : AppStyles.radiusStandard);
    final borderRadiusTyped = BorderRadius.circular(borderRadiusValue);

    final bgColor = backgroundColor ??
        finalDecoration?.color ??
        AppStyles.surfaceDeep;

    final container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadiusTyped,
        border: Border.all(
          color: AppStyles.borderColor,
          width: AppStyles.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: borderRadiusTyped,
      child: container,
    );
  }
}

/// Кнопка с иконкой с акцентом на глубину и паттерн фона.
class GlassIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;
  final EdgeInsets? padding;
  final double? borderRadius;

  const GlassIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.iconColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadiusValue = borderRadius ?? AppStyles.radiusStandard;
    final borderRadiusTyped = BorderRadius.circular(borderRadiusValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadiusTyped,
        child: Container(
          padding: padding ?? const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: borderRadiusTyped,
            color: AppStyles.surfaceDeep,
            border: Border.all(color: AppStyles.borderColor, width: AppStyles.borderWidth),
          ),
          child: Icon(
            icon,
            size: iconSize ?? 20,
            color: iconColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Аккуратные кнопки, адаптированные под темный паттерн.
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
    final borderRadiusValue = borderRadius ?? AppStyles.radiusStandard;
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
          duration: AppStyles.animationDuration,
          curve: AppStyles.animationCurve,
          constraints: BoxConstraints(
            minWidth: minWidth ?? 64,
            minHeight: minHeight ?? 48,
            maxWidth: double.infinity,
            maxHeight: 60,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isEnabled ? primaryColor.withOpacity(0.2) : AppStyles.surfaceDeep),
            borderRadius: borderRadiusTyped,
            border: Border.all(
              color: AppStyles.borderColor,
              width: AppStyles.borderWidth,
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.white.withOpacity(isEnabled ? 1.0 : 0.5),
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
    barrierColor: Colors.black.withOpacity(0.6),
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
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusStandard)),
          color: AppStyles.surfaceDeep,
          border: Border(
            top: BorderSide(color: AppStyles.borderColor, width: AppStyles.borderWidth),
            left: BorderSide(color: AppStyles.borderColor, width: AppStyles.borderWidth),
            right: BorderSide(color: AppStyles.borderColor, width: AppStyles.borderWidth),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.white.withOpacity(0.35),
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
