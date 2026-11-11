import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/download_manager_service.dart';

/// E17 — Téléchargements hors ligne :
/// - Deux onglets : `[Audio][Traductions]`.
/// - Téléchargement par sourate ou en lot, avec pause et reprise.
/// - Option « Wi-Fi uniquement » pour économiser les données mobiles.
/// - Affichage clair de la taille avant téléchargement et de l'espace total utilisé.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, SurahDownloadTask> tasks =
        ref.watch(downloadManagerProvider);
    final DownloadManagerNotifier notifier =
        ref.read(downloadManagerProvider.notifier);
    final AppPreferencesState prefs = ref.watch(appPreferencesProvider);

    final double usedMb = notifier.totalDownloadedBytes / (1024 * 1024);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloads),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentSoftGold,
          tabs: const <Widget>[
            Tab(text: 'Audio'),
            Tab(text: 'Traductions'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Télécharger en Wi-Fi uniquement'),
            subtitle: const Text(
              'Économise votre forfait de données mobiles',
            ),
            value: prefs.wifiOnlyDownloads,
            onChanged: (bool val) => ref
                .read(appPreferencesProvider.notifier)
                .setWifiOnlyDownloads(val),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildAudioTab(tasks, notifier),
                _buildTranslationsTab(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Theme.of(context).cardTheme.color,
            child: Text(
              'Espace utilisé : ${usedMb.toStringAsFixed(1)} Mo (Base Coran + Traductions : 7,7 Mo)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTab(
    Map<String, SurahDownloadTask> tasks,
    DownloadManagerNotifier notifier,
  ) {
    final List<MapEntry<String, SurahDownloadTask>> entries =
        tasks.entries.toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          color: AppColors.secondaryLightGreen.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Mishary Rashid Al-Afasy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Sélection de sourates · Murattal 128 kbps'),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    for (final String key in tasks.keys) {
                      notifier.startOrResumeDownload(key);
                    }
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Tout télécharger'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((MapEntry<String, SurahDownloadTask> entry) {
          final String key = entry.key;
          final SurahDownloadTask task = entry.value;

          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${task.surahId}. ${task.surahName}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      _buildTaskTrailing(key, task, notifier),
                    ],
                  ),
                  if (task.status == DownloadItemStatus.running ||
                      task.status == DownloadItemStatus.paused) ...<Widget>[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: task.progress,
                      color: AppColors.primaryDeepGreen,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(task.progress * 100).round()}% · ${task.formattedSizeMb}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (task.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      task.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTaskTrailing(
    String key,
    SurahDownloadTask task,
    DownloadManagerNotifier notifier,
  ) {
    switch (task.status) {
      case DownloadItemStatus.done:
        return Text(
          '✓ ${task.formattedSizeMb}',
          style: const TextStyle(
            color: AppColors.primaryDeepGreen,
            fontWeight: FontWeight.bold,
          ),
        );
      case DownloadItemStatus.running:
        return IconButton(
          tooltip: 'Mettre en pause',
          icon: const Icon(Icons.pause_circle_outline),
          onPressed: () => notifier.pauseDownload(key),
        );
      case DownloadItemStatus.paused:
        return TextButton.icon(
          onPressed: () => notifier.startOrResumeDownload(key),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Reprendre'),
        );
      case DownloadItemStatus.error:
        return TextButton.icon(
          onPressed: () => notifier.startOrResumeDownload(key),
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        );
      case DownloadItemStatus.queued:
        return OutlinedButton.icon(
          onPressed: () => notifier.startOrResumeDownload(key),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text(task.formattedSizeMb),
        );
    }
  }

  Widget _buildTranslationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        Card(
          child: ListTile(
            leading: Icon(Icons.check_circle, color: AppColors.primaryDeepGreen),
            title: Text('Français — Muhammad Hamidullah'),
            subtitle: Text('Inclus hors ligne dans quran.db (Tanzil.net)'),
            trailing: Text('Installé ✓'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.check_circle, color: AppColors.primaryDeepGreen),
            title: Text('Anglais / Translittération phonétique'),
            subtitle: Text('Inclus hors ligne dans quran.db (Tanzil.net)'),
            trailing: Text('Installé ✓'),
          ),
        ),
      ],
    );
  }
}
