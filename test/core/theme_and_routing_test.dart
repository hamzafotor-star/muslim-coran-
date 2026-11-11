import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/core/theme/app_colors.dart';
import 'package:muslim_coran/core/theme/app_theme.dart';
import 'package:muslim_coran/l10n/app_localizations.dart';

void main() {
  group('Phase 0 — Charte graphique, thèmes et internationalisation RTL', () {
    test('Vérifie les codes couleurs exacts de la charte des maquettes (§0)', () {
      expect(AppColors.primaryDeepGreen, const Color(0xFF0F5132));
      expect(AppColors.secondaryLightGreen, const Color(0xFFD1E7DD));
      expect(AppColors.accentSoftGold, const Color(0xFFC9A227));
      expect(AppColors.backgroundLight, const Color(0xFFFFFFFF));
      expect(AppColors.backgroundDark, const Color(0xFF121614));
      expect(AppColors.backgroundSepia, const Color(0xFFF4ECD8));
      expect(AppColors.textPrimaryLight, const Color(0xFF1B1F1D));
      expect(AppColors.textPrimaryDark, const Color(0xFFE8ECEA));
    });

    test('Construit les 3 thèmes Material 3 (Clair, Sombre, Sépia)', () {
      final ThemeData light = AppTheme.buildTheme(AppThemeMode.light);
      final ThemeData dark = AppTheme.buildTheme(AppThemeMode.dark);
      final ThemeData sepia = AppTheme.buildTheme(AppThemeMode.sepia);

      expect(light.scaffoldBackgroundColor, AppColors.backgroundLight);
      expect(dark.scaffoldBackgroundColor, AppColors.backgroundDark);
      expect(sepia.scaffoldBackgroundColor, AppColors.backgroundSepia);
    });

    test('Gère les traductions FR / AR / EN et détecte le mode RTL pour AR', () {
      const AppLocalizations fr = AppLocalizations(Locale('fr'));
      const AppLocalizations ar = AppLocalizations(Locale('ar'));
      const AppLocalizations en = AppLocalizations(Locale('en'));

      expect(fr.isRtl, isFalse);
      expect(ar.isRtl, isTrue);
      expect(en.isRtl, isFalse);

      expect(fr.tabQuran, 'Coran');
      expect(ar.tabQuran, 'القرآن');
      expect(en.tabQuran, 'Quran');
    });
  });
}
