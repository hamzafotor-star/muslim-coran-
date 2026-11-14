import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic_ornaments.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookmarks/data/bookmark_repository.dart';
import '../../prayer/domain/prayer_calculator_service.dart';
import '../../prayer/presentation/prayer_times_screen.dart';
import '../../quran/data/quran_repository.dart';
import '../../quran/domain/entities/ayah.dart';
import '../../quran/domain/entities/surah.dart';

/// E04 — Accueil (Tableau de bord) « Qurana » :
/// - En-tête royal émeraude & or : logo, titre **Qurana**, salutation calligraphiée,
///   carte « Prochaine prière » intégrée avec compte à rebours lumineux et
///   barre des 5 prières.
/// - Carte « Reprendre la lecture » dynamique : rechargée à chaque retour
///   d'une route (`await context.push(...)`) et à chaque reprise de l'application.
/// - Grille d'accès rapide (Sourates, Prières, Qibla, Signets, Téléchargements, Réglages).
/// - Carte « Verset du jour » dans un cadre doré de style Mushaf.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late Future<Ayah?> _readingFuture;
  late final Future<Ayah?> _verseFuture;
  DateTime _lastScheduleRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readingFuture = _loadReadingPosition();
    _verseFuture =
        ref.read(quranRepositoryProvider).getVerseOfTheDay(DateTime.now());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadReadingPosition();
    }
  }

  Future<Ayah?> _loadReadingPosition() async {
    try {
      return await ref
          .read(bookmarkRepositoryProvider)
          .getCurrentReadingPositionAyah();
    } catch (_) {
      return null;
    }
  }

  /// Recharge immédiatement la dernière sourate / le dernier verset lus.
  void _reloadReadingPosition() {
    if (!mounted) return;
    setState(() {
      _readingFuture = _loadReadingPosition();
    });
  }

  /// Ouvre une route empilée puis rafraîchit la carte « Reprendre la lecture »
  /// dès le retour, sans aucune action supplémentaire de l'utilisateur.
  Future<void> _openRoute(String location) async {
    await context.push(location);
    if (!mounted) return;
    _reloadReadingPosition();
  }

  /// Recalcule le planning lorsque l'heure de la prochaine prière est passée.
  void _onPrayerReached() {
    final DateTime now = DateTime.now();
    if (now.difference(_lastScheduleRefresh).inSeconds < 60) return;
    _lastScheduleRefresh = now;
    ref.invalidate(currentPrayerScheduleProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DailyPrayerSchedule schedule =
        ref.watch(currentPrayerScheduleProvider);
    final List<Surah> surahs =
        ref.watch(surahListProvider).valueOrNull ?? const <Surah>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          color: AppColors.accentSoftGold,
          onRefresh: () async {
            _reloadReadingPosition();
            await _readingFuture;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _RoyalHero(
                  l10n: l10n,
                  schedule: schedule,
                  onOpenSearch: () => _openRoute(AppRoutes.search),
                  onOpenAudio: () => _openRoute(AppRoutes.fullAudioPlayer),
                  onOpenSettings: () => _openRoute(AppRoutes.settings),
                  onOpenPrayers: () => context.go(AppRoutes.prayers),
                  onPrayerReached: _onPrayerReached,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    // 2. Carte « Reprendre la lecture »
                    FutureBuilder<Ayah?>(
                      future: _readingFuture,
                      builder: (BuildContext context,
                          AsyncSnapshot<Ayah?> snap) {
                        final Ayah? pos = snap.data;
                        Surah? surah;
                        final int surahId = pos?.surahId ?? 1;
                        for (final Surah s in surahs) {
                          if (s.id == surahId) {
                            surah = s;
                            break;
                          }
                        }
                        return _ResumeReadingCard(
                          l10n: l10n,
                          position: pos,
                          surah: surah,
                          isLoading: snap.connectionState ==
                                  ConnectionState.waiting &&
                              !snap.hasData,
                          onContinue: () => _openRoute(
                            AppRoutes.ayahReaderPath(
                              surahId,
                              initialAyah: pos?.ayahNumber ?? 1,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),

                    // 3. Grille d'accès rapide
                    OrnateSectionTitle(title: l10n.quickAccess),
                    _QuickAccessGrid(
                      items: <_QuickAccessItem>[
                        _QuickAccessItem(
                          icon: Icons.menu_book_rounded,
                          label: l10n.surahs,
                          onTap: () => context.go(AppRoutes.quranList),
                        ),
                        _QuickAccessItem(
                          icon: Icons.schedule_rounded,
                          label: l10n.tabPrayers,
                          onTap: () => context.go(AppRoutes.prayers),
                        ),
                        _QuickAccessItem(
                          icon: Icons.explore_rounded,
                          label: l10n.tabQibla,
                          onTap: () => context.go(AppRoutes.qibla),
                        ),
                        _QuickAccessItem(
                          icon: Icons.bookmark_rounded,
                          label: l10n.tabBookmarks,
                          onTap: () => context.go(AppRoutes.bookmarks),
                        ),
                        _QuickAccessItem(
                          icon: Icons.download_for_offline_rounded,
                          label: l10n.downloads,
                          onTap: () => _openRoute(AppRoutes.downloads),
                        ),
                        _QuickAccessItem(
                          icon: Icons.settings_rounded,
                          label: l10n.settings,
                          onTap: () => _openRoute(AppRoutes.settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // 4. Carte « Verset du jour »
                    FutureBuilder<Ayah?>(
                      future: _verseFuture,
                      builder: (BuildContext context,
                          AsyncSnapshot<Ayah?> snap) {
                        final Ayah? v = snap.data;
                        if (v == null) {
                          return const SizedBox.shrink();
                        }
                        return _VerseOfTheDayCard(
                          l10n: l10n,
                          verse: v,
                          onOpen: () => _openRoute(
                            AppRoutes.ayahReaderPath(
                              v.surahId,
                              initialAyah: v.ayahNumber,
                            ),
                          ),
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// En-tête royal
// =============================================================================

class _RoyalHero extends StatelessWidget {
  const _RoyalHero({
    required this.l10n,
    required this.schedule,
    required this.onOpenSearch,
    required this.onOpenAudio,
    required this.onOpenSettings,
    required this.onOpenPrayers,
    required this.onPrayerReached,
  });

  final AppLocalizations l10n;
  final DailyPrayerSchedule schedule;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAudio;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenPrayers;
  final VoidCallback onPrayerReached;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;

    return RoyalPatternBackground(
      showGoldEdge: false,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(32)),
          border: Border(
            bottom: BorderSide(
              color: AppColors.accentSoftGold.withOpacity(0.8),
              width: 1.4,
            ),
          ),
          gradient: RadialGradient(
            center: const Alignment(0.9, -1.0),
            radius: 1.1,
            colors: <Color>[
              AppColors.goldLight.withOpacity(0.16),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Ligne marque + actions
            Row(
              children: <Widget>[
                const GoldLogoMedallion(size: 44, glow: false),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ShaderMask(
                        shaderCallback: (Rect bounds) =>
                            AppColors.goldGradient.createShader(bounds),
                        child: const Text(
                          'Qurana',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Text(
                        l10n.appTagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeroIconButton(
                  icon: Icons.search_rounded,
                  tooltip: 'Rechercher',
                  onTap: onOpenSearch,
                ),
                _HeroIconButton(
                  icon: Icons.headphones_rounded,
                  tooltip: 'Lecteur audio',
                  onTap: onOpenAudio,
                ),
                _HeroIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: l10n.settings,
                  onTap: onOpenSettings,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Salutation calligraphiée
            const Text(
              'السَّلَامُ عَلَيْكُمْ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 30,
                height: 1.7,
                color: AppColors.goldLight,
                shadows: <Shadow>[
                  Shadow(color: Colors.black38, blurRadius: 8),
                ],
              ),
            ),
            Text(
              l10n.greeting,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.place_rounded,
                  size: 14,
                  color: AppColors.goldLight.withOpacity(0.9),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${schedule.locationName} · ${schedule.formattedDate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Carte « Prochaine prière » intégrée
            _NextPrayerPanel(
              l10n: l10n,
              schedule: schedule,
              onTap: onOpenPrayers,
              onPrayerReached: onPrayerReached,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Material(
        color: Colors.white.withOpacity(0.10),
        shape: CircleBorder(
          side: BorderSide(color: AppColors.goldLight.withOpacity(0.45)),
        ),
        child: IconButton(
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          icon: Icon(icon, color: AppColors.goldLight),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _NextPrayerPanel extends StatelessWidget {
  const _NextPrayerPanel({
    required this.l10n,
    required this.schedule,
    required this.onTap,
    required this.onPrayerReached,
  });

  final AppLocalizations l10n;
  final DailyPrayerSchedule schedule;
  final VoidCallback onTap;
  final VoidCallback onPrayerReached;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, DateTime>> fivePrayers =
        <MapEntry<String, DateTime>>[
      MapEntry<String, DateTime>('Fajr', schedule.fajr),
      MapEntry<String, DateTime>('Dhuhr', schedule.dhuhr),
      MapEntry<String, DateTime>('Asr', schedule.asr),
      MapEntry<String, DateTime>('Maghrib', schedule.maghrib),
      MapEntry<String, DateTime>('Isha', schedule.isha),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: AppColors.goldLight.withOpacity(0.55),
              width: 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.nextPrayer.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.secondaryLightGreen
                                .withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schedule.nextPrayerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          schedule.nextPrayerFormattedTime,
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LiveCountdown(
                    target: schedule.nextPrayerTime,
                    onReached: onPrayerReached,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.goldLight.withOpacity(0),
                      AppColors.goldLight.withOpacity(0.6),
                      AppColors.goldLight.withOpacity(0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: fivePrayers.map((MapEntry<String, DateTime> p) {
                  final bool isNext = p.key == schedule.nextPrayerName;
                  final bool isPast = !isNext &&
                      p.value.isBefore(schedule.nextPrayerTime) &&
                      p.value.isBefore(DateTime.now());
                  return Expanded(
                    child: _PrayerPill(
                      name: p.key,
                      time: DailyPrayerSchedule.formatHm(p.value),
                      isNext: isNext,
                      isPast: isPast,
                    ),
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerPill extends StatelessWidget {
  const _PrayerPill({
    required this.name,
    required this.time,
    required this.isNext,
    required this.isPast,
  });

  final String name;
  final String time;
  final bool isNext;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isNext
        ? AppColors.emeraldNight
        : Colors.white.withOpacity(isPast ? 0.5 : 0.92);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isNext ? AppColors.goldGradient : null,
        boxShadow: isNext ? AppColors.goldGlow(opacity: 0.4) : null,
      ),
      child: Column(
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compte à rebours lumineux mis à jour chaque seconde, sans reconstruire
/// tout l'écran d'accueil.
class _LiveCountdown extends StatefulWidget {
  const _LiveCountdown({required this.target, required this.onReached});

  final DateTime target;
  final VoidCallback onReached;

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _compute());
    });
  }

  @override
  void didUpdateWidget(covariant _LiveCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _remaining = _compute();
    }
  }

  /// Calcule le temps restant ; si l'heure est atteinte, demande (après la
  /// frame courante) le recalcul du planning des prières.
  Duration _compute() {
    final Duration diff = widget.target.difference(DateTime.now());
    if (diff.isNegative) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReached();
      });
      return Duration.zero;
    }
    return diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final int h = _remaining.inHours.clamp(0, 99);
    final int m = _remaining.inMinutes % 60;
    final int s = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.emeraldNight.withOpacity(0.55),
        border: Border.all(color: AppColors.goldLight.withOpacity(0.8)),
        boxShadow: AppColors.goldGlow(opacity: 0.30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${_two(h)}:${_two(m)}:${_two(s)}',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              shadows: <Shadow>[
                Shadow(color: AppColors.goldLight, blurRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'h · min · s',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Carte « Reprendre la lecture »
// =============================================================================

class _ResumeReadingCard extends StatelessWidget {
  const _ResumeReadingCard({
    required this.l10n,
    required this.position,
    required this.surah,
    required this.isLoading,
    required this.onContinue,
  });

  final AppLocalizations l10n;
  final Ayah? position;
  final Surah? surah;
  final bool isLoading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final Color accent =
        isDark ? AppColors.goldLight : AppColors.primaryDeepGreen;

    final bool hasPosition = position != null;
    final int surahId = position?.surahId ?? 1;
    final int ayahNum = position?.ayahNumber ?? 1;
    final String translit =
        position?.surahNameTranslit ?? surah?.nameTranslit ?? 'Al-Fâtiha';
    final String nameAr = position?.surahNameAr ?? surah?.nameAr ?? 'الفاتحة';
    final int? total = surah?.ayahCount;
    final double progress =
        total != null && total > 0 ? (ayahNum / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.goldGradient,
        boxShadow: AppColors.softShadow(opacity: isDark ? 0.45 : 0.14),
      ),
      padding: const EdgeInsets.all(1.6),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(22.4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onContinue,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: GeometricPatternPainter(
                    color: AppColors.accentSoftGold,
                    opacity: isDark ? 0.05 : 0.07,
                    tileSize: 50,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDeepGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.auto_stories_rounded,
                                size: 14,
                                color: AppColors.goldLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.resumeReading,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        IslamicStarBadge(
                          label: '$surahId',
                          size: 58,
                          highlighted: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                translit,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasPosition
                                    ? 'Verset $ayahNum${total != null ? ' / $total' : ''} · Sourate $surahId'
                                    : 'Commencez votre lecture du Saint Coran',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nameAr,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 26,
                            height: 1.6,
                            color: isDark
                                ? AppColors.goldLight
                                : AppColors.goldDeep,
                          ),
                        ),
                      ],
                    ),
                    if (total != null) ...<Widget>[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: AppColors.accentSoftGold,
                          backgroundColor:
                              AppColors.accentSoftGold.withOpacity(0.15),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).round()} % de la sourate',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: AppColors.goldLight.withOpacity(0.7),
                            ),
                          ),
                        ),
                        onPressed: onContinue,
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.goldLight,
                        ),
                        label: Text(
                          hasPosition
                              ? '${l10n.continueBtn} · $translit $surahId:$ayahNum'
                              : l10n.openQuran,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Grille d'accès rapide
// =============================================================================

class _QuickAccessItem {
  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.items});

  final List<_QuickAccessItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.98,
      children: items.map((_QuickAccessItem item) {
        return Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            onTap: item.onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentSoftGold.withOpacity(0.35),
                ),
                boxShadow: AppColors.softShadow(opacity: isDark ? 0.3 : 0.06),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.royalEmeraldGradient,
                        border: Border.all(
                          color: AppColors.goldLight.withOpacity(0.8),
                          width: 1.2,
                        ),
                        boxShadow: AppColors.softShadow(opacity: 0.2),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.goldLight,
                        size: 23,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

// =============================================================================
// Carte « Verset du jour »
// =============================================================================

class _VerseOfTheDayCard extends ConsumerWidget {
  const _VerseOfTheDayCard({
    required this.l10n,
    required this.verse,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final Ayah verse;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent =
        isDark ? AppColors.goldLight : AppColors.primaryDeepGreen;
    final String surahTitle =
        verse.surahNameTranslit ?? 'Sourate ${verse.surahId}';

    return MushafFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: OrnamentDivider(starSize: 9)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  l10n.verseOfTheDay.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: accent,
                  ),
                ),
              ),
              const Expanded(child: OrnamentDivider(starSize: 9)),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpen,
            child: Text(
              verse.displayArabicText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24,
                height: 2.0,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          if (verse.translationText != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              '« ${verse.translationText!} »',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '— $surahTitle (${verse.surahId}:${verse.ayahNumber})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.goldLight : AppColors.goldDeep,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Partager ce verset',
                icon: Icon(Icons.share_outlined, size: 20, color: accent),
                onPressed: () {
                  Share.share(verse.formatForShare(surahTitle: surahTitle));
                },
              ),
              IconButton(
                tooltip: 'Ajouter aux signets',
                icon: Icon(Icons.favorite_border, size: 20, color: accent),
                onPressed: () async {
                  await ref.read(bookmarkRepositoryProvider).upsertBookmark(
                        ayahId: verse.id,
                        label:
                            '$surahTitle ${verse.surahId}:${verse.ayahNumber}',
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
    );
  }
}
