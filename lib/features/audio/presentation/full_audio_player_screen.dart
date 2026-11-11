import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../downloads/data/download_manager_service.dart';
import '../data/quran_audio_handler.dart';

/// E09 — Lecteur audio plein écran :
/// - Sourate en cours, choix parmi 12 récitateurs (dont Abdullah Al-Matrood, Mishary Al-Afasy, etc.).
/// - Téléchargement direct de la sourate en cours pour le récitateur choisi.
/// - Barre de progression temporelle + boutons `⏮ ⏪ ⏯ ⏩ ⏭`.
/// - Options : `🔁 Répéter`, `⏲ Minuteur`, `Vitesse (0.75× à 1.5×)`.
class FullAudioPlayerScreen extends ConsumerWidget {
  const FullAudioPlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}:" : ""}$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioPlaybackState state = ref.watch(audioControllerProvider);
    final AudioController controller =
        ref.read(audioControllerProvider.notifier);
    final Map<String, SurahDownloadTask> downloads =
        ref.watch(downloadManagerProvider);
    final String currentTaskKey = DownloadManagerNotifier.taskKey(
      state.reciter.id,
      state.currentSurahId,
    );
    final SurahDownloadTask? currentDownload = downloads[currentTaskKey];
    final bool isDownloaded =
        state.isOfflineFile || currentDownload?.status == DownloadItemStatus.done;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => context.pop(),
        ),
        title: const Text('En lecture'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            tooltip: 'Téléchargements hors ligne (E17)',
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () => context.push(AppRoutes.downloads),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // En-tête sourate & récitateur
            Column(
              children: <Widget>[
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentSoftGold,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book,
                        size: 52,
                        color: AppColors.accentSoftGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sourate ${state.currentSurahName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      _showReciterPicker(context, ref, state, controller),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLightGreen.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.record_voice_over_outlined,
                          size: 18,
                          color: AppColors.primaryDeepGreen,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            state.reciter.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.primaryDeepGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primaryDeepGreen,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (isDownloaded)
                  const Chip(
                    avatar: Icon(
                      Icons.offline_pin,
                      size: 18,
                      color: AppColors.primaryDeepGreen,
                    ),
                    label: Text('Téléchargé — Lecture 100 % hors ligne'),
                  )
                else if (currentDownload?.status == DownloadItemStatus.running)
                  Column(
                    children: <Widget>[
                      SizedBox(
                        width: 220,
                        child: LinearProgressIndicator(
                          value: currentDownload!.progress,
                          color: AppColors.primaryDeepGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Téléchargement en cours (${(currentDownload.progress * 100).round()}%)…',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(downloadManagerProvider.notifier)
                          .downloadSurahForReciter(
                            reciter: state.reciter,
                            surahId: state.currentSurahId,
                            surahName: state.currentSurahName,
                          );
                    },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Télécharger cette sourate hors ligne'),
                  ),
              ],
            ),

            if (state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.downloads),
                      icon: const Icon(Icons.download),
                      label: const Text('Ouvrir les téléchargements'),
                    ),
                  ],
                ),
              ),

            // Barre de progression et contrôles principaux
            Column(
              children: <Widget>[
                Slider(
                  value: state.progressFraction,
                  activeColor: AppColors.primaryDeepGreen,
                  onChanged: (double v) {
                    final int targetMs =
                        (state.duration.inMilliseconds * v).round();
                    controller.seekTo(Duration(milliseconds: targetMs));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(_formatDuration(state.position)),
                      Text(_formatDuration(state.duration)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      iconSize: 32,
                      tooltip: 'Sourate précédente',
                      icon: const Icon(Icons.skip_previous),
                      onPressed: controller.previousSurah,
                    ),
                    IconButton(
                      iconSize: 32,
                      tooltip: 'Reculer de 10 s',
                      icon: const Icon(Icons.replay_10),
                      onPressed: () => controller.skipBySeconds(-10),
                    ),
                    IconButton(
                      iconSize: 64,
                      color: AppColors.primaryDeepGreen,
                      icon: Icon(
                        state.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      onPressed: controller.togglePlayPause,
                    ),
                    IconButton(
                      iconSize: 32,
                      tooltip: 'Avancer de 10 s',
                      icon: const Icon(Icons.forward_10),
                      onPressed: () => controller.skipBySeconds(10),
                    ),
                    IconButton(
                      iconSize: 32,
                      tooltip: 'Sourate suivante',
                      icon: const Icon(Icons.skip_next),
                      onPressed: controller.nextSurah,
                    ),
                  ],
                ),
              ],
            ),

            // Options secondaires : Répéter, Minuteur, Vitesse
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TextButton.icon(
                  onPressed: controller.cycleRepeatMode,
                  icon: const Icon(Icons.repeat),
                  label: Text(state.repeatMode.label),
                ),
                TextButton.icon(
                  onPressed: () => _showSleepTimerPicker(context, controller),
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(
                    state.sleepTimerMinutes != null
                        ? '${state.sleepTimerMinutes} min'
                        : 'Minuteur',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    const List<double> speeds = <double>[0.75, 1.0, 1.25, 1.5];
                    final int nextIdx =
                        (speeds.indexOf(state.speed) + 1) % speeds.length;
                    controller.setSpeed(speeds[nextIdx]);
                  },
                  child: Text(
                    'Vitesse ${state.speed}×',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterPicker(
    BuildContext context,
    WidgetRef ref,
    AudioPlaybackState state,
    AudioController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return SafeArea(
              child: Column(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Choisir un récitateur (12 lecteurs disponibles)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: AudioPlaybackState.availableReciters.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ReciterOption r =
                            AudioPlaybackState.availableReciters[index];
                        return RadioListTile<int>(
                          value: r.id,
                          groupValue: state.reciter.id,
                          activeColor: AppColors.primaryDeepGreen,
                          title: Text(
                            r.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(r.style),
                          onChanged: (_) {
                            controller.setReciter(r);
                            ref
                                .read(appPreferencesProvider.notifier)
                                .setDefaultReciterId(r.id);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSleepTimerPicker(
    BuildContext context,
    AudioController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <int?>[null, 15, 30, 60].map((int? mins) {
              return ListTile(
                leading: const Icon(Icons.bedtime_outlined),
                title: Text(
                  mins == null
                      ? 'Désactiver le minuteur'
                      : 'Arrêter après $mins minutes',
                ),
                onTap: () {
                  controller.setSleepTimerMinutes(mins);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
