import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// E15 — Menu « Plus » :
/// - Les modules de la V1.x (`Dhikr / Tasbih`, `Mémorisation`, `Objectifs (Khatma)`,
///   `Calendrier hégirien`, `Apprendre (Qaida)`) apparaissent avec la mention « Bientôt ».
/// - Accès direct à `Téléchargements` (E17), `Réglages` (E16), `Soutenir l'application` et `À propos`.
class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<_V1xFutureModule> upcomingModules = <_V1xFutureModule>[
      const _V1xFutureModule(
        icon: Icons.toll_outlined,
        title: 'Dhikr / Tasbih',
        subtitle: 'Compteur numérique & invocations du matin et du soir',
      ),
      const _V1xFutureModule(
        icon: Icons.psychology_alt_outlined,
        title: 'Mémorisation (Hifz)',
        subtitle: 'Révision espacée et répétition de passages',
      ),
      const _V1xFutureModule(
        icon: Icons.track_changes_outlined,
        title: 'Objectifs (Khatma)',
        subtitle: 'Plan de lecture en 30 jours et suivi quotidien',
      ),
      const _V1xFutureModule(
        icon: Icons.calendar_month_outlined,
        title: 'Calendrier hégirien',
        subtitle: 'Dates islamiques, jours blancs et fêtes',
      ),
      const _V1xFutureModule(
        icon: Icons.translate_outlined,
        title: 'Apprendre (Qaida)',
        subtitle: 'Leçons progressives d’alphabet et de lecture coranique',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tabMore,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.download_for_offline_outlined,
                color: AppColors.primaryDeepGreen,
              ),
              title: Text(
                l10n.downloads,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Gérer les sourates audio et les traductions hors ligne',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.downloads),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: AppColors.primaryDeepGreen,
              ),
              title: Text(
                l10n.settings,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Langue, thème Clair/Sombre/Sépia, police et taille du texte arabe',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.settings),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Modules prévus en version V1.x',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDeepGreen,
              ),
            ),
          ),
          ...upcomingModules.map(
            (_V1xFutureModule m) => Card(
              child: ListTile(
                enabled: false,
                leading: Icon(m.icon),
                title: Text(m.title),
                subtitle: Text(m.subtitle),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.comingSoon,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDeepGreen,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.volunteer_activism_outlined,
                color: AppColors.accentSoftGold,
              ),
              title: const Text('Soutenir l’application (Sadaqah Jariyah)'),
              subtitle: const Text(
                'Application 100 % gratuite, sans publicité ni pistage',
              ),
              onTap: () => _showAboutOrSupportDialog(
                context,
                title: 'Soutenir Muslim Coran',
                body:
                    'Muslim Coran est développé sans aucune publicité ni revente de données personnelles afin de préserver le recueillement pendant la lecture du Saint Coran.\n\n'
                    'Vous pouvez soutenir le projet en le partageant autour de vous et par vos invocations.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: AppColors.primaryDeepGreen,
              ),
              title: const Text('À propos & Licences'),
              subtitle: const Text(
                'Muslim Coran v1.0.0 · Sources : Tanzil.net, Hamidullah, GeoNames, Polices OFL',
              ),
              onTap: () => _showAboutOrSupportDialog(
                context,
                title: 'À propos & Crédits officiels',
                body:
                    '• Texte coranique Uthmani & Simple : Tanzil Project (https://tanzil.net) — Licence CC BY 3.0, vérifié par somme de contrôle SHA-256.\n'
                    '• Traduction française : Prof. Muhammad Hamidullah (Tanzil.net).\n'
                    '• Polices arabes : Amiri Quran, Scheherazade New, Lateef (SIL Open Font License 1.1).\n'
                    '• Données géographiques : GeoNames.org (CC BY 4.0).\n'
                    '• Calcul astronomique des prières : Bibliothèque open source Adhan (MIT).',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutOrSupportDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.45)),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _V1xFutureModule {
  const _V1xFutureModule({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
