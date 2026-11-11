import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../quran/data/quran_repository.dart';
import '../../quran/domain/entities/ayah.dart';
import '../domain/entities/bookmark_item.dart';

/// Dépôt de données pour les signets, les notes personnelles et la position
/// de lecture dans `user.db` (M8 / E14).
class BookmarkRepository {
  const BookmarkRepository(this._dbService, this._quranRepo);

  final DatabaseService _dbService;
  final QuranRepository _quranRepo;

  int get _nowSeconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Ajoute ou met à jour un signet (un par verset, `UNIQUE(ayah_id)`).
  Future<void> upsertBookmark({
    required int ayahId,
    String? label,
    String? color,
  }) async {
    final Database db = await _dbService.userDb;
    await db.insert(
      'bookmark',
      <String, Object?>{
        'ayah_id': ayahId,
        'label': label,
        'color': color,
        'created_at': _nowSeconds,
        'deleted_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Suppression logique d'un signet (`deleted_at`).
  Future<void> removeBookmarkByAyahId(int ayahId) async {
    final Database db = await _dbService.userDb;
    await db.update(
      'bookmark',
      <String, Object?>{'deleted_at': _nowSeconds},
      where: 'ayah_id = ?',
      whereArgs: <Object?>[ayahId],
    );
  }

  Future<bool> isBookmarked(int ayahId) async {
    final Database db = await _dbService.userDb;
    final List<Map<String, Object?>> rows = await db.query(
      'bookmark',
      where: 'ayah_id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[ayahId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<BookmarkItem>> getAllBookmarks() async {
    final Database db = await _dbService.userDb;
    final List<Map<String, Object?>> rows = await db.query(
      'bookmark',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    final List<BookmarkItem> items = <BookmarkItem>[];
    for (final Map<String, Object?> row in rows) {
      final int ayahId = (row['ayah_id'] as num).toInt();
      final Ayah? ayah = await _quranRepo.getAyahById(ayahId);
      items.add(
        BookmarkItem(
          id: (row['id'] as num).toInt(),
          ayahId: ayahId,
          label: row['label'] as String?,
          color: row['color'] as String?,
          createdAt: (row['created_at'] as num).toInt(),
          ayah: ayah,
        ),
      );
    }
    return items;
  }

  Future<void> saveNote({
    required int ayahId,
    required String body,
  }) async {
    final Database db = await _dbService.userDb;
    final int now = _nowSeconds;
    final List<Map<String, Object?>> existing = await db.query(
      'note',
      where: 'ayah_id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[ayahId],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('note', <String, Object?>{
        'ayah_id': ayahId,
        'body': body.trim(),
        'created_at': now,
        'updated_at': now,
        'deleted_at': null,
      });
    } else {
      await db.update(
        'note',
        <String, Object?>{
          'body': body.trim(),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: <Object?>[existing.first['id']],
      );
    }
  }

  Future<void> deleteNote(int noteId) async {
    final Database db = await _dbService.userDb;
    await db.update(
      'note',
      <String, Object?>{'deleted_at': _nowSeconds},
      where: 'id = ?',
      whereArgs: <Object?>[noteId],
    );
  }

  Future<List<NoteItem>> getAllNotes() async {
    final Database db = await _dbService.userDb;
    final List<Map<String, Object?>> rows = await db.query(
      'note',
      where: 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    final List<NoteItem> notes = <NoteItem>[];
    for (final Map<String, Object?> row in rows) {
      final int ayahId = (row['ayah_id'] as num).toInt();
      final Ayah? ayah = await _quranRepo.getAyahById(ayahId);
      notes.add(
        NoteItem(
          id: (row['id'] as num).toInt(),
          ayahId: ayahId,
          body: (row['body'] as String?) ?? '',
          createdAt: (row['created_at'] as num).toInt(),
          updatedAt: (row['updated_at'] as num).toInt(),
          ayah: ayah,
        ),
      );
    }
    return notes;
  }

  /// Met à jour la position courante « Reprendre la lecture » (E04) et ajoute à l'historique.
  Future<void> saveReadingPosition({
    required int ayahId,
    int? page,
    String mode = 'ayah',
  }) async {
    final Database db = await _dbService.userDb;
    final int now = _nowSeconds;
    await db.insert(
      'reading_position',
      <String, Object?>{
        'id': 1,
        'ayah_id': ayahId,
        'page': page ?? 1,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert('reading_history', <String, Object?>{
      'ayah_id': ayahId,
      'mode': mode,
      'read_at': now,
    });
  }

  Future<Ayah?> getCurrentReadingPositionAyah() async {
    final Database db = await _dbService.userDb;
    final List<Map<String, Object?>> rows = await db.query(
      'reading_position',
      where: 'id = 1',
      limit: 1,
    );
    final int ayahId =
        rows.isNotEmpty ? (rows.first['ayah_id'] as num).toInt() : 1;
    return _quranRepo.getAyahById(ayahId);
  }

  Future<List<ReadingHistoryItem>> getRecentHistory({int limit = 25}) async {
    final Database db = await _dbService.userDb;
    final List<Map<String, Object?>> rows = await db.query(
      'reading_history',
      orderBy: 'read_at DESC',
      limit: limit,
    );
    final List<ReadingHistoryItem> items = <ReadingHistoryItem>[];
    for (final Map<String, Object?> row in rows) {
      final int ayahId = (row['ayah_id'] as num).toInt();
      final Ayah? ayah = await _quranRepo.getAyahById(ayahId);
      items.add(
        ReadingHistoryItem(
          id: (row['id'] as num).toInt(),
          ayahId: ayahId,
          mode: (row['mode'] as String?) ?? 'ayah',
          readAt: (row['read_at'] as num).toInt(),
          ayah: ayah,
        ),
      );
    }
    return items;
  }
}

final Provider<BookmarkRepository> bookmarkRepositoryProvider =
    Provider<BookmarkRepository>(
  (Ref ref) => BookmarkRepository(
    ref.watch(databaseServiceProvider),
    ref.watch(quranRepositoryProvider),
  ),
);
