import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/quran_audio_handler.dart';

/// E09 — Mini-lecteur audio (barre du bas) :
/// `Al-Baqara · Al-Afasy` + barre de progression + `⏮ ⏯ ⏭`.
class MiniAudioPlayer extends ConsumerWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioPlaybackState state = ref.watch(audioControllerProvider);
    if (!state.isVisible) {
      return const SizedBox.shrink();
    }

    final AudioController controller =
        ref.read(audioControllerProvider.notifier);

    return Material(
      elevation: 4,
      color: AppColors.primaryDeepGreen,
      child: InkWell(
        onTap: () => context.push(AppRoutes.fullAudioPlayer),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LinearProgressIndicator(
              value: state.progressFraction,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentSoftGold,
              ),
              minHeight: 3,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.graphic_eq,
                    color: AppColors.accentSoftGold,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${state.currentSurahName} · v.${state.currentAyahNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          state.reciter.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryLightGreen,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: controller.previousSurah,
                  ),
                  IconButton(
                    icon: Icon(
                      state.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: AppColors.accentSoftGold,
                      size: 30,
                    ),
                    onPressed: controller.togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: controller.nextSurah,
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
