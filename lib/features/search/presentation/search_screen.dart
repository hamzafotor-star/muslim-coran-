import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../quran/domain/utils/arabic_normalizer.dart';
import '../data/search_repository.dart';

/// E10 — Recherche plein texte (FTS5) :
/// - Recherche en arabe (avec ou sans voyelles grâce à `ArabicNormalizer`) ou dans la traduction.
/// - Mot recherché mis en évidence (`TextSpan`).
/// - Historique des dernières recherches quand le champ est vide.
/// - Toucher un résultat : ouverture directe du verset dans le lecteur E06.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  SearchScope _scope = SearchScope.translation;
  List<SearchResultItem> _results = const <SearchResultItem>[];
  List<String> _recentQueries = const <String>[];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final List<String> recent =
        await ref.read(searchRepositoryProvider).getRecentSearches();
    if (mounted) {
      setState(() => _recentQueries = recent);
    }
  }

  Future<void> _performSearch(String rawQuery) async {
    final String query = rawQuery.trim();
    if (query.isEmpty) {
      await _loadHistory();
      if (mounted) {
        setState(() {
          _results = const <SearchResultItem>[];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);
    final int translationId =
        ref.read(appPreferencesProvider).defaultTranslationId;
    final List<SearchResultItem> hits =
        await ref.read(searchRepositoryProvider).search(
              query: query,
              scope: _scope,
              translationId: translationId,
            );
    final List<String> recent =
        await ref.read(searchRepositoryProvider).getRecentSearches();

    if (mounted) {
      setState(() {
        _results = hits;
        _recentQueries = recent;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String currentQuery = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            suffixIcon: currentQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
          onSubmitted: _performSearch,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: <Widget>[
                ChoiceChip(
                  label: Text(l10n.arabic),
                  selected: _scope == SearchScope.arabic,
                  onSelected: (_) {
                    setState(() => _scope = SearchScope.arabic);
                    _performSearch(_controller.text);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.french),
                  selected: _scope == SearchScope.translation,
                  onSelected: (_) {
                    setState(() => _scope = SearchScope.translation);
                    _performSearch(_controller.text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : currentQuery.isEmpty
              ? _buildRecentHistory()
              : _buildResultsList(currentQuery),
    );
  }

  Widget _buildRecentHistory() {
    if (_recentQueries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Saisissez un mot en français (ex. « patience », « miséricorde ») '
            'ou en arabe avec ou sans voyelles (ex. « الحمد », « الرحمن »).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Dernières recherches',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(searchRepositoryProvider).clearRecentSearches();
                await _loadHistory();
              },
              child: const Text('Effacer'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentQueries.map(
          (String q) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(q),
            onTap: () {
              _controller.text = q;
              _performSearch(q);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(String query) {
    if (_results.isEmpty) {
      return Center(
        child: Text('Aucun résultat trouvé pour « $query ».'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Résultats (${_results.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _results.length,
            itemBuilder: (BuildContext context, int index) {
              final SearchResultItem item = _results[index];
              final String surahLabel =
                  item.ayah.surahNameTranslit ?? 'Sourate ${item.ayah.surahId}';
              return Card(
                child: ListTile(
                  title: Text(
                    '$surahLabel ${item.ayah.surahId}:${item.ayah.ayahNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDeepGreen,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildHighlightedText(
                      item.matchedSnippet,
                      query,
                      isArabic: item.scope == SearchScope.arabic,
                    ),
                  ),
                  onTap: () => context.push(
                    AppRoutes.ayahReaderPath(
                      item.ayah.surahId,
                      initialAyah: item.ayah.ayahNumber,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query, {
    required bool isArabic,
  }) {
    final String cleanQuery = isArabic
        ? ArabicNormalizer.normalizeForSearch(query)
        : query.toLowerCase();

    if (cleanQuery.isEmpty) {
      return Text(
        text,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      );
    }

    final String lowerText = text.toLowerCase();
    final int matchIndex = lowerText.indexOf(cleanQuery);
    if (matchIndex == -1) {
      return Text(
        text,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
          fontFamily: isArabic ? 'AmiriQuran' : null,
          fontSize: isArabic ? 20 : 14,
        ),
      );
    }

    final String before = text.substring(0, matchIndex);
    final String match =
        text.substring(matchIndex, matchIndex + cleanQuery.length);
    final String after = text.substring(matchIndex + cleanQuery.length);

    return RichText(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(
              fontFamily: isArabic ? 'AmiriQuran' : null,
              fontSize: isArabic ? 20 : 14,
            ),
        children: <TextSpan>[
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(
              backgroundColor: AppColors.accentSoftGold,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
