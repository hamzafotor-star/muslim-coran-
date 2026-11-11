import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Modes de thème supportés par l'application (RF-15, E16).
enum AppThemeMode {
  light,
  dark,
  sepia,
}

/// Polices arabes OFL (3 embarquées hors ligne + 6 téléchargeables via FontLoader — RF-03, E16, E17).
enum ArabicFontFamily {
  amiriQuran(
    'AmiriQuran',
    'Amiri Quran',
    styleDescription: 'Style Naskh coranique classique (embarquée hors ligne)',
    isBuiltIn: true,
    estimatedSizeKb: 225,
  ),
  scheherazadeNew(
    'ScheherazadeNew',
    'Scheherazade New',
    styleDescription: 'Style Naskh traditionnel SIL (embarquée hors ligne)',
    isBuiltIn: true,
    estimatedSizeKb: 489,
  ),
  lateef(
    'Lateef',
    'Lateef',
    styleDescription: 'Style Naskh fluide SIL (embarquée hors ligne)',
    isBuiltIn: true,
    estimatedSizeKb: 317,
  ),
  notoNaskhArabic(
    'NotoNaskhArabic',
    'Noto Naskh Arabic',
    styleDescription: 'Haute lisibilité sur petits écrans Android (OFL)',
    isBuiltIn: false,
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/notonaskharabic/NotoNaskhArabic%5Bwght%5D.ttf',
    estimatedSizeKb: 295,
  ),
  harmattan(
    'Harmattan',
    'Harmattan (Afrique de l’Ouest)',
    styleDescription: 'Calligraphie coranique d’Afrique de l’Ouest / Warsh (OFL)',
    isBuiltIn: false,
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/harmattan/Harmattan-Regular.ttf',
    estimatedSizeKb: 310,
  ),
  alkalami(
    'Alkalami',
    'Alkalami (Sudani / Kano)',
    styleDescription: 'Calligraphie traditionnelle des manuscrits du Sahel (OFL)',
    isBuiltIn: false,
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/alkalami/Alkalami-Regular.ttf',
    estimatedSizeKb: 240,
  ),
  reemKufi(
    'ReemKufi',
    'Reem Kufi',
    styleDescription: 'Calligraphie coufique moderne (OFL)',
    isBuiltIn: false,
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/reemkufi/ReemKufi%5Bwght%5D.ttf',
    estimatedSizeKb: 185,
  ),
  arefRuqaa(
    'ArefRuqaa',
    'Aref Ruqaa',
    styleDescription: 'Calligraphie Ruq’ah classique (OFL)',
    isBuiltIn: false,
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/arefruqaa/ArefRuqaa-Regular.ttf',
    estimatedSizeKb: 190,
  ),
  mirza(
    'Mirza',
    'Mirza',
    styleDescription: 'Calligraphie orientale Naskh/Nastaliq (OFL)',
    isBuiltIn: false,
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/mirza/Mirza-Regular.ttf',
    estimatedSizeKb: 260,
  );

  const ArabicFontFamily(
    this.fontFamily,
    this.displayName, {
    required this.styleDescription,
    required this.isBuiltIn,
    required this.estimatedSizeKb,
    this.downloadUrl,
  });

  final String fontFamily;
  final String displayName;
  final String styleDescription;
  final bool isBuiltIn;
  final int estimatedSizeKb;
  final String? downloadUrl;
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
      cardTheme: CardTheme(
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
