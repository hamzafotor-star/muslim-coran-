import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/quran_audio_handler.dart';

/// E09 — Lecteur audio plein écran :
/// - Sourate en cours, récitateur sélectionnable (Mishary Al-Afasy, Mahmoud Al-Husary).
/// - Barre de progression temporelle + boutons `⏮ ⏪ ⏯ ⏩ ⏭`.
/// - Options : `🔁 Répéter`, `⏲ Minuteur`, `Vitesse (0.75× à 1.5×)`.
/// - Si l'audio n'est pas téléchargé et hors connexion : message clair + bouton vers Téléchargements (E17).
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
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.menu_book,
                    size: 56,
                    color: AppColors.accentSoftGold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sourate ${state.currentSurahName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showReciterPicker(context, state, controller),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          state.reciter.name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.primaryDeepGreen,
                            fontWeight: FontWeight.w600,
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
                const SizedBox(height: 8),
                Chip(
                  avatar: Icon(
                    state.isOfflineFile
                        ? Icons.offline_pin
                        : Icons.cloud_queue,
                    size: 18,
                    color: AppColors.primaryDeepGreen,
                  ),
                  label: Text(
                    state.isOfflineFile
                        ? 'Lecture hors ligne'
                        : 'Streaming (Téléchargeable dans E17)',
                  ),
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
    AudioPlaybackState state,
    AudioController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AudioPlaybackState.availableReciters
                .map((ReciterOption r) {
              return RadioListTile<int>(
                value: r.id,
                groupValue: state.reciter.id,
                title: Text(r.name),
                subtitle: Text('Style : ${r.style}'),
                onChanged: (_) {
                  controller.setReciter(r);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
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
