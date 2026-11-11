import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// E02 — Bienvenue (première ouverture) :
/// - 3 pages : **Lecture hors ligne**, **Horaires et Adhan**, **Qibla et suivi**.
/// - Choix de la langue (`Français`, `العربية`, `English`) sur la dernière page.
/// - Bouton « Passer » en haut à gauche.
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
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
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

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: TextButton(
          onPressed: () {
            ref.read(appPreferencesProvider.notifier).completeOnboarding();
            context.go(AppRoutes.permissions);
          },
          child: const Text('Passer'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int idx) {
                    setState(() => _currentPage = idx);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final _OnboardingSlide slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLightGreen,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 52,
                            color: AppColors.primaryDeepGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide.arabicCalligraphy,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 24,
                            color: AppColors.primaryDeepGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.45),
                        ),
                        if (index == _slides.length - 1) ...<Widget>[
                          const SizedBox(height: 24),
                          const Text(
                            'Choisissez la langue de l’interface :',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
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
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_slides.length, (int i) {
                  final bool active = i == _currentPage;
                  return Container(
                    width: active ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryDeepGreen
                          : AppColors.secondaryLightGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextOrProceed,
                  child: Text(
                    _currentPage == _slides.length - 1
                        ? 'Commencer'
                        : 'Suivant',
                  ),
                ),
              ),
            ],
          ),
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
