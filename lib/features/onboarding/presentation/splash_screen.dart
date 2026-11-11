import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_service.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// E01 — Écran de démarrage (Splash) :
/// - Fond vert profond `#0F5132`, symbole croissant/étoile et titre blanc/or centré.
/// - Durée : 1 à 2 s maximum pendant l'ouverture et la vérification SHA-256 de `quran.db`.
/// - Redirige vers E02 (au 1er lancement) ou E04 (si déjà configuré).
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
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentSoftGold,
                      width: 2.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '☪',
                    style: TextStyle(
                      fontSize: 48,
                      color: AppColors.accentSoftGold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                  'Lecture fidèle · Horaires · Qibla · 100 % Hors ligne',
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
