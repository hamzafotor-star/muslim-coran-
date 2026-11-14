import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic_ornaments.dart';

/// E02 — Bienvenue (première ouverture) :
/// - 3 cartes illustrées (motifs géométriques islamiques) : **Lecture hors ligne**,
///   **Horaires et Adhan**, **Qibla et suivi**.
/// - Choix de la langue (`Français`, `العربية`, `English`) sur la dernière page.
/// - Bouton « Passer » en haut.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.menu_book_outlined,
      arabicCalligraphy: 'إِنَّا نَحْنُ نَزَّلْنَا الذِّكْرَ',
      title: 'Lisez le Coran, partout, sans internet',
      subtitle:
          'Texte Uthmani vérifié (Tanzil.net), traductions française et anglaise, recherche instantanée avec ou sans voyelles.',
    ),
    _OnboardingSlide(
      icon: Icons.schedule_outlined,
      arabicCalligraphy: 'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
      title: 'Horaires de prière et Adhan précis',
      subtitle:
          'Calcul astronomique 100 % local adapté à l’Afrique de l’Ouest et au monde, avec alarmes exactes et rappels.',
    ),
    _OnboardingSlide(
      icon: Icons.explore_outlined,
      arabicCalligraphy: 'فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ',
      title: 'Qibla et suivi de votre lecture',
      subtitle:
          'Boussole vers la Kaaba, signets, notes personnelles et reprise automatique sans création de compte.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextOrProceed() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      ref.read(appPreferencesProvider.notifier).completeOnboarding();
      context.go(AppRoutes.permissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
    final AppPreferencesNotifier notifier =
        ref.read(appPreferencesProvider.notifier);
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent =
        isDark ? AppColors.goldLight : AppColors.primaryDeepGreen;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // En-tête : médaillon + marque + « Passer »
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: <Widget>[
                  const GoldLogoMedallion(size: 40, glow: false),
                  const SizedBox(width: 8),
                  Text(
                    'QURANA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(appPreferencesProvider.notifier)
                          .completeOnboarding();
                      context.go(AppRoutes.permissions);
                    },
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (int idx) {
                  setState(() => _currentPage = idx);
                },
                itemBuilder: (BuildContext context, int index) {
                  final _OnboardingSlide slide = _slides[index];
                  final bool isLast = index == _slides.length - 1;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      children: <Widget>[
                        _SlideIllustration(
                          icon: slide.icon,
                          calligraphy: slide.arabicCalligraphy,
                          step: index + 1,
                          total: _slides.length,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const OrnamentDivider(width: 140),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isLast) ...<Widget>[
                          const SizedBox(height: 22),
                          Text(
                            'Choisissez la langue de l’interface :',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: <Widget>[
                              ChoiceChip(
                                label: const Text('Français'),
                                selected: prefs.locale.languageCode == 'fr',
                                onSelected: (_) =>
                                    notifier.setLocale(const Locale('fr')),
                              ),
                              ChoiceChip(
                                label: const Text('العربية'),
                                selected: prefs.locale.languageCode == 'ar',
                                onSelected: (_) =>
                                    notifier.setLocale(const Locale('ar')),
                              ),
                              ChoiceChip(
                                label: const Text('English'),
                                selected: prefs.locale.languageCode == 'en',
                                onSelected: (_) =>
                                    notifier.setLocale(const Locale('en')),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(_slides.length, (int i) {
                      final bool active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: active ? 26 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: active ? AppColors.goldGradient : null,
                          color: active
                              ? null
                              : AppColors.accentSoftGold.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.softShadow(opacity: 0.25),
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.goldLight.withOpacity(0.7),
                            ),
                          ),
                        ),
                        onPressed: _nextOrProceed,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Commencer'
                                  : 'Suivant',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: AppColors.goldLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte illustrée : fond royal émeraude à motif géométrique, étoile dorée
/// à 8 branches portant l'icône, et calligraphie arabe en bas.
class _SlideIllustration extends StatelessWidget {
  const _SlideIllustration({
    required this.icon,
    required this.calligraphy,
    required this.step,
    required this.total,
  });

  final IconData icon;
  final String calligraphy;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return RoyalPatternBackground(
      borderRadius: BorderRadius.circular(28),
      patternOpacity: 0.09,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 0.85,
            colors: <Color>[
              AppColors.goldLight.withOpacity(0.18),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.goldLight.withOpacity(0.6),
                  ),
                ),
                child: Text(
                  '$step / $total',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 132,
              height: 132,
              child: CustomPaint(
                painter: IslamicStarPainter(
                  fillGradient: AppColors.goldGradient,
                  strokeColor: AppColors.goldLight.withOpacity(0.9),
                  strokeWidth: 1.4,
                  innerRingColor: AppColors.emeraldNight.withOpacity(0.35),
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emeraldNight,
                    ),
                    child: Icon(icon, size: 32, color: AppColors.goldLight),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              calligraphy,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 23,
                height: 1.9,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.arabicCalligraphy,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String arabicCalligraphy;
  final String title;
  final String subtitle;
}
