import 'package:flutter/material.dart';

/// Design system per .cursorrules: "Strict Boxy Black"
/// No glassmorphism. Solid surfaces. Cupertino soul, darker and sharper.
class AppStyles {
  AppStyles._();

  // --- Geometry & Colors ---
  static const Color backgroundOled = Color(0xFF0B0B0B); // OLED Black
  static const Color surfaceDeep = Color(0xFF111111); // Deep Grey
  static const Color borderColor = Color(0xFF515151); // Every surface must have this border
  static const double borderWidth = 0.6;
  static const double radiusStandard = 26.0; // Soft, modern rounding

  // --- Typography ---
  static const double letterSpacingSignature = -1.65; // Tight, dense, confident
  static const String fontFamily = 'Inter';

  // --- Motion ---
  static const Duration animationDuration = Duration(milliseconds: 180); // 170-200ms
  static const Curve animationCurve = Curves.easeOutCubic;

  // --- Surface decoration (DRY) ---
  static BoxDecoration surfaceDecoration({
    Color? color,
    double? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) =>
      BoxDecoration(
        color: color ?? surfaceDeep,
        borderRadius: BorderRadius.circular(borderRadius ?? radiusStandard),
        border: border ?? Border.all(color: borderColor, width: borderWidth),
        boxShadow: boxShadow,
      );

  static BoxDecoration cardDecoration({bool elevated = false}) =>
      surfaceDecoration(
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      );
}
