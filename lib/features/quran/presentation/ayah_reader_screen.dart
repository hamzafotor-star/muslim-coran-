import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../audio/data/quran_audio_handler.dart';
import '../../audio/presentation/widgets/mini_audio_player.dart';
import '../../bookmarks/data/bookmark_repository.dart';
import '../data/quran_repository.dart';
import '../domain/entities/ayah.dart';
import '../domain/entities/surah.dart';
import '../domain/utils/arabic_normalizer.dart';
import 'widgets/ayah_actions_sheet.dart';

/// E06 — Lecteur du Coran, mode verset par verset :
/// - En-tête : retour, nom de sourate, bouton réglages de texte (`Aa`), menu (`⋮`).
/// - Basmala affichée conformément à la sourate (absente pour At-Tawba, intégrée en v.1 pour Al-Fâtiha).
/// - Liste virtualisée (`ListView.builder`) pour performances < 300 ms sur 2 Go de RAM.
/// - Marqueurs de Sajda (prosternation recommandée ou obligatoire).
/// - Surlignage du verset en cours pendant la lecture audio.
/// - Appui long ou icône menu : feuille d'actions E08.
class AyahReaderScreen extends ConsumerStatefulWidget {
  const AyahReaderScreen({
    super.key,
    required this.surahId,
    this.initialAyahNumber,
  });

  final int surahId;
  final int? initialAyahNumber;

  @override
  ConsumerState<AyahReaderScreen> createState() => _AyahReaderScreenState();
}

class _AyahReaderScreenState extends ConsumerState<AyahReaderScreen> {
  Surah? _surah;
  List<Ayah> _ayahs = const <Ayah>[];
  bool _loading = true;
  int? _highlightedAyahNumber;

  @override
  void initState() {
    super.initState();
    _highlightedAyahNumber = widget.initialAyahNumber;
    _loadSurahAndAyahs();
  }

  Future<void> _loadSurahAndAyahs() async {
    final QuranRepository repo = ref.read(quranRepositoryProvider);
    final int translationId =
        ref.read(appPreferencesProvider).defaultTranslationId;

    final Surah? surah = await repo.getSurahById(widget.surahId);
    final List<Ayah> ayahs = await repo.getAyahsBySurah(
      surahId: widget.surahId,
      translationId: translationId,
    );

    if (ayahs.isNotEmpty) {
      final Ayah target = widget.initialAyahNumber != null
          ? ayahs.firstWhere(
              (Ayah a) => a.ayahNumber == widget.initialAyahNumber,
              orElse: () => ayahs.first,
            )
          : ayahs.first;
      await ref.read(bookmarkRepositoryProvider).saveReadingPosition(
            ayahId: target.id,
            page: target.page15,
          );
    }

    if (mounted) {
      setState(() {
        _surah = surah;
        _ayahs = ayahs;
        _loading = false;
      });
    }
  }

  void _openTextSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
            final AppPreferencesNotifier notifier =
                ref.read(appPreferencesProvider.notifier);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Réglages de lecture (Aa)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Police arabe (Licence OFL) :'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ArabicFontFamily.values.map((ArabicFontFamily f) {
                        return ChoiceChip(
                          label: Text(f.displayName),
                          selected: prefs.arabicFont == f,
                          onSelected: (_) => notifier.setArabicFont(f),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        const Text('Taille du texte arabe :'),
                        Expanded(
                          child: Slider(
                            min: 20,
                            max: 42,
                            divisions: 11,
                            value: prefs.arabicFontSize,
                            label: '${prefs.arabicFontSize.round()} pt',
                            onChanged: notifier.setArabicFontSize,
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Afficher la traduction'),
                      value: prefs.showTranslation,
                      onChanged: notifier.setShowTranslation,
                    ),
                    const SizedBox(height: 8),
                    const Text('Thème de lecture :'),
                    const SizedBox(height: 8),
                    SegmentedButton<AppThemeMode>(
                      segments: const <ButtonSegment<AppThemeMode>>[
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.light,
                          label: Text('Clair'),
                        ),
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.dark,
                          label: Text('Sombre'),
                        ),
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.sepia,
                          label: Text('Sépia'),
                        ),
                      ],
                      selected: <AppThemeMode>{prefs.themeMode},
                      onSelectionChanged: (Set<AppThemeMode> selection) {
                        notifier.setThemeMode(selection.first);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAyahActions(Ayah ayah) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AyahActionsSheet(
          ayah: ayah,
          surahTitle: _surah?.nameTranslit ?? 'Sourate ${widget.surahId}',
          onListenAyah: () {
            setState(() => _highlightedAyahNumber = ayah.ayahNumber);
            ref.read(audioControllerProvider.notifier).playSurah(
                  surahId: widget.surahId,
                  surahName: _surah?.nameTranslit ?? 'Sourate ${widget.surahId}',
                  activeAyahNumber: ayah.ayahNumber,
                );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
    final AudioPlaybackState audioState = ref.watch(audioControllerProvider);
    final bool showBasmalaHeader =
        ArabicNormalizer.shouldShowBasmalaHeader(widget.surahId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _surah != null
              ? '${_surah!.nameTranslit} (${_surah!.nameAr})'
              : 'Sourate ${widget.surahId}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _openTextSettingsSheet,
            child: const Text(
              'Aa',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Écouter la sourate',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              ref.read(audioControllerProvider.notifier).playSurah(
                    surahId: widget.surahId,
                    surahName:
                        _surah?.nameTranslit ?? 'Sourate ${widget.surahId}',
                  );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ayahs.length + (showBasmalaHeader ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (showBasmalaHeader && index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLightGreen.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accentSoftGold.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            ArabicNormalizer.basmalaUthmani,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: prefs.arabicFont.fontFamily,
                              fontSize: prefs.arabicFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      final int ayahIdx =
                          showBasmalaHeader ? index - 1 : index;
                      final Ayah ayah = _ayahs[ayahIdx];
                      final bool isHighlighted =
                          (_highlightedAyahNumber == ayah.ayahNumber) ||
                          (audioState.currentSurahId == widget.surahId &&
                              audioState.currentAyahNumber == ayah.ayahNumber);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isHighlighted
                              ? const BorderSide(
                                  color: AppColors.accentSoftGold,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onLongPress: () => _openAyahActions(ayah),
                          onTap: () {
                            setState(
                              () => _highlightedAyahNumber = ayah.ayahNumber,
                            );
                            ref
                                .read(bookmarkRepositoryProvider)
                                .saveReadingPosition(
                                  ayahId: ayah.id,
                                  page: ayah.page15,
                                );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryLightGreen,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${ayah.surahId}:${ayah.ayahNumber} · ﴿${ArabicNormalizer.toEasternArabicDigits(ayah.ayahNumber)}﴾',
                                            style: const TextStyle(
                                              color: AppColors.primaryDeepGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (ayah.hasSajda) ...<Widget>[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentSoftGold
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              ayah.isObligatorySajda
                                                  ? '۩ Sajda obligatoire'
                                                  : '۩ Sajda',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    IconButton(
                                      tooltip: 'Actions du verset (E08)',
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      onPressed: () => _openAyahActions(ayah),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${ayah.displayArabicText} ﴿${ArabicNormalizer.toEasternArabicDigits(ayah.ayahNumber)}﴾',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: prefs.arabicFont.fontFamily,
                                    fontSize: prefs.arabicFontSize,
                                    height: 1.95,
                                  ),
                                ),
                                if (prefs.showTranslation &&
                                    ayah.translationText != null) ...<Widget>[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Text(
                                    ayah.translationText!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const MiniAudioPlayer(),
              ],
            ),
    );
  }
}
