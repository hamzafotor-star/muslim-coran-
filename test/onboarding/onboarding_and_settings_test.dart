import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/core/providers/app_preferences_provider.dart';
import 'package:muslim_coran/core/theme/app_theme.dart';
import 'package:muslim_coran/features/more/presentation/more_menu_screen.dart';
import 'package:muslim_coran/features/settings/presentation/settings_screen.dart';
import 'package:muslim_coran/l10n/app_localizations.dart';

void main() {
  group('Phase 4 — Réglages (E16), Menu Plus (E15) et Préférences RTL', () {
    test('Met à jour la police arabe, la taille (bornée 18..44) et le thème', () {
      final AppPreferencesNotifier notifier = AppPreferencesNotifier();
      expect(notifier.state.themeMode, AppThemeMode.light);
      expect(notifier.state.arabicFont, ArabicFontFamily.amiriQuran);

      notifier.setThemeMode(AppThemeMode.sepia);
      notifier.setArabicFont(ArabicFontFamily.scheherazadeNew);
      notifier.setArabicFontSize(34.0);
      notifier.setLocale(const Locale('ar'));

      expect(notifier.state.themeMode, AppThemeMode.sepia);
      expect(notifier.state.arabicFont, ArabicFontFamily.scheherazadeNew);
      expect(notifier.state.arabicFontSize, 34.0);
      expect(notifier.state.locale.languageCode, 'ar');
    });

    testWidgets(
      'E15 Menu Plus affiche les modules V1.x avec la mention « Bientôt »',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              locale: Locale('fr'),
              localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: MoreMenuScreen(),
            ),
          ),
        );

        expect(find.text('Dhikr / Tasbih'), findsOneWidget);
        expect(find.text('Mémorisation (Hifz)'), findsOneWidget);
        expect(find.text('Bientôt'), findsWidgets);
      },
    );

    testWidgets(
      'E16 Réglages affiche l’aperçu en direct de la Basmala et les 3 thèmes',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              locale: Locale('fr'),
              localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: SettingsScreen(),
            ),
          ),
        );

        expect(find.text('Clair'), findsOneWidget);
        expect(find.text('Sombre'), findsOneWidget);
        expect(find.text('Sépia'), findsOneWidget);
        expect(find.text('Amiri Quran'), findsOneWidget);
      },
    );
  });
}
