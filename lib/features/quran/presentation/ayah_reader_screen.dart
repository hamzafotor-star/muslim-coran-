import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fonts/font_download_service.dart';
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
import 'widgets/tajweed_text_view.dart';

/// E06 & E07 — Lecteur du Coran (Mode Verset par Verset + Mode Mushaf Tajweed continu) :
/// - En-tête : retour, nom de sourate, bascule Mode Mushaf / Versets, réglages (`Aa`), lecture audio (`▶`).
/// - Bandeau des couleurs indicatives du **Mushaf Tajweed** (Madd, Ghunnah/Ikhfâ’, Qalqalah, Iqlâb/Tafkhîm).
/// - Basmala affichée conformément à la sourate (absente pour At-Tawba, intégrée en v.1 pour Al-Fâtiha).
/// - Liste virtualisée (`ListView.builder`) ou page continue encadrée style Mushaf.
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
  late int _currentSurahId;
  Surah? _surah;
  List<Ayah> _ayahs = const <Ayah>[];
  bool _loading = true;
  int? _highlightedAyahNumber;
  int? _lastSavedAyahId;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _currentSurahId = widget.surahId.clamp(1, 114);
    _highlightedAyahNumber = widget.initialAyahNumber;
    _loadSurahAndAyahs(targetAyahNumber: widget.initialAyahNumber);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveAyahReadingPosition(Ayah ayah, {String? mode}) async {
    if (_lastSavedAyahId == ayah.id) return;
    _lastSavedAyahId = ayah.id;
    final String effectiveMode = mode ??
        (ref.read(appPreferencesProvider).isMushafPageMode ? 'mushaf' : 'ayah');
    await ref.read(bookmarkRepositoryProvider).saveReadingPosition(
          ayahId: ayah.id,
          page: ayah.page15,
          mode: effectiveMode,
        );
  }

  Future<void> _loadSurahAndAyahs({int? targetAyahNumber}) async {
    final QuranRepository repo = ref.read(quranRepositoryProvider);
    final AppPreferencesState prefs = ref.read(appPreferencesProvider);
    final int requestedSurahId = _currentSurahId;

    final Surah? surah = await repo.getSurahById(requestedSurahId);
    final List<Ayah> ayahs = await repo.getAyahsBySurah(
      surahId: requestedSurahId,
      translationId: prefs.defaultTranslationId,
    );

    if (!mounted || requestedSurahId != _currentSurahId) return;

    _ayahKeys
      ..clear()
      ..addEntries(
        ayahs.map(
          (Ayah a) => MapEntry<int, GlobalKey>(a.ayahNumber, GlobalKey()),
        ),
      );

    if (ayahs.isNotEmpty) {
      final Ayah target = targetAyahNumber != null
          ? ayahs.firstWhere(
              (Ayah a) => a.ayahNumber == targetAyahNumber,
              orElse: () => ayahs.first,
            )
          : ayahs.first;
      _lastSavedAyahId = null;
      await _saveAyahReadingPosition(
        target,
        mode: prefs.isMushafPageMode ? 'mushaf' : 'ayah',
      );
    }

    if (mounted) {
      setState(() {
        _surah = surah;
        _ayahs = ayahs;
        _loading = false;
        _highlightedAyahNumber = targetAyahNumber ?? (ayahs.isNotEmpty ? 1 : null);
      });

      if (targetAyahNumber != null && targetAyahNumber > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToAyah(targetAyahNumber);
          }
        });
      }
    }
  }

  void _goToSurah(int nextSurahId) {
    final int targetSurahId = nextSurahId.clamp(1, 114);
    if (targetSurahId == _currentSurahId) return;

    setState(() {
      _currentSurahId = targetSurahId;
      _loading = true;
      _highlightedAyahNumber = 1;
      _lastSavedAyahId = null;
      _ayahKeys.clear();
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadSurahAndAyahs(targetAyahNumber: 1);
  }

  Future<void> _scrollToAyah(int ayahNumber) async {
    if (!mounted || _ayahs.isEmpty) return;

    final GlobalKey? key = _ayahKeys[ayahNumber];
    final BuildContext? ctx = key?.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.25,
      );
      return;
    }

    if (!_scrollController.hasClients) return;
    final int idx =
        _ayahs.indexWhere((Ayah a) => a.ayahNumber == ayahNumber);
    if (idx < 0) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0 || _ayahs.length <= 1) return;

    final double ratio = idx / (_ayahs.length - 1);
    final double targetOffset = (ratio * maxScroll).clamp(0.0, maxScroll);
    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    if (!mounted) return;
    final BuildContext? refinedCtx = _ayahKeys[ayahNumber]?.currentContext;
    if (refinedCtx != null && refinedCtx.mounted) {
      await Scrollable.ensureVisible(
        refinedCtx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0.25,
      );
    }
  }

  bool _handleScrollEnd(ScrollEndNotification notification) {
    if (notification.depth != 0 || _ayahs.isEmpty || _loading) return false;

    Ayah? visibleAyah;
    final double viewportHeight = MediaQuery.of(context).size.height;
    double bestDistance = double.infinity;

    for (final Ayah ayah in _ayahs) {
      final BuildContext? ctx = _ayahKeys[ayah.ayahNumber]?.currentContext;
      if (ctx == null) continue;
      final RenderObject? renderObj = ctx.findRenderObject();
      if (renderObj is! RenderBox || !renderObj.hasSize) continue;

      final double dy = renderObj.localToGlobal(Offset.zero).dy;
      final double bottom = dy + renderObj.size.height;
      if (bottom > 90 && dy < viewportHeight * 0.75) {
        final double distance = (dy - 140).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          visibleAyah = ayah;
        }
      }
    }

    if (visibleAyah == null && notification.metrics.maxScrollExtent > 0) {
      final double fraction =
          (notification.metrics.pixels / notification.metrics.maxScrollExtent)
              .clamp(0.0, 1.0);
      final int idx =
          (fraction * (_ayahs.length - 1)).round().clamp(0, _ayahs.length - 1);
      visibleAyah = _ayahs[idx];
    }

    if (visibleAyah != null) {
      _saveAyahReadingPosition(visibleAyah);
    }
    return false;
  }

  void _openTextSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
            final AppPreferencesNotifier notifier =
                ref.read(appPreferencesProvider.notifier);
            final Map<ArabicFontFamily, FontDownloadItemState> fontStates =
                ref.watch(fontDownloadProvider);

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Réglages de lecture & Mushaf Tajweed (Aa)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Couleurs indicatives du Mushaf Tajweed',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Coloration des règles Madd, Ghunnah, Qalqalah et Iqlâb',
                      ),
                      value: prefs.tajweedColorsEnabled,
                      onChanged: notifier.setTajweedColorsEnabled,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mode Mushaf pleine page (continu)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Afficher les versets en continu dans un cadre Mushaf doré',
                      ),
                      value: prefs.isMushafPageMode,
                      onChanged: notifier.setMushafPageMode,
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    const Text(
                      'Police coranique (touchez ⬇ pour télécharger) :',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children:
                          ArabicFontFamily.values.map((ArabicFontFamily f) {
                        final FontDownloadItemState? fState = fontStates[f];
                        final bool isReady =
                            f.isBuiltIn || (fState?.isReady ?? false);
                        final bool isDownloading =
                            fState?.status == FontInstallStatus.downloading;

                        return ChoiceChip(
                          avatar: isDownloading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : (!isReady
                                  ? const Icon(Icons.download_outlined, size: 16)
                                  : null),
                          label: Text(f.displayName),
                          selected: prefs.arabicFont == f,
                          onSelected: (_) async {
                            if (isReady) {
                              notifier.setArabicFont(f);
                            } else {
                              final bool ok = await ref
                                  .read(fontDownloadProvider.notifier)
                                  .downloadAndLoadFont(f);
                              if (ok) {
                                notifier.setArabicFont(f);
                              }
                            }
                          },
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
                    if (!prefs.isMushafPageMode)
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
          surahTitle: _surah?.nameTranslit ?? 'Sourate $_currentSurahId',
          onListenAyah: () {
            setState(() => _highlightedAyahNumber = ayah.ayahNumber);
            ref.read(audioControllerProvider.notifier).playSurah(
                  surahId: _currentSurahId,
                  surahName:
                      _surah?.nameTranslit ?? 'Sourate $_currentSurahId',
                  activeAyahNumber: ayah.ayahNumber,
                  totalAyahs: _ayahs.isNotEmpty ? _ayahs.length : null,
                );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
    final AppPreferencesNotifier prefsNotifier =
        ref.read(appPreferencesProvider.notifier);
    final AudioPlaybackState audioState = ref.watch(audioControllerProvider);
    final bool showBasmalaHeader =
        ArabicNormalizer.shouldShowBasmalaHeader(_currentSurahId);

    ref.listen<AudioPlaybackState>(
      audioControllerProvider,
      (AudioPlaybackState? prev, AudioPlaybackState next) {
        if (next.currentSurahId == _currentSurahId && next.isPlaying) {
          final bool ayahChanged =
              next.currentAyahNumber != prev?.currentAyahNumber;
          final bool newlyPlayingThisSurah =
              prev?.currentSurahId != _currentSurahId ||
                  !(prev?.isPlaying ?? false);
          if (ayahChanged || newlyPlayingThisSurah) {
            setState(() {
              _highlightedAyahNumber = next.currentAyahNumber;
            });
            if (_ayahs.isNotEmpty) {
              final Ayah activeAyah = _ayahs.firstWhere(
                (Ayah a) => a.ayahNumber == next.currentAyahNumber,
                orElse: () => _ayahs.first,
              );
              _saveAyahReadingPosition(
                activeAyah,
                mode: prefs.isMushafPageMode ? 'mushaf' : 'ayah',
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _scrollToAyah(next.currentAyahNumber);
              }
            });
          }
        }
      },
    );

    final bool showLiveAudioBar =
        audioState.currentSurahId == _currentSurahId && audioState.isVisible;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _surah != null
              ? '${_surah!.nameTranslit} (${_surah!.nameAr})'
              : 'Sourate $_currentSurahId',
        ),
        actions: <Widget>[
          IconButton(
            tooltip: prefs.isMushafPageMode
                ? 'Passer en mode Verset par Verset'
                : 'Passer en mode Mushaf Tajweed pleine page',
            icon: Icon(
              prefs.isMushafPageMode
                  ? Icons.view_agenda_outlined
                  : Icons.auto_stories_outlined,
              color: prefs.isMushafPageMode ? AppColors.accentSoftGold : null,
            ),
            onPressed: () =>
                prefsNotifier.setMushafPageMode(!prefs.isMushafPageMode),
          ),
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
                    surahId: _currentSurahId,
                    surahName:
                        _surah?.nameTranslit ?? 'Sourate $_currentSurahId',
                    totalAyahs: _ayahs.isNotEmpty ? _ayahs.length : null,
                  );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                TajweedLegendBanner(
                  enabled: prefs.tajweedColorsEnabled,
                  onToggle: prefsNotifier.setTajweedColorsEnabled,
                ),
                _buildSurahNavBar(),
                if (showLiveAudioBar) _buildLiveAudioTrackingBar(audioState),
                Expanded(
                  child: NotificationListener<ScrollEndNotification>(
                    onNotification: _handleScrollEnd,
                    child: prefs.isMushafPageMode
                        ? _buildMushafContinuousPage(
                            context,
                            prefs,
                            audioState,
                            showBasmalaHeader,
                          )
                        : _buildAyahByAyahList(
                            context,
                            prefs,
                            audioState,
                            showBasmalaHeader,
                          ),
                  ),
                ),
                const MiniAudioPlayer(),
              ],
            ),
    );
  }

  Widget _buildSurahNavBar({bool isBottom = false}) {
    final bool hasPrev = _currentSurahId > 1;
    final bool hasNext = _currentSurahId < 114;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isBottom ? 0 : 12,
        vertical: isBottom ? 12 : 6,
      ),
      decoration: isBottom
          ? null
          : BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  AppColors.secondaryLightGreen.withOpacity(0.18),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryDeepGreen.withOpacity(0.14),
                ),
              ),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primaryDeepGreen,
                ),
                onPressed: hasPrev ? () => _goToSurah(_currentSurahId - 1) : null,
                child: const Text(
                  '◀ Sourate préc.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryDeepGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_currentSurahId / 114',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDeepGreen,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primaryDeepGreen,
                ),
                onPressed: hasNext ? () => _goToSurah(_currentSurahId + 1) : null,
                child: const Text(
                  'Sourate suiv. ▶',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAudioTrackingBar(AudioPlaybackState audioState) {
    final int totalAyahs =
        _ayahs.isNotEmpty ? _ayahs.length : audioState.totalAyahsInSurah;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryDeepGreen.withOpacity(0.94),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentSoftGold.withOpacity(0.8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '🔊 En lecture : Verset ${audioState.currentAyahNumber} / $totalAyahs',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentSoftGold,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              setState(
                () => _highlightedAyahNumber = audioState.currentAyahNumber,
              );
              _scrollToAyah(audioState.currentAyahNumber);
            },
            icon: const Icon(Icons.my_location, size: 15),
            label: const Text(
              'Centrer',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Mode E07 — Mushaf Tajweed pleine page (texte continu encadré d'or et d'émeraude).
  Widget _buildMushafContinuousPage(
    BuildContext context,
    AppPreferencesState prefs,
    AudioPlaybackState audioState,
    bool showBasmalaHeader,
  ) {
    final Color baseColor = Theme.of(context).colorScheme.onSurface;
    final List<InlineSpan> spans = <InlineSpan>[];

    for (final Ayah ayah in _ayahs) {
      final bool isAudioAyah = audioState.currentSurahId == _currentSurahId &&
          audioState.currentAyahNumber == ayah.ayahNumber &&
          audioState.isVisible;
      final bool isHighlighted =
          (_highlightedAyahNumber == ayah.ayahNumber) || isAudioAyah;
      final Color? highlightBg = isHighlighted
          ? AppColors.accentSoftGold.withOpacity(0.24)
          : null;

      if (prefs.tajweedColorsEnabled) {
        final List<TextSpan> ayahSpans = TajweedTextView.buildTajweedSpans(
          ayah.displayArabicText,
          defaultColor: baseColor,
        );
        if (highlightBg != null) {
          for (final TextSpan ts in ayahSpans) {
            spans.add(
              TextSpan(
                text: ts.text,
                style: (ts.style ?? const TextStyle()).copyWith(
                  backgroundColor: highlightBg,
                ),
              ),
            );
          }
        } else {
          spans.addAll(ayahSpans);
        }
      } else {
        spans.add(
          TextSpan(
            text: ayah.displayArabicText,
            style: TextStyle(
              color: baseColor,
              backgroundColor: highlightBg,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text:
              ' ﴿${ArabicNormalizer.toEasternArabicDigits(ayah.ayahNumber)}﴾ ',
          style: TextStyle(
            color: AppColors.primaryDeepGreen,
            fontWeight: FontWeight.bold,
            backgroundColor: highlightBg,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openAyahActions(ayah),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.accentSoftGold,
                width: 2.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Cartouche d'en-tête de la sourate style Mushaf
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepGreen,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.accentSoftGold, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        _surah != null ? '${_surah!.ayahCount} versets' : '',
                        style: const TextStyle(
                          color: AppColors.secondaryLightGreen,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _surah?.nameAr ?? 'سورة',
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 22,
                          color: AppColors.accentSoftGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _surah?.nameTranslit ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showBasmalaHeader) ...<Widget>[
                  const SizedBox(height: 14),
                  TajweedTextView(
                    text: ArabicNormalizer.basmalaUthmani,
                    fontFamily: prefs.arabicFont.fontFamily,
                    fontSize: prefs.arabicFontSize,
                    enableTajweedColors: prefs.tajweedColorsEnabled,
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 24),
                ] else
                  const SizedBox(height: 14),
                RichText(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: prefs.arabicFont.fontFamily,
                      fontSize: prefs.arabicFontSize,
                      height: 2.05,
                      color: baseColor,
                    ),
                    children: spans,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSurahNavBar(isBottom: true),
        ],
      ),
    );
  }

  /// Mode E06 — Lecteur verset par verset avec coloration Tajweed et traduction.
  Widget _buildAyahByAyahList(
    BuildContext context,
    AppPreferencesState prefs,
    AudioPlaybackState audioState,
    bool showBasmalaHeader,
  ) {
    final int headerOffset = showBasmalaHeader ? 1 : 0;
    final int totalItems = _ayahs.length + headerOffset + 1;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: totalItems,
      itemBuilder: (BuildContext context, int index) {
        if (showBasmalaHeader && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondaryLightGreen.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentSoftGold.withOpacity(0.5),
              ),
            ),
            child: TajweedTextView(
              text: ArabicNormalizer.basmalaUthmani,
              fontFamily: prefs.arabicFont.fontFamily,
              fontSize: prefs.arabicFontSize,
              enableTajweedColors: prefs.tajweedColorsEnabled,
              textAlign: TextAlign.center,
            ),
          );
        }

        if (index == totalItems - 1) {
          return _buildSurahNavBar(isBottom: true);
        }

        final int ayahIdx = index - headerOffset;
        final Ayah ayah = _ayahs[ayahIdx];
        final bool isAudioActive =
            audioState.currentSurahId == _currentSurahId &&
                audioState.currentAyahNumber == ayah.ayahNumber &&
                audioState.isVisible;
        final bool isHighlighted =
            (_highlightedAyahNumber == ayah.ayahNumber) || isAudioActive;
        final GlobalKey ayahKey =
            _ayahKeys.putIfAbsent(ayah.ayahNumber, GlobalKey.new);

        return Card(
          key: ayahKey,
          color: isAudioActive
              ? AppColors.accentSoftGold.withOpacity(0.12)
              : null,
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
              _saveAyahReadingPosition(ayah);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLightGreen,
                                borderRadius: BorderRadius.circular(12),
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
                            if (isAudioActive)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDeepGreen,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentSoftGold,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '🔊 En lecture : ${ayah.ayahNumber}/${_ayahs.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (ayah.hasSajda)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accentSoftGold.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(8),
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
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actions du verset (E08)',
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () => _openAyahActions(ayah),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TajweedTextView(
                    text: ayah.displayArabicText,
                    fontFamily: prefs.arabicFont.fontFamily,
                    fontSize: prefs.arabicFontSize,
                    enableTajweedColors: prefs.tajweedColorsEnabled,
                    textAlign: TextAlign.right,
                    trailingSpan: TextSpan(
                      text:
                          ' ﴿${ArabicNormalizer.toEasternArabicDigits(ayah.ayahNumber)}﴾',
                      style: const TextStyle(
                        color: AppColors.primaryDeepGreen,
                        fontWeight: FontWeight.bold,
                      ),
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
    );
  }
}
