import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../quran/domain/entities/ayah.dart';
import '../../quran/domain/utils/arabic_normalizer.dart';

enum SearchScope {
  arabic,
  translation,
}

@immutable
class SearchResultItem {
  const SearchResultItem({
    required this.ayah,
    required this.matchedSnippet,
    required this.scope,
  });

  final Ayah ayah;
  final String matchedSnippet;
  final SearchScope scope;
}

/// Dépôt de recherche plein texte FTS5 (M7 / E10) :
/// - Recherche arabe avec ou sans voyelles via `ArabicNormalizer` et `ayah_fts`
/// - Recherche dans les traductions via `translation_fts`
/// - Persistance de l'historique des dernières recherches dans `user.db.settings`.
class SearchRepository {
  const SearchRepository(this._dbService);

  final DatabaseService _dbService;
  static const String _historySettingsKey = 'recent_search_queries';

  Future<List<SearchResultItem>> search({
    required String query,
    required SearchScope scope,
    int translationId = 1,
    int limit = 60,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return const <SearchResultItem>[];

    final Database db = await _dbService.quranDb;
    await _saveQueryToHistory(trimmed);

    if (scope == SearchScope.arabic) {
      final String normalized = ArabicNormalizer.normalizeForSearch(trimmed);
      if (normalized.isEmpty) return const <SearchResultItem>[];
      final String safeMatch = _buildSafeFtsQuery(normalized);

      final List<Map<String, Object?>> rows = await db.rawQuery(
        '''
        SELECT a.*,
               t.text AS translation_text,
               s.name_translit AS surah_name_translit,
               s.name_ar AS surah_name_ar
        FROM ayah_fts f
        INNER JOIN ayah a ON a.id = f.rowid
        INNER JOIN surah s ON s.id = a.surah_id
        LEFT JOIN ayah_translation t
          ON t.ayah_id = a.id AND t.translation_id = ?
        WHERE ayah_fts MATCH ?
        ORDER BY a.id ASC
        LIMIT ?
        ''',
        <Object?>[translationId, safeMatch, limit],
      );

      return rows
          .map(
            (Map<String, Object?> row) => SearchResultItem(
              ayah: Ayah.fromMap(row),
              matchedSnippet: (row['text_uthmani'] as String?) ?? '',
              scope: SearchScope.arabic,
            ),
          )
          .toList(growable: false);
    } else {
      final String safeMatch = _buildSafeFtsQuery(trimmed);
      final List<Map<String, Object?>> rows = await db.rawQuery(
        '''
        SELECT a.*,
               t.text AS translation_text,
               s.name_translit AS surah_name_translit,
               s.name_ar AS surah_name_ar
        FROM translation_fts f
        INNER JOIN ayah a ON a.id = CAST(f.ayah_id AS INTEGER)
        INNER JOIN surah s ON s.id = a.surah_id
        INNER JOIN ayah_translation t
          ON t.ayah_id = a.id AND t.translation_id = CAST(f.translation_id AS INTEGER)
        WHERE translation_fts MATCH ? AND CAST(f.translation_id AS INTEGER) = ?
        ORDER BY a.id ASC
        LIMIT ?
        ''',
        <Object?>[safeMatch, translationId, limit],
      );

      return rows
          .map(
            (Map<String, Object?> row) => SearchResultItem(
              ayah: Ayah.fromMap(row),
              matchedSnippet: (row['translation_text'] as String?) ?? '',
              scope: SearchScope.translation,
            ),
          )
          .toList(growable: false);
    }
  }

  String _buildSafeFtsQuery(String input) {
    final List<String> tokens = input
        .replaceAll(RegExp(r'["\*\(\)\-\:\^]'), ' ')
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return '""';
    return tokens.map((String t) => '"$t"*').join(' ');
  }

  Future<List<String>> getRecentSearches() async {
    final Database userDb = await _dbService.userDb;
    final List<Map<String, Object?>> rows = await userDb.query(
      'settings',
      where: 'key = ?',
      whereArgs: <Object?>[_historySettingsKey],
      limit: 1,
    );
    if (rows.isEmpty) return const <String>[];
    try {
      final List<dynamic> decoded =
          jsonDecode((rows.first['value'] as String?) ?? '[]') as List<dynamic>;
      return decoded.map((dynamic e) => e.toString()).toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> clearRecentSearches() async {
    final Database userDb = await _dbService.userDb;
    await userDb.delete(
      'settings',
      where: 'key = ?',
      whereArgs: <Object?>[_historySettingsKey],
    );
  }

  Future<void> _saveQueryToHistory(String query) async {
    final List<String> current = List<String>.from(await getRecentSearches());
    current.remove(query);
    current.insert(0, query);
    if (current.length > 10) {
      current.removeRange(10, current.length);
    }
    final Database userDb = await _dbService.userDb;
    await userDb.insert(
      'settings',
      <String, Object?>{
        'key': _historySettingsKey,
        'value': jsonEncode(current),
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

final Provider<SearchRepository> searchRepositoryProvider =
    Provider<SearchRepository>(
  (Ref ref) => SearchRepository(ref.watch(databaseServiceProvider)),
);
