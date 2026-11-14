import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic_ornaments.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookmarks/data/bookmark_repository.dart';
import '../data/quran_repository.dart';
import '../domain/entities/ayah.dart';
import '../domain/entities/surah.dart';

/// E05 — Liste des sourates / Juz' (30) / Pages (604).
/// Design « Qurana » : barre de recherche stylisée, médaillons en étoile
/// islamique à 8 branches pour les numéros, calligraphie arabe mise en valeur
/// et badges Mecquoise / Médinoise distingués.
class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _quickFilter = '';
  late Future<Ayah?> _readingFuture;
  late final Future<List<Ayah>> _juzFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _readingFuture = _loadReadingPosition();
    _juzFuture = ref.read(quranRepositoryProvider).getJuzStartAyahs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  /// Ouvre le lecteur puis rafraîchit la sourate « En cours » au retour.
  Future<void> _openReader(int surahId, {int? initialAyah}) async {
    await context.push(
      AppRoutes.ayahReaderPath(surahId, initialAyah: initialAyah),
    );
    if (!mounted) return;
    setState(() {
      _readingFuture = _loadReadingPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Surah>> surahsAsync = ref.watch(surahListProvider);

    return Scaffold(
      appBar: buildRoyalAppBar(
        title: l10n.tabQuran,
        subtitle: "114 ${l10n.surahs.toLowerCase()} · 30 Juz' · 604 pages",
        actions: <Widget>[
          IconButton(
            tooltip: 'Tableau de bord (Accueil)',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => context.go(AppRoutes.home),
          ),
          IconButton(
            tooltip: 'Rechercher (E10)',
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
        bottom: buildRoyalTabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: l10n.surahs),
            Tab(text: l10n.juz),
            Tab(text: l10n.pages),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildSurahsTab(context, l10n, surahsAsync),
          _buildJuzTab(context),
          _buildPagesTab(context),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow(opacity: isDark ? 0.35 : 0.08),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Filtrer par numéro ou nom de sourate…',
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: _quickFilter.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _quickFilter = '');
                  },
                ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.accentSoftGold.withOpacity(0.45),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.accentSoftGold.withOpacity(0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.accentSoftGold,
              width: 1.6,
            ),
          ),
        ),
        onChanged: (String value) {
          setState(() => _quickFilter = value.trim());
        },
      ),
    );
  }

  Widget _buildSurahsTab(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Surah>> surahsAsync,
  ) {
    return FutureBuilder<Ayah?>(
      future: _readingFuture,
      builder: (BuildContext context, AsyncSnapshot<Ayah?> posSnap) {
        final int? activeSurahId = posSnap.data?.surahId;
        final int? activeAyah = posSnap.data?.ayahNumber;

        return surahsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object err, StackTrace st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erreur de chargement des sourates : $err'),
            ),
          ),
          data: (List<Surah> surahs) {
            final List<Surah> filtered = _quickFilter.isEmpty
                ? surahs
                : surahs.where((Surah s) {
                    final String q = _quickFilter.toLowerCase();
                    return s.id.toString() == q ||
                        s.nameTranslit.toLowerCase().contains(q) ||
                        s.nameFr.toLowerCase().contains(q) ||
                        s.nameAr.contains(_quickFilter);
                  }).toList(growable: false);

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: _buildSearchField(context),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Aucune sourate ne correspond à « $_quickFilter ».',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemBuilder: (BuildContext context, int index) {
                            final Surah surah = filtered[index];
                            final bool isReading = surah.id == activeSurahId;
                            return _SurahCard(
                              surah: surah,
                              l10n: l10n,
                              isReading: isReading,
                              readingAyah: isReading ? activeAyah : null,
                              onTap: () => _openReader(
                                surah.id,
                                initialAyah: isReading ? activeAyah : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildJuzTab(BuildContext context) {
    return FutureBuilder<List<Ayah>>(
      future: _juzFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Ayah>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<Ayah> juzStarts = snapshot.data ?? const <Ayah>[];
        return ListView.builder(
          itemCount: juzStarts.length,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          itemBuilder: (BuildContext context, int index) {
            final Ayah startAyah = juzStarts[index];
            return _OrnateListCard(
              leading: IslamicStarBadge(label: '${startAyah.juz}', size: 46),
              title: "Juz' ${startAyah.juz}",
              subtitle:
                  'Début : ${startAyah.surahNameTranslit ?? "Sourate ${startAyah.surahId}"} · v.${startAyah.ayahNumber}',
              trailingArabic: startAyah.surahNameAr,
              onTap: () => _openReader(
                startAyah.surahId,
                initialAyah: startAyah.ayahNumber,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPagesTab(BuildContext context) {
    return ListView.builder(
      itemCount: 604,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemBuilder: (BuildContext context, int index) {
        final int pageNumber = index + 1;
        final int estimatedJuz = ((pageNumber - 1) ~/ 20 + 1).clamp(1, 30);
        return _OrnateListCard(
          leading: IslamicStarBadge(label: '$pageNumber', size: 46),
          title: 'Page $pageNumber',
          subtitle: "Juz' $estimatedJuz · Mushaf 604 pages",
          onTap: () async {
            final Ayah? first = await ref
                .read(quranRepositoryProvider)
                .getFirstAyahOfPage(pageNumber);
            if (first != null && mounted) {
              await _openReader(
                first.surahId,
                initialAyah: first.ayahNumber,
              );
            }
          },
        );
      },
    );
  }
}

/// Carte de sourate : médaillon étoilé, translittération, badge de révélation,
/// nombre de versets et calligraphie arabe.
class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required this.surah,
    required this.l10n,
    required this.isReading,
    required this.readingAyah,
    required this.onTap,
  });

  final Surah surah;
  final AppLocalizations l10n;
  final bool isReading;
  final int? readingAyah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final Color titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isReading
                    ? AppColors.accentSoftGold
                    : AppColors.accentSoftGold.withOpacity(0.25),
                width: isReading ? 1.6 : 0.9,
              ),
              gradient: isReading
                  ? LinearGradient(
                      colors: <Color>[
                        AppColors.accentSoftGold.withOpacity(0.12),
                        cardColor,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: <Widget>[
                  IslamicStarBadge(
                    label: '${surah.id}',
                    size: 50,
                    highlighted: isReading,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                surah.nameTranslit,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            if (isReading) ...<Widget>[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  readingAyah != null
                                      ? 'En cours · v.$readingAyah'
                                      : 'En cours',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.emeraldNight,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: <Widget>[
                            _RevelationBadge(
                              isMeccan: surah.isMeccan,
                              label:
                                  surah.isMeccan ? l10n.meccan : l10n.medinan,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${l10n.versesCount(surah.ayahCount)} · ${surah.nameFr}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    surah.nameAr,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 24,
                      height: 1.6,
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.primaryDeepGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge Mecquoise (or) / Médinoise (émeraude).
class _RevelationBadge extends StatelessWidget {
  const _RevelationBadge({required this.isMeccan, required this.label});

  final bool isMeccan;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base =
        isMeccan ? AppColors.accentSoftGold : AppColors.emeraldRoyal;
    final Color textColor = isMeccan
        ? (isDark ? AppColors.goldLight : AppColors.goldDeep)
        : (isDark ? AppColors.emeraldGlow : AppColors.primaryDeepGreen);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: base.withOpacity(isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: base.withOpacity(0.55), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Transform.rotate(
            angle: 0.785398,
            child: Container(width: 5, height: 5, color: textColor),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte générique ornée (Juz', Pages).
class _OrnateListCard extends StatelessWidget {
  const _OrnateListCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingArabic,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String? trailingArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: <Widget>[
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingArabic != null && trailingArabic!.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  trailingArabic!,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 20,
                    height: 1.6,
                    color: isDark
                        ? AppColors.goldLight
                        : AppColors.primaryDeepGreen,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accentSoftGold.withOpacity(0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
