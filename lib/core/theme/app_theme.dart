import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Modes de thème supportés par l'application (RF-15, E16).
enum AppThemeMode {
  light,
  dark,
  sepia,
}

/// Polices arabes OFL embarquées (RF-03, E16).
enum ArabicFontFamily {
  amiriQuran('AmiriQuran', 'Amiri Quran'),
  scheherazadeNew('ScheherazadeNew', 'Scheherazade New'),
  lateef('Lateef', 'Lateef');

  const ArabicFontFamily(this.fontFamily, this.displayName);
  final String fontFamily;
  final String displayName;
}

class AppTheme {
  const AppTheme._();

  static const double cardRadius = 16.0;
  static const double pageMargin = 16.0;
  static const double gridUnit = 8.0;

  static ThemeData buildTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return _buildLightTheme();
      case AppThemeMode.dark:
        return _buildDarkTheme();
      case AppThemeMode.sepia:
        return _buildSepiaTheme();
    }
  }

  static ThemeData _buildLightTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDeepGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryDeepGreen,
      onPrimary: Colors.white,
      secondary: AppColors.accentSoftGold,
      secondaryContainer: AppColors.secondaryLightGreen,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.textPrimaryLight,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundLight,
      cardColor: AppColors.cardLight,
      textColor: AppColors.textPrimaryLight,
    );
  }

  static ThemeData _buildDarkTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDeepGreen,
      brightness: Brightness.dark,
      primary: const Color(0xFF47A778),
      onPrimary: AppColors.backgroundDark,
      secondary: AppColors.accentSoftGold,
      secondaryContainer: const Color(0xFF1F3B2D),
      surface: AppColors.backgroundDark,
      onSurface: AppColors.textPrimaryDark,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundDark,
      cardColor: AppColors.cardDark,
      textColor: AppColors.textPrimaryDark,
    );
  }

  static ThemeData _buildSepiaTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDeepGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryDeepGreen,
      onPrimary: Colors.white,
      secondary: AppColors.accentSoftGold,
      secondaryContainer: const Color(0xFFE5DEC9),
      surface: AppColors.backgroundSepia,
      onSurface: AppColors.textPrimaryLight,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundSepia,
      cardColor: AppColors.cardSepia,
      textColor: AppColors.textPrimaryLight,
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color textColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: gridUnit),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDeepGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
