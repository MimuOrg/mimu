import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mimu/data/settings_service.dart';

// --- Theme Extension for Glass Effects ---
@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.baseGlass,
    required this.interactiveGlass,
    required this.panelGlass,
  });

  final BoxDecoration baseGlass;
  final BoxDecoration interactiveGlass;
  final BoxDecoration panelGlass;

  @override
  ThemeExtension<GlassTheme> copyWith({
    BoxDecoration? baseGlass,
    BoxDecoration? interactiveGlass,
    BoxDecoration? panelGlass,
  }) {
    return GlassTheme(
      baseGlass: baseGlass ?? this.baseGlass,
      interactiveGlass: interactiveGlass ?? this.interactiveGlass,
      panelGlass: panelGlass ?? this.panelGlass,
    );
  }

  @override
  ThemeExtension<GlassTheme> lerp(
    covariant ThemeExtension<GlassTheme>? other,
    double t,
  ) {
    if (other is! GlassTheme) {
      return this;
    }
    return GlassTheme(
      baseGlass: BoxDecoration.lerp(baseGlass, other.baseGlass, t)!,
      interactiveGlass:
          BoxDecoration.lerp(interactiveGlass, other.interactiveGlass, t)!,
      panelGlass: BoxDecoration.lerp(panelGlass, other.panelGlass, t)!,
    );
  }
}

// --- Font Provider ---
class FontProvider extends ChangeNotifier {
  String _font = 'Inter';
  int _fontSize = 16;
  String _fontStyle = 'Regular';
  
  FontProvider() {
    _loadSettings();
  }
  
  void _loadSettings() {
    _font = SettingsService.getFont();
    _fontSize = SettingsService.getFontSize();
    _fontStyle = SettingsService.getFontStyle();
  }
  
  String get font => _font;
  int get fontSize => _fontSize;
  String get fontStyle => _fontStyle;
  
  Future<void> setFont(String font) async {
    await SettingsService.setFont(font);
    _font = font;
    notifyListeners();
  }
  
  Future<void> setFontSize(int size) async {
    await SettingsService.setFontSize(size);
    _fontSize = size;
    notifyListeners();
  }
  
  Future<void> setFontStyle(String style) async {
    await SettingsService.setFontStyle(style);
    _fontStyle = style;
    notifyListeners();
  }
  
  TextStyle getTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
  }) {
    final size = fontSize ?? _fontSize.toDouble();
    
    // Определяем FontWeight из стиля
    FontWeight weight;
    bool isItalic = false;
    switch (_fontStyle) {
      case 'Light':
        weight = FontWeight.w300;
        break;
      case 'Regular':
        weight = FontWeight.normal;
        break;
      case 'Medium':
        weight = FontWeight.w500;
        break;
      case 'SemiBold':
        weight = FontWeight.w600;
        break;
      case 'Bold':
        weight = FontWeight.bold;
        break;
      case 'ExtraBold':
        weight = FontWeight.w800;
        break;
      case 'Italic':
        weight = FontWeight.normal;
        isItalic = true;
        break;
      case 'Bold Italic':
        weight = FontWeight.bold;
        isItalic = true;
        break;
      default:
        weight = fontWeight ?? FontWeight.normal;
    }

    final style = isItalic ? FontStyle.italic : (fontStyle ?? FontStyle.normal);

    TextTheme textTheme;
    switch (_font) {
      case 'Roboto':
        textTheme = GoogleFonts.robotoTextTheme();
        break;
      case 'Open Sans':
        textTheme = GoogleFonts.openSansTextTheme();
        break;
      case 'Lato':
        textTheme = GoogleFonts.latoTextTheme();
        break;
      case 'Montserrat':
        textTheme = GoogleFonts.montserratTextTheme();
        break;
      case 'Poppins':
        textTheme = GoogleFonts.poppinsTextTheme();
        break;
      case 'Nunito':
        textTheme = GoogleFonts.nunitoTextTheme();
        break;
      case 'Raleway':
        textTheme = GoogleFonts.ralewayTextTheme();
        break;
      case 'Antic':
        textTheme = GoogleFonts.anticTextTheme();
        break;
      default:
        textTheme = GoogleFonts.interTextTheme();
    }

    final resolvedColor = color ?? Colors.white;

    return textTheme.bodyMedium!.copyWith(
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      color: resolvedColor,
      letterSpacing: -0.0165 * size,
    );
  }
}

// --- Main Theme Data ---
class MimuTheme {
  static final _primaryTextColor = Colors.white.withOpacity(0.95);
  static final _secondaryTextColor = Colors.white.withOpacity(0.7);
  // Богатая черная палитра для премиум дизайна
  static const _backgroundColor = Color(0xFF000000); // Чистый черный фон
  static const _surfaceColor = Color(0xFF0A0A0A); // Богатый черный для поверхностей
  static const _richBlack = Color(0xFF050505); // Богатый черный для акцентов
  static const _deepBlack = Color(0xFF0F0F0F); // Глубокий черный для карточек
  static const _charcoalBlack = Color(0xFF1A1A1A); // Угольно-черный для интерактивных элементов

  static ThemeData darkTheme(Color accentColor, {FontProvider? fontProvider}) {
    TextTheme textTheme;
    final font = fontProvider?.font ?? 'Inter';
    switch (font) {
      case 'Roboto':
        textTheme = GoogleFonts.robotoTextTheme();
        break;
      case 'Open Sans':
        textTheme = GoogleFonts.openSansTextTheme();
        break;
      case 'Lato':
        textTheme = GoogleFonts.latoTextTheme();
        break;
      case 'Montserrat':
        textTheme = GoogleFonts.montserratTextTheme();
        break;
      case 'Poppins':
        textTheme = GoogleFonts.poppinsTextTheme();
        break;
      case 'Nunito':
        textTheme = GoogleFonts.nunitoTextTheme();
        break;
      case 'Raleway':
        textTheme = GoogleFonts.ralewayTextTheme();
        break;
      case 'Antic':
        textTheme = GoogleFonts.anticTextTheme();
        break;
      default:
        textTheme = GoogleFonts.interTextTheme();
    }

    textTheme = textTheme.apply(
      bodyColor: _primaryTextColor,
      displayColor: _primaryTextColor,
    );

    final fontSize = fontProvider?.fontSize ?? 16;
    
    // Определяем FontWeight и FontStyle из стиля
    FontWeight fontWeight = FontWeight.normal;
    FontStyle fontStyle = FontStyle.normal;
    final style = fontProvider?.fontStyle ?? 'Regular';
    switch (style) {
      case 'Light':
        fontWeight = FontWeight.w300;
        break;
      case 'Regular':
        fontWeight = FontWeight.normal;
        break;
      case 'Medium':
        fontWeight = FontWeight.w500;
        break;
      case 'SemiBold':
        fontWeight = FontWeight.w600;
        break;
      case 'Bold':
        fontWeight = FontWeight.bold;
        break;
      case 'ExtraBold':
        fontWeight = FontWeight.w800;
        break;
      case 'Italic':
        fontWeight = FontWeight.normal;
        fontStyle = FontStyle.italic;
        break;
      case 'Bold Italic':
        fontWeight = FontWeight.bold;
        fontStyle = FontStyle.italic;
        break;
    }

    final adjustedTextTheme = textTheme.copyWith(
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: fontSize.toDouble(),
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: _primaryTextColor,
        letterSpacing: -0.0165 * fontSize,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: (fontSize * 1.125).toDouble(),
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: _primaryTextColor,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        fontSize: (fontSize * 0.875).toDouble(),
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: _secondaryTextColor,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: (fontSize * 1.25).toDouble(),
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: _primaryTextColor,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: (fontSize * 1.5).toDouble(),
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: _primaryTextColor,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(color: _secondaryTextColor),
      labelSmall: textTheme.labelSmall?.copyWith(color: _secondaryTextColor),
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: _backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        background: _backgroundColor,
        surface: _surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: _primaryTextColor,
        onSurface: _primaryTextColor,
        error: Colors.redAccent,
        // Дополнительные черные оттенки
        tertiary: _richBlack,
        onTertiary: Colors.white,
        surfaceVariant: _deepBlack,
        onSurfaceVariant: _secondaryTextColor,
      ),
      textTheme: adjustedTextTheme,
      iconTheme: IconThemeData(color: _primaryTextColor, size: 22),
      dividerColor: Colors.white.withOpacity(0.1),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: fontProvider?.font == 'Inter' ? null : GoogleFonts.getFont(fontProvider?.font ?? 'Inter').fontFamily,
            letterSpacing: -0.0165 * 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(64, 40),
          maximumSize: const Size(double.infinity, 48),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontProvider?.font == 'Inter' ? null : GoogleFonts.getFont(fontProvider?.font ?? 'Inter').fontFamily,
            letterSpacing: -0.0165 * 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(88, 44),
          maximumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _primaryTextColor,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(40, 40),
          maximumSize: const Size(48, 48),
          padding: const EdgeInsets.all(8),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _charcoalBlack,
        textStyle: TextStyle(color: _primaryTextColor, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.8),
      ),
      extensions: <ThemeExtension<dynamic>>[
        GlassTheme(
          baseGlass: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
          ),
          interactiveGlass: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
          ),
          panelGlass: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _richBlack.withOpacity(0.6),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Theme Provider ---
class ThemeProvider extends ChangeNotifier {
  // Богатый черный как основной акцентный цвет
  Color _accentColor = const Color(0xFF1A1A1A); // Богатый угольно-черный
  Color _originalAccentColor = const Color(0xFF0A0A0A); // Оригинальный богатый черный
  String _currentTheme = 'Mimu Classical';
  String? _backgroundImage;
  
  // Палитра богатых черных оттенков
  static const Color richBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF050505);
  static const Color charcoalBlack = Color(0xFF0A0A0A);
  static const Color darkCharcoal = Color(0xFF0F0F0F);
  static const Color mediumBlack = Color(0xFF1A1A1A);
  static const Color lightBlack = Color(0xFF252525);
  
  Color get accentColor => _accentColor;
  Color get originalAccentColor => _originalAccentColor;
  String get currentTheme => _currentTheme;
  String? get backgroundImage => _backgroundImage;

  void changeAccentColor(Color color) {
    // Store original color for comparison
    _originalAccentColor = color;
    // Слегка затемняем цвет для глубины
    _accentColor = Color.fromRGBO(
      (color.red * 0.9).round().clamp(0, 255),
      (color.green * 0.9).round().clamp(0, 255),
      (color.blue * 0.9).round().clamp(0, 255),
      1.0,
    );
    notifyListeners();
  }

  void changeTheme(String themeName) {
    _currentTheme = themeName;
    // Настройка богатых черных оттенков для разных тем
    switch (themeName) {
      case 'Mimu Classical':
        _accentColor = charcoalBlack; // Богатый угольно-черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Winter Ocean':
        _accentColor = darkCharcoal; // Глубокий черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Melanholic':
        _accentColor = deepBlack; // Глубокий черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Dark Mode':
        _accentColor = richBlack; // Чистый черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Light Mode':
        _accentColor = mediumBlack; // Средний черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Amoled Black':
        _accentColor = richBlack; // Чистый черный для AMOLED
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Ocean Blue':
        _accentColor = charcoalBlack; // Угольно-черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Sunset Orange':
        _accentColor = darkCharcoal; // Глубокий черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Forest Green':
        _accentColor = deepBlack; // Глубокий черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Lavender Purple':
        _accentColor = mediumBlack; // Средний черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Rich Black':
        _accentColor = richBlack; // Богатый черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Charcoal':
        _accentColor = charcoalBlack; // Угольно-черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      case 'Deep Black':
        _accentColor = deepBlack; // Глубокий черный
        _backgroundImage = 'assets/images/background_pattern.png';
        break;
      default:
        _accentColor = charcoalBlack; // Богатый угольно-черный по умолчанию
        _backgroundImage = 'assets/images/background_pattern.png';
    }
    notifyListeners();
  }
}