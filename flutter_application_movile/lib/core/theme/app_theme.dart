import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // 🎨 Colores base (constantes de uso global)
  static const Color _primaryColor = Color(0xFF3B82F6);
  static const Color _secondaryColor = Color(0xFF60A5FA);
  static const Color _backgroundLight = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textLight = Colors.white;

  // 🌈 Gradiente principal
  static const LinearGradient mainGradient = LinearGradient(
    colors: [_primaryColor, _secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ Alias para compatibilidad con el resto de la app
  static const LinearGradient accentGradient = mainGradient;

  // 🌞 Tema claro
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: _backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: Colors.white,
        background: _backgroundLight,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: _textDark),
        bodyMedium: TextStyle(fontSize: 14, color: _textDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: _textDark),
        titleTextStyle: TextStyle(
          color: _textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _primaryColor,
        contentTextStyle: TextStyle(color: _textLight),
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
