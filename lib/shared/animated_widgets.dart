import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    this.delayMs = 100,
    this.durationMs = 500,
    this.slideDy = 0.06,
    this.staggered = false,
    this.staggerChildren = 0,
    this.rippleFade = false,
  });

  @override
  Widget build(BuildContext context) {
    if (staggered && child is Column) {
      final c = child as Column;
      return Column(
        crossAxisAlignment: c.crossAxisAlignment,
        mainAxisAlignment: c.mainAxisAlignment,
        children: [
          for (int i = 0; i < c.children.length; i++)
            AnimateOnDisplay(
              child: c.children[i],
              delayMs: delayMs + 65 * i,
              durationMs: durationMs,
              slideDy: slideDy,
            ),
        ],
      );
    }
    Widget content = Animate(
      effects: [
        if (rippleFade)
          FadeEffect(
            delay: Duration(milliseconds: delayMs),
            duration: Duration(milliseconds: (durationMs * 0.8).toInt()),
            curve: Curves.easeInOutQuint,
          ),
        FadeEffect(
          delay: Duration(milliseconds: delayMs),
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOutCubic,
        ),
        SlideEffect(
          begin: Offset(0, slideDy),
          end: Offset.zero,
          delay: Duration(milliseconds: delayMs),
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOutExpo,
        ),
        ScaleEffect(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: Duration(milliseconds: (durationMs * 0.7).toInt()),
          curve: Curves.easeOutBack,
        ),
      ],
      child: child,
    );
    if (rippleFade) {
      content = Stack(children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: 0.25,
            duration: Duration(milliseconds: (durationMs * 0.5).toInt()),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                // ripple overlay look
                borderRadius: BorderRadius.circular(15),
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