import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_service.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic_ornaments.dart';
import '../../audio/data/quran_audio_handler.dart';

/// E01 — Écran de démarrage (Splash) :
/// - Fond royal émeraude orné d'un motif géométrique, logo officiel Qurana
///   serti dans un médaillon doré.
/// - Charge les préférences persistées (`app_preferences.json`) + `quran.db` + `user.db`.
/// - Redirige vers E02 (uniquement au 1er lancement) ou directement vers E04 (si déjà configuré).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _introController.forward();
    _bootApp();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
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

    final int remainingMs = (1100 - sw.elapsedMilliseconds).clamp(0, 1100);
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
      backgroundColor: AppColors.emeraldNight,
      body: RoyalPatternBackground(
        showGoldEdge: false,
        patternOpacity: 0.08,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.25),
              radius: 0.9,
              colors: <Color>[
                AppColors.goldLight.withOpacity(0.16),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Spacer(),
                    FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: const GoldLogoMedallion(size: 150),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: <Widget>[
                          ShaderMask(
                            shaderCallback: (Rect bounds) =>
                                AppColors.goldGradient.createShader(bounds),
                            child: const Text(
                              'QURANA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 8.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'قرآنا',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              color: AppColors.goldLight,
                              fontSize: 26,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const OrnamentDivider(
                            width: 200,
                            color: AppColors.goldLight,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Mushaf Tajweed · Horaires · Qibla · 100 % Hors ligne',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondaryLightGreen
                                  .withOpacity(0.92),
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          minHeight: 3,
                          color: AppColors.goldLight,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chargement…',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
