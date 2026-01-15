import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mimu/app/theme.dart';
import 'package:mimu/shared/glass_widgets.dart';

/// Богатая черная палитра для премиум дизайна
class RichBlackPalette {
  static const Color richBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF050505);
  static const Color charcoalBlack = Color(0xFF0A0A0A);
  static const Color darkCharcoal = Color(0xFF0F0F0F);
  static const Color mediumBlack = Color(0xFF1A1A1A);
  static const Color lightBlack = Color(0xFF252525);
  static const Color softBlack = Color(0xFF2A2A2A);
  static const Color mutedBlack = Color(0xFF303030);
}

/// Улучшенная карточка с богатым черным дизайном
class RichBlackCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool useGlow;
  final double? elevation;

  const RichBlackCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.useGlow = false,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RichBlackPalette.charcoalBlack.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: elevation ?? 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          if (useGlow)
            BoxShadow(
              color: RichBlackPalette.charcoalBlack.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: child,
    );

    if (useGlow) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: card,
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Улучшенная кнопка с богатым черным дизайном
class RichBlackButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsets? padding;
  final bool isOutlined;
  final bool useGlow;
  final IconData? icon;

  const RichBlackButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.isOutlined = false,
    this.useGlow = false,
    this.icon,
  });

  @override
  State<RichBlackButton> createState() => _RichBlackButtonState();
}

class _RichBlackButtonState extends State<RichBlackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final color = isEnabled
        ? RichBlackPalette.charcoalBlack
        : RichBlackPalette.mutedBlack;

    return GestureDetector(
      onTapDown: (_) {
        if (isEnabled) {
          setState(() => _isPressed = true);
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (isEnabled) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onPressed?.call();
        }
      },
      onTapCancel: () {
        if (isEnabled) {
          setState(() => _isPressed = false);
          _controller.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isOutlined
                    ? Colors.transparent
                    : color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isOutlined
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: widget.useGlow ? 16 : 8,
                    spreadRadius: widget.useGlow ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: Colors.white.withOpacity(isEnabled ? 0.9 : 0.5),
                    ),
                    const SizedBox(width: 8),
                  ],
                  DefaultTextStyle(
                    style: TextStyle(
                      color: Colors.white.withOpacity(isEnabled ? 0.9 : 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Индикатор загрузки с богатым черным дизайном
class RichBlackLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const RichBlackLoader({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  State<RichBlackLoader> createState() => _RichBlackLoaderState();
}

class _RichBlackLoaderState extends State<RichBlackLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RichBlackLoaderPainter(
              progress: _controller.value,
              color: widget.color ?? RichBlackPalette.charcoalBlack,
            ),
          );
        },
      ),
    );
  }
}

class _RichBlackLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RichBlackLoaderPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RichBlackLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Улучшенный чип с богатым черным дизайном
class RichBlackChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const RichBlackChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? RichBlackPalette.charcoalBlack.withOpacity(0.8)
                  : RichBlackPalette.deepBlack.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 1.5 : 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: RichBlackPalette.charcoalBlack.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: Colors.white.withOpacity(isSelected ? 0.9 : 0.7),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isSelected ? 0.9 : 0.7),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Улучшенный список с богатым черным дизайном
class RichBlackListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  const RichBlackListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? RichBlackPalette.charcoalBlack.withOpacity(0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Улучшенный поиск с богатым черным дизайном
class RichBlackSearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const RichBlackSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<RichBlackSearchBar> createState() => _RichBlackSearchBarState();
}

class _RichBlackSearchBarState extends State<RichBlackSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichBlackCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.search,
            size: 20,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Поиск...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                widget.onChanged?.call(value);
              },
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onClear?.call();
              },
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 20,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
}

/// Анимированный переход с богатым черным дизайном
class RichBlackPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  RichBlackPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

/// Градиентный фон с богатым черным дизайном
class RichBlackGradient extends StatelessWidget {
  final Widget child;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<Color>? colors;

  const RichBlackGradient({
    super.key,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ?? [
            RichBlackPalette.richBlack,
            RichBlackPalette.deepBlack,
            RichBlackPalette.charcoalBlack,
          ],
        ),
      ),
      child: child,
    );
  }
}

