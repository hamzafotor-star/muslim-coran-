import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fonts/font_download_service.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../audio/data/quran_audio_handler.dart';
import '../../quran/domain/utils/arabic_normalizer.dart';
import '../data/download_manager_service.dart';

/// E17 — Téléchargements hors ligne :
/// - Trois onglets : `[Audio (12 Récitateurs)][Polices Arabes][Traductions]`.
/// - Choix du récitateur (dont Abdullah Al-Matrood, Mishary Al-Afasy, Abdul Basit, etc.)
///   et téléchargement par sourate ou en lot avec pause et reprise.
/// - Téléchargement à la demande de 6 polices coraniques OFL supplémentaires via `FontLoader`.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int? _selectedReciterId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    final int activeReciterId = _selectedReciterId ?? prefs.defaultReciterId;
    final ReciterOption activeReciter = AudioPlaybackState.availableReciters
        .firstWhere(
          (ReciterOption r) => r.id == activeReciterId,
          orElse: () => AudioPlaybackState.defaultRecitersFirst,
        );

    final double usedMb = notifier.totalDownloadedBytes / (1024 * 1024);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloads),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentSoftGold,
          tabs: const <Widget>[
            Tab(text: 'Audio'),
            Tab(text: 'Polices'),
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
                _buildAudioTab(activeReciter, tasks, notifier),
                _buildFontsTab(prefs),
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
    ReciterOption activeReciter,
    Map<String, SurahDownloadTask> tasks,
    DownloadManagerNotifier notifier,
  ) {
    final List<MapEntry<String, SurahDownloadTask>> entries = tasks.entries
        .where(
          (MapEntry<String, SurahDownloadTask> e) =>
              e.value.reciterId == activeReciter.id,
        )
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          color: AppColors.secondaryLightGreen.withOpacity(0.45),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Choisir le récitateur à télécharger :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDeepGreen,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: activeReciter.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: AudioPlaybackState.availableReciters
                      .map(
                        (ReciterOption r) => DropdownMenuItem<int>(
                          value: r.id,
                          child: Text(
                            r.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (int? newId) {
                    if (newId == null) return;
                    setState(() => _selectedReciterId = newId);
                    ref
                        .read(appPreferencesProvider.notifier)
                        .setDefaultReciterId(newId);
                    final ReciterOption chosen = AudioPlaybackState
                        .availableReciters
                        .firstWhere((ReciterOption r) => r.id == newId);
                    ref
                        .read(audioControllerProvider.notifier)
                        .setReciter(chosen);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Style : ${activeReciter.style}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        for (final MapEntry<String, SurahDownloadTask> e
                            in entries) {
                          notifier.startOrResumeDownload(e.key);
                        }
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Tout télécharger'),
                    ),
                  ],
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
                      Expanded(
                        child: Text(
                          '${task.surahId}. ${task.surahName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 12),
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

  Widget _buildFontsTab(AppPreferencesState prefs) {
    final Map<ArabicFontFamily, FontDownloadItemState> fontStates =
        ref.watch(fontDownloadProvider);
    final FontDownloadNotifier fontNotifier =
        ref.read(fontDownloadProvider.notifier);
    final AppPreferencesNotifier prefsNotifier =
        ref.read(appPreferencesProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Polices coraniques et arabes (SIL Open Font License 1.1)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDeepGreen,
            ),
          ),
        ),
        ...ArabicFontFamily.values.map((ArabicFontFamily font) {
          final FontDownloadItemState item = fontStates[font] ??
              FontDownloadItemState(
                font: font,
                status: font.isBuiltIn
                    ? FontInstallStatus.builtIn
                    : FontInstallStatus.notInstalled,
              );
          final bool isSelected = prefs.arabicFont == font;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              font.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${font.styleDescription} · ~${font.estimatedSizeKb} Ko',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.status == FontInstallStatus.downloading)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: item.progress,
                            strokeWidth: 3,
                            color: AppColors.primaryDeepGreen,
                          ),
                        )
                      else if (item.isReady)
                        isSelected
                            ? const Chip(
                                avatar: Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppColors.primaryDeepGreen,
                                ),
                                label: Text('Active'),
                              )
                            : FilledButton.tonal(
                                onPressed: () =>
                                    prefsNotifier.setArabicFont(font),
                                child: const Text('Activer'),
                              )
                      else
                        OutlinedButton.icon(
                          onPressed: () async {
                            final bool ok =
                                await fontNotifier.downloadAndLoadFont(font);
                            if (ok) {
                              prefsNotifier.setArabicFont(font);
                            }
                          },
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('Télécharger'),
                        ),
                    ],
                  ),
                  if (item.isReady) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLightGreen.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ArabicNormalizer.basmalaUthmani,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: font.fontFamily,
                          fontSize: 22,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                  if (item.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      item.errorMessage!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 12),
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
            leading:
                Icon(Icons.check_circle, color: AppColors.primaryDeepGreen),
            title: Text('Français — Muhammad Hamidullah'),
            subtitle: Text('Inclus hors ligne dans quran.db (Tanzil.net)'),
            trailing: Text('Installé ✓'),
          ),
        ),
        Card(
          child: ListTile(
            leading:
                Icon(Icons.check_circle, color: AppColors.primaryDeepGreen),
            title: Text('Anglais / Translittération phonétique'),
            subtitle: Text('Inclus hors ligne dans quran.db (Tanzil.net)'),
            trailing: Text('Installé ✓'),
          ),
        ),
      ],
    );
  }
}
