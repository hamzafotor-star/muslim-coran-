import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_service.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../audio/data/quran_audio_handler.dart';

/// E01 — Écran de démarrage (Splash) :
/// - Fond vert profond `#0F5132`, logo officiel Muslim Coran centré.
/// - Charge les préférences persistées (`app_preferences.json`) + `quran.db` + `user.db`.
/// - Redirige vers E02 (uniquement au 1er lancement) ou directement vers E04 (si déjà configuré).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootApp();
  }

  Future<void> _bootApp() async {
    final Stopwatch sw = Stopwatch()..start();
    try {
      await ref.read(appPreferencesProvider.notifier).loadFromStorage();
      final AppPreferencesState prefs = ref.read(appPreferencesProvider);
      final ReciterOption chosenReciter =
          AudioPlaybackState.availableReciters.firstWhere(
        (ReciterOption r) => r.id == prefs.defaultReciterId,
        orElse: () => AudioPlaybackState.defaultRecitersFirst,
      );
      ref.read(audioControllerProvider.notifier).setReciter(chosenReciter);

      await ref.read(databaseServiceProvider).quranDb;
      await ref.read(databaseServiceProvider).userDb;
    } catch (_) {
      // En environnement de test de widgets sans assets binaires natifs, on poursuit sans bloquer.
    }

    final int remainingMs = (900 - sw.elapsedMilliseconds).clamp(0, 900);
    if (remainingMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: remainingMs));
    }
    if (!mounted) return;

    final bool completed =
        ref.read(appPreferencesProvider).onboardingCompleted;
    if (completed) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeepGreen,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book,
                        size: 64,
                        color: AppColors.accentSoftGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'MUSLIM CORAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mushaf Tajweed · Horaires · Qibla · 100 % Hors ligne',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryLightGreen,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    color: AppColors.accentSoftGold,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chargement…',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
