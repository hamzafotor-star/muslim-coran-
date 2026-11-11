import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_service.dart';
import '../domain/entities/ayah.dart';
import '../domain/entities/surah.dart';

/// Dépôt de données en lecture seule pour le Coran et ses traductions (`quran.db`).
class QuranRepository {
  const QuranRepository(this._dbService);

  final DatabaseService _dbService;

  Future<List<Surah>> getAllSurahs() async {
    final Database db = await _dbService.quranDb;
    final List<Map<String, Object?>> rows = await db.query(
      'surah',
      orderBy: 'id ASC',
    );
    return rows.map(Surah.fromMap).toList(growable: false);
  }

  Future<Surah?> getSurahById(int surahId) async {
    final Database db = await _dbService.quranDb;
    final List<Map<String, Object?>> rows = await db.query(
      'surah',
      where: 'id = ?',
      whereArgs: <Object?>[surahId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Surah.fromMap(rows.first);
  }

  /// Charge les versets d'une sourate avec la traduction choisie (< 300 ms grâce à l'index).
  Future<List<Ayah>> getAyahsBySurah({
    required int surahId,
    required int translationId,
  }) async {
    final Database db = await _dbService.quranDb;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT a.*,
             t.text AS translation_text,
             s.name_translit AS surah_name_translit,
             s.name_ar AS surah_name_ar
      FROM ayah a
      INNER JOIN surah s ON s.id = a.surah_id
      LEFT JOIN ayah_translation t
        ON t.ayah_id = a.id AND t.translation_id = ?
      WHERE a.surah_id = ?
      ORDER BY a.ayah_number ASC
      ''',
      <Object?>[translationId, surahId],
    );
    return rows.map(Ayah.fromMap).toList(growable: false);
  }

  /// Charge un verset par son identifiant global (1..6236).
  Future<Ayah?> getAyahById(int ayahId, {int translationId = 1}) async {
    final Database db = await _dbService.quranDb;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT a.*,
             t.text AS translation_text,
             s.name_translit AS surah_name_translit,
             s.name_ar AS surah_name_ar
      FROM ayah a
      INNER JOIN surah s ON s.id = a.surah_id
      LEFT JOIN ayah_translation t
        ON t.ayah_id = a.id AND t.translation_id = ?
      WHERE a.id = ?
      LIMIT 1
      ''',
      <Object?>[translationId, ayahId],
    );
    if (rows.isEmpty) return null;
    return Ayah.fromMap(rows.first);
  }

  /// Retourne le premier verset de chaque Juz' (1..30) pour l'onglet « Juz' » de E05.
  Future<List<Ayah>> getJuzStartAyahs() async {
    final Database db = await _dbService.quranDb;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT a.*,
             s.name_translit AS surah_name_translit,
             s.name_ar AS surah_name_ar
      FROM ayah a
      INNER JOIN surah s ON s.id = a.surah_id
      WHERE a.id IN (
        SELECT MIN(id) FROM ayah GROUP BY juz
      )
      ORDER BY a.juz ASC
      ''',
    );
    return rows.map(Ayah.fromMap).toList(growable: false);
  }

  /// Retourne le premier verset d'une page donnée (1..604) pour l'onglet « Pages » de E05.
  Future<Ayah?> getFirstAyahOfPage(int pageNumber) async {
    final Database db = await _dbService.quranDb;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT a.*,
             s.name_translit AS surah_name_translit,
             s.name_ar AS surah_name_ar
      FROM ayah a
      INNER JOIN surah s ON s.id = a.surah_id
      WHERE a.page_15 = ?
      ORDER BY a.id ASC
      LIMIT 1
      ''',
      <Object?>[pageNumber.clamp(1, 604)],
    );
    if (rows.isEmpty) return null;
    return Ayah.fromMap(rows.first);
  }

  /// Sélection déterministe du « Verset du jour » (E04) parmi des versets spirituels marquants.
  Future<Ayah?> getVerseOfTheDay(DateTime date, {int translationId = 1}) async {
    const List<int> curatedAyahIds = <int>[
      262, // Ayat al-Kursi (2:255)
      293, // Al-Baqara 2:286
      7, // Al-Fatiha 1:7
      1750, // Ar-Ra'd 13:28
      2822, // An-Nur 24:35
      4131, // Az-Zumar 39:53
      4914, // Ar-Rahman 55:13
      5243, // At-Talaq 65:3
      6092, // Ash-Sharh 94:5
      6222, // Al-Ikhlas 112:1
    ];
    final int dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays.abs();
    final int selectedId = curatedAyahIds[dayOfYear % curatedAyahIds.length];
    return getAyahById(selectedId, translationId: translationId);
  }
}

final Provider<QuranRepository> quranRepositoryProvider =
    Provider<QuranRepository>(
  (Ref ref) => QuranRepository(ref.watch(databaseServiceProvider)),
);

final FutureProvider<List<Surah>> surahListProvider =
    FutureProvider<List<Surah>>((Ref ref) {
  return ref.watch(quranRepositoryProvider).getAllSurahs();
});
