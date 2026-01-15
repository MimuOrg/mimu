import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mimu/data/settings_service.dart';

class AnimateOnDisplay extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final double slideDy;
  final bool staggered;
  final int staggerChildren;
  final bool rippleFade;

  const AnimateOnDisplay({
    super.key,
    required this.child,
    this.delayMs = 50,
    this.durationMs = 300,
    this.slideDy = 0.03,
    this.staggered = false,
    this.staggerChildren = 0,
    this.rippleFade = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOptimized = SettingsService.getOptimizeMimu();
    final shouldAnimate = !isOptimized || SettingsService.getAnimationsEnabled();
    
    if (!shouldAnimate) {
      return child;
    }

    if (staggered && child is Column) {
      final c = child as Column;
      return Column(
        crossAxisAlignment: c.crossAxisAlignment,
        mainAxisAlignment: c.mainAxisAlignment,
        children: [
          for (int i = 0; i < c.children.length; i++)
            AnimateOnDisplay(
              child: c.children[i],
              delayMs: delayMs + 40 * i,
              durationMs: durationMs,
              slideDy: slideDy,
            ),
        ],
      );
    }
    
    // Telegram iOS style: быстрые, плавные, естественные анимации
    Widget content = Animate(
      effects: [
        FadeEffect(
          delay: Duration(milliseconds: delayMs),
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOutCubic, // Telegram iOS стиль
        ),
        SlideEffect(
          begin: Offset(0, slideDy * 0.5), // Более тонкое движение
          end: Offset.zero,
          delay: Duration(milliseconds: delayMs),
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOutCubic, // Telegram iOS стиль
        ),
      ],
      child: child,
    );
    if (rippleFade && !isOptimized) {
      content = Stack(children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: 0.2,
            duration: Duration(milliseconds: (durationMs * 0.6).toInt()),
            curve: Curves.easeInOutCubic,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: const Color(0xFF0A0A0A).withOpacity(0.15), // Богатый черный вместо фиолетового
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        content,
      ]);
    }
    return content;
  }
}