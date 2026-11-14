import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/quran_audio_handler.dart';

/// E09 — Mini-lecteur audio flottant (barre du bas) :
/// Protégé des boutons système par `SafeArea(top: false, bottom: true)`.
/// Affiche `Sourate X · Verset Y`, récitateur, barre de progression et contrôles.
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
    final String surahTitle = state.currentSurahName.startsWith('Sourate')
        ? state.currentSurahName
        : 'Sourate ${state.currentSurahName}';

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F5132),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.accentSoftGold.withOpacity(0.75),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.transparent,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                                  '$surahTitle · Verset ${state.currentAyahNumber}',
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
                                    color: AppColors.accentSoftGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: state.isPlaying ? 'Pause' : 'Lire',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
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
                            tooltip: 'Sourate suivante',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: controller.nextSurah,
                          ),
                          IconButton(
                            tooltip: 'Fermer le lecteur',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 19,
                            ),
                            onPressed: controller.closePlayer,
                          ),
                        ],
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
