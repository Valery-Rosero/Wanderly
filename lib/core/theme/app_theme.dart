import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Paleta viajera
  // Océano (primario), Cielo (secundario), Arena (surface), Coral (accent)
  static const Color _primaryColor = Color(0xFF1E88E5); // azul océano
  static const Color _secondaryColor = Color(0xFF4FC3F7); // azul cielo
  static const Color _accentColor = Color(0xFFE76F51); // coral atardecer
  static const Color _surfaceSand = Color(0xFFF4EFE6); // arena clara
  static const Color _backgroundLight = Color(0xFFF8FAFC); // fondo suave
  static const Color _textDark = Color(0xFF102A43);
  static const Color _textLight = Colors.white;

  // 🌈 Gradiente principal (océano → cielo)
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
        tertiary: _accentColor,
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
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textDark),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
        bodyLarge: TextStyle(fontSize: 16, color: _textDark),
        bodyMedium: TextStyle(fontSize: 14, color: _textDark),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight),
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
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _secondaryColor.withOpacity(0.12),
        selectedColor: _secondaryColor.withOpacity(0.20),
        disabledColor: Colors.grey.shade200,
        labelStyle: const TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: _textLight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceSand,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade700),
        prefixIconColor: _primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _textLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _primaryColor,
        contentTextStyle: TextStyle(color: _textLight),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
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

  // 🌙 Tema oscuro
  static ThemeData dark() {
    const Color _darkBackground = Color(0xFF0B1E2D);
    const Color _darkSurface = Color(0xFF1F2937);
    const Color _darkSurfaceAlt = Color(0xFF111827);
    const Color _darkDivider = Color(0xFF374151);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _secondaryColor,
        secondary: _accentColor,
        tertiary: _accentColor,
        surface: _darkSurface,
        background: _darkBackground,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _textLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _textLight,
        ),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textLight),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textLight),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textLight),
        bodyLarge: TextStyle(fontSize: 16, color: _textLight),
        bodyMedium: TextStyle(fontSize: 14, color: _textLight),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        iconTheme: IconThemeData(color: _textLight),
        titleTextStyle: TextStyle(
          color: _textLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: _darkSurfaceAlt,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface,
        selectedColor: _secondaryColor.withOpacity(0.25),
        disabledColor: Colors.grey.shade700,
        labelStyle: const TextStyle(color: _textLight, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: _textLight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _secondaryColor,
        textColor: _textLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: _darkBackground, surfaceTintColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIconColor: _secondaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: _textDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondaryColor,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _secondaryColor,
        contentTextStyle: TextStyle(color: _textDark),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: _darkDivider, thickness: 1),
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
