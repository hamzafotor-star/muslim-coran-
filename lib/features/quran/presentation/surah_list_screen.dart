import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookmarks/data/bookmark_repository.dart';
import '../data/quran_repository.dart';
import '../domain/entities/ayah.dart';
import '../domain/entities/surah.dart';

/// E05 — Liste des sourates / Juz' (30) / Pages (604).
class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _quickFilter = '';

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
    final AsyncValue<List<Surah>> surahsAsync = ref.watch(surahListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tabQuran,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentSoftGold,
          labelColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildSurahsTab(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Surah>> surahsAsync,
  ) {
    return FutureBuilder<Ayah?>(
      future: ref.read(bookmarkRepositoryProvider).getCurrentReadingPositionAyah(),
      builder: (BuildContext context, AsyncSnapshot<Ayah?> posSnap) {
        final int? activeSurahId = posSnap.data?.surahId;

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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Filtrer par numéro ou nom de sourate…',
                      prefixIcon: const Icon(Icons.filter_list, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (String value) {
                      setState(() => _quickFilter = value.trim());
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final Surah surah = filtered[index];
                      final bool isReading = surah.id == activeSurahId;
                      final String revLabel =
                          surah.isMeccan ? l10n.meccan : l10n.medinan;

                      return Card(
                        child: ListTile(
                          onTap: () => context.push(
                            AppRoutes.ayahReaderPath(surah.id),
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isReading
                                  ? AppColors.accentSoftGold
                                  : AppColors.secondaryLightGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${surah.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDeepGreen,
                              ),
                            ),
                          ),
                          title: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  surah.nameTranslit,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isReading)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSoftGold.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'En cours',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Text(
                                surah.nameAr,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '$revLabel · ${l10n.versesCount(surah.ayahCount)} · ${surah.nameFr}',
                          ),
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
      future: ref.read(quranRepositoryProvider).getJuzStartAyahs(),
      builder: (BuildContext context, AsyncSnapshot<List<Ayah>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<Ayah> juzStarts = snapshot.data ?? const <Ayah>[];
        return ListView.builder(
          itemCount: juzStarts.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext context, int index) {
            final Ayah startAyah = juzStarts[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryLightGreen,
                  foregroundColor: AppColors.primaryDeepGreen,
                  child: Text('${startAyah.juz}'),
                ),
                title: Text(
                  "Juz' ${startAyah.juz}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Début : ${startAyah.surahNameTranslit ?? "Sourate ${startAyah.surahId}"} · v.${startAyah.ayahNumber}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  AppRoutes.ayahReaderPath(
                    startAyah.surahId,
                    initialAyah: startAyah.ayahNumber,
                  ),
                ),
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
      padding: const EdgeInsets.all(16),
      itemBuilder: (BuildContext context, int index) {
        final int pageNumber = index + 1;
        final int estimatedJuz = ((pageNumber - 1) ~/ 20 + 1).clamp(1, 30);
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: AppColors.primaryDeepGreen,
            ),
            title: Text(
              'Page $pageNumber',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("Juz' $estimatedJuz · Mushaf 604 pages"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final Ayah? first = await ref
                  .read(quranRepositoryProvider)
                  .getFirstAyahOfPage(pageNumber);
              if (first != null && context.mounted) {
                await context.push(
                  AppRoutes.ayahReaderPath(
                    first.surahId,
                    initialAyah: first.ayahNumber,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
