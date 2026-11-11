import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/app_preferences_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class MuslimCoranApp extends ConsumerWidget {
  const MuslimCoranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Muslim Coran',
      debugShowCheckedModeBanner: false,
      locale: prefs.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.buildTheme(prefs.themeMode),
      routerConfig: router,
    );
  }
}
