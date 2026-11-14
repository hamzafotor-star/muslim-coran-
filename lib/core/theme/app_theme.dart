import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Modes de thème supportés par l'application (RF-15, E16).
enum AppThemeMode {
  light,
  dark,
  sepia,
}

/// Polices arabes OFL (Mushaf Tajweed + 3 embarquées hors ligne + 6 téléchargeables via FontLoader — RF-03, E16, E17).
enum ArabicFontFamily {
  mushafTajweed(
    'AmiriQuran',
    'Mushaf Tajweed (Couleurs)',
    styleDescription: ' Écriture Uthmani avec coloration des règles de Tajweed (embarquée)',
    isBuiltIn: true,
    estimatedSizeKb: 225,
  ),
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

  static const double cardRadius = 18.0;
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
      primaryContainer: AppColors.secondaryLightGreen,
      onPrimaryContainer: AppColors.emeraldNight,
      secondary: AppColors.accentSoftGold,
      onSecondary: AppColors.emeraldNight,
      secondaryContainer: AppColors.secondaryLightGreen,
      onSecondaryContainer: AppColors.emeraldNight,
      tertiary: AppColors.goldLight,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundLight,
      cardColor: AppColors.cardLight,
      textColor: AppColors.textPrimaryLight,
      secondaryTextColor: AppColors.textSecondaryLight,
    );
  }

  static ThemeData _buildDarkTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDeepGreen,
      brightness: Brightness.dark,
      primary: AppColors.emeraldGlow,
      onPrimary: AppColors.backgroundDark,
      primaryContainer: const Color(0xFF1F3B2D),
      onPrimaryContainer: AppColors.secondaryLightGreen,
      secondary: AppColors.goldLight,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: const Color(0xFF1F3B2D),
      onSecondaryContainer: AppColors.secondaryLightGreen,
      tertiary: AppColors.accentSoftGold,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundDark,
      cardColor: AppColors.cardDark,
      textColor: AppColors.textPrimaryDark,
      secondaryTextColor: AppColors.textSecondaryDark,
    );
  }

  static ThemeData _buildSepiaTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDeepGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryDeepGreen,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE5DEC9),
      onPrimaryContainer: AppColors.emeraldNight,
      secondary: AppColors.accentSoftGold,
      onSecondary: AppColors.emeraldNight,
      secondaryContainer: const Color(0xFFE5DEC9),
      onSecondaryContainer: AppColors.emeraldNight,
      tertiary: AppColors.goldDeep,
      surface: AppColors.backgroundSepia,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
    );
    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.backgroundSepia,
      cardColor: AppColors.cardSepia,
      textColor: AppColors.textPrimaryLight,
      secondaryTextColor: AppColors.textSecondaryLight,
    );
  }

  /// Typographie soignée : titres affirmés, interlignage confortable.
  static TextTheme _buildTextTheme(
    TextTheme base,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
          bodySmall: base.bodySmall?.copyWith(
            height: 1.4,
            color: secondaryTextColor,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        )
        .apply(bodyColor: textColor, displayColor: textColor);
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color goldBorder =
        AppColors.accentSoftGold.withOpacity(isDark ? 0.28 : 0.22);
    final Color accentOnSurface =
        isDark ? AppColors.goldLight : AppColors.primaryDeepGreen;
    final TextTheme baseText = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final TextTheme textTheme =
        _buildTextTheme(baseText, textColor, secondaryTextColor);

    final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: BorderSide(color: goldBorder, width: 0.8),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: goldBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppColors.emeraldNight.withOpacity(0.15),
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: accentOnSurface),
        actionsIconTheme: IconThemeData(color: accentOnSurface),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: AppColors.emeraldNight.withOpacity(isDark ? 0.5 : 0.10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: cardShape,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accentOnSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(color: textColor),
        subtitleTextStyle:
            textTheme.bodySmall?.copyWith(color: secondaryTextColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.emeraldNight.withOpacity(0.18),
        height: 68,
        indicatorColor: isDark
            ? AppColors.accentSoftGold.withOpacity(0.22)
            : AppColors.secondaryLightGreen,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.accentSoftGold.withOpacity(0.55),
            width: 1,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) {
            final bool selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: selected ? 26 : 24,
              color: selected ? accentOnSurface : secondaryTextColor,
            );
          },
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
            final bool selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.3,
              color: selected ? accentOnSurface : secondaryTextColor,
            );
          },
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: accentOnSurface,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: AppColors.accentSoftGold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: goldBorder,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.accentSoftGold, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        prefixIconColor: accentOnSurface,
        hintStyle: TextStyle(color: secondaryTextColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: goldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: goldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.accentSoftGold, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: isDark
            ? AppColors.accentSoftGold.withOpacity(0.25)
            : AppColors.secondaryLightGreen,
        side: BorderSide(color: goldBorder),
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDeepGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.emeraldNight.withOpacity(0.3),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentOnSurface,
          side: BorderSide(
            color: AppColors.accentSoftGold.withOpacity(0.7),
            width: 1.2,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentOnSurface,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDeepGreen,
        foregroundColor: AppColors.goldLight,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: goldBorder),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: textColor),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.accentSoftGold.withOpacity(0.6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.emeraldNight,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: AppColors.goldLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.accentSoftGold.withOpacity(0.5),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.goldLight
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDeepGreen
              : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentSoftGold,
      ),
      dividerTheme: DividerThemeData(
        color: goldBorder,
        thickness: 0.8,
        space: 24,
      ),
    );
  }
}
