import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookmarks/data/bookmark_repository.dart';
import '../../prayer/domain/prayer_calculator_service.dart';
import '../../prayer/presentation/prayer_times_screen.dart';
import '../../quran/data/quran_repository.dart';
import '../../quran/domain/entities/ayah.dart';

/// E04 — Accueil (Tableau de bord) :
/// - Salutation « Assalamu alaykum » + bouton Réglages (⚙).
/// - Carte « Prochaine prière » avec décompte en direct.
/// - Carte « Reprendre la lecture » avec bouton `[ Continuer ▶ ]`.
/// - Carte « Verset du jour » avec partage (↗) et ajout aux signets (♡).
/// - Raccourcis : `[Qibla] [Dhikr (Bientôt)] [Audio]`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DailyPrayerSchedule schedule = ref.watch(currentPrayerScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.greeting,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              '${schedule.locationName} · ${schedule.formattedDate}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // 1. Carte « Prochaine prière »
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  AppColors.primaryDeepGreen,
                  Color(0xFF166943),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => context.go(AppRoutes.prayers),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.nextPrayer,
                    style: const TextStyle(
                      color: AppColors.secondaryLightGreen,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        schedule.nextPrayerName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        schedule.nextPrayerFormattedTime,
                        style: const TextStyle(
                          color: AppColors.accentSoftGold,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.inTime(schedule.countdownText),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Carte « Reprendre la lecture »
          FutureBuilder<Ayah?>(
            future: ref
                .read(bookmarkRepositoryProvider)
                .getCurrentReadingPositionAyah(),
            builder: (BuildContext context, AsyncSnapshot<Ayah?> snap) {
              final Ayah? pos = snap.data;
              final String surahName = pos?.surahNameTranslit ?? 'Al-Fâtiha';
              final int surahId = pos?.surahId ?? 1;
              final int ayahNum = pos?.ayahNumber ?? 1;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.resumeReading,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$surahName · v.$ayahNum'),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.ayahReaderPath(
                            surahId,
                            initialAyah: ayahNum,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(l10n.continueBtn),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 3. Carte « Verset du jour »
          FutureBuilder<Ayah?>(
            future: ref
                .read(quranRepositoryProvider)
                .getVerseOfTheDay(DateTime.now()),
            builder: (BuildContext context, AsyncSnapshot<Ayah?> snap) {
              final Ayah? v = snap.data;
              if (v == null) {
                return const SizedBox.shrink();
              }
              final String surahTitle =
                  v.surahNameTranslit ?? 'Sourate ${v.surahId}';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            l10n.verseOfTheDay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDeepGreen,
                            ),
                          ),
                          Text(
                            '$surahTitle (${v.surahId}:${v.ayahNumber})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        v.displayArabicText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 22,
                          height: 1.85,
                        ),
                      ),
                      if (v.translationText != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          v.translationText!,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          IconButton(
                            tooltip: 'Partager ce verset',
                            icon: const Icon(Icons.share_outlined, size: 20),
                            onPressed: () {
                              Share.share(
                                v.formatForShare(surahTitle: surahTitle),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Ajouter aux signets',
                            icon: const Icon(Icons.favorite_border, size: 20),
                            onPressed: () async {
                              await ref
                                  .read(bookmarkRepositoryProvider)
                                  .upsertBookmark(
                                    ayahId: v.id,
                                    label: '$surahTitle ${v.surahId}:${v.ayahNumber}',
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Verset du jour ajouté aux signets.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 4. Raccourcis : [Qibla] [Dhikr (V1.x)] [Audio]
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.qibla),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Qibla'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Module Dhikr / Tasbih prévu en version V1.x (Bientôt).'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.toll_outlined),
                  label: const Text('Dhikr'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.fullAudioPlayer),
                  icon: const Icon(Icons.headphones_outlined),
                  label: const Text('Audio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
