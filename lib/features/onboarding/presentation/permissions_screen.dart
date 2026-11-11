import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../prayer/data/location_repository.dart';
import '../../prayer/data/prayer_alarm_scheduler.dart';
import '../../prayer/presentation/prayer_times_screen.dart';

/// E03 — Écran des permissions (Localisation & Notifications) :
/// - Chaque permission est expliquée pédagogiquement avant la demande système (§6).
/// - L'application reste 100 % utilisable si l'utilisateur refuse (choix manuel de la ville).
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _locationAuthorized = false;
  bool _notificationsInitialized = false;

  Future<void> _requestLocation() async {
    final CityEntity? gps =
        await ref.read(locationRepositoryProvider).acquireGpsLocation();
    if (gps != null && mounted) {
      ref.read(prayerControllerProvider.notifier).setCity(gps);
      setState(() => _locationAuthorized = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Refus pris en compte : la ville hors ligne par défaut (Ouagadougou) est activée.',
          ),
        ),
      );
    }
  }

  Future<void> _requestNotifications() async {
    await ref.read(prayerAlarmSchedulerProvider).initialize();
    if (mounted) {
      setState(() => _notificationsInitialized = true);
    }
  }

  void _finishOnboarding() {
    ref.read(appPreferencesProvider.notifier).completeOnboarding();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pour les prières'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryDeepGreen,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Localisation',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Utilisée uniquement sur votre téléphone pour calculer les horaires de prière et l’angle exact de la Qibla. Aucune coordonnée n’est envoyée sur Internet.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        children: <Widget>[
                          FilledButton(
                            onPressed: _requestLocation,
                            child: Text(
                              _locationAuthorized ? 'Autorisé ✓' : 'Autoriser',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => context.push(AppRoutes.cityPicker),
                            child: const Text('Choisir une ville'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.primaryDeepGreen,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Notifications & Adhan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Permet de programmer les alarmes exactes pour recevoir l’Adhan et les rappels avant chaque prière, même hors connexion.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _requestNotifications,
                        child: Text(
                          _notificationsInitialized
                              ? 'Activé ✓'
                              : 'Autoriser',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _finishOnboarding,
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
