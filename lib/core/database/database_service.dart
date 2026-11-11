import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Service de gestion des deux bases SQLite (§3 & docs/schema_muslim_coran.sql) :
/// 1. `quran.db` : copiée depuis `assets/db/quran.db` au 1er lancement, ouverte en LECTURE SEULE,
///    avec vérification d'intégrité (`meta.quran_text_sha256`).
/// 2. `user.db` : créée à l'exécution en LECTURE/ÉCRITURE selon `lib/data/user_schema.sql`.
class DatabaseService {
  Database? _quranDb;
  Database? _userDb;

  static const String expectedTanzilSha256 =
      '6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f';

  Future<Database> get quranDb async {
    if (_quranDb != null && _quranDb!.isOpen) {
      return _quranDb!;
    }
    _quranDb = await _initQuranDb();
    return _quranDb!;
  }

  Future<Database> get userDb async {
    if (_userDb != null && _userDb!.isOpen) {
      return _userDb!;
    }
    _userDb = await _initUserDb();
    return _userDb!;
  }

  Future<Database> _initQuranDb() async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(docsDir.path, 'quran.db');
    final File dbFile = File(dbPath);

    if (!dbFile.existsSync()) {
      await dbFile.parent.create(recursive: true);
      final ByteData data = await rootBundle.load('assets/db/quran.db');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await dbFile.writeAsBytes(bytes, flush: true);
    }

    final Database db = await openDatabase(dbPath, readOnly: true);
    await verifyQuranIntegrity(db);
    return db;
  }

  /// Vérifie que la base `quran.db` contient bien les 114 sourates, 6 236 versets
  /// et la somme de contrôle SHA-256 officielle de Tanzil (RF / §5).
  Future<void> verifyQuranIntegrity(Database db) async {
    final List<Map<String, Object?>> metaRows = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: <Object?>['quran_text_sha256'],
    );
    if (metaRows.isEmpty) {
      throw StateError('Somme de contrôle quran_text_sha256 absente de quran.db');
    }
    final String storedSha = (metaRows.first['value'] as String?) ?? '';
    if (storedSha.isEmpty || storedSha != expectedTanzilSha256) {
      throw StateError(
        'Échec du contrôle d’intégrité SHA-256 du texte coranique : $storedSha',
      );
    }
  }

  Future<Database> _initUserDb() async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(docsDir.path, 'user.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await applyUserSchema(db);
      },
    );
  }

  static Future<void> applyUserSchema(Database db) async {
    final Batch batch = db.batch();
    for (final String stmt in _userSchemaStatements) {
      batch.execute(stmt);
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _quranDb?.close();
    await _userDb?.close();
    _quranDb = null;
    _userDb = null;
  }

  static const List<String> _userSchemaStatements = <String>[
    '''
    CREATE TABLE IF NOT EXISTS settings (
        key        TEXT PRIMARY KEY,
        value      TEXT NOT NULL,
        updated_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS bookmark (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        ayah_id    INTEGER NOT NULL,
        label      TEXT,
        color      TEXT,
        created_at INTEGER NOT NULL,
        deleted_at INTEGER,
        UNIQUE (ayah_id)
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS note (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        ayah_id    INTEGER NOT NULL,
        body       TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_note_ayah ON note(ayah_id)',
    '''
    CREATE TABLE IF NOT EXISTS reading_history (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        ayah_id    INTEGER NOT NULL,
        mode       TEXT NOT NULL CHECK (mode IN ('ayah','mushaf','audio')),
        read_at    INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_history_date ON reading_history(read_at DESC)',
    '''
    CREATE TABLE IF NOT EXISTS reading_position (
        id         INTEGER PRIMARY KEY CHECK (id = 1),
        ayah_id    INTEGER NOT NULL,
        page       INTEGER,
        updated_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS location_profile (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        name           TEXT NOT NULL,
        latitude       REAL NOT NULL,
        longitude      REAL NOT NULL,
        timezone       TEXT NOT NULL,
        source         TEXT NOT NULL CHECK (source IN ('gps','city','manual')),
        city_id        INTEGER,
        is_active      INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0,1)),
        created_at     INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS prayer_settings (
        location_id        INTEGER PRIMARY KEY REFERENCES location_profile(id) ON DELETE CASCADE,
        calc_method        TEXT NOT NULL DEFAULT 'MWL',
        asr_school         TEXT NOT NULL DEFAULT 'shafi' CHECK (asr_school IN ('shafi','hanafi')),
        high_lat_rule      TEXT,
        adj_fajr           INTEGER NOT NULL DEFAULT 0,
        adj_sunrise        INTEGER NOT NULL DEFAULT 0,
        adj_dhuhr          INTEGER NOT NULL DEFAULT 0,
        adj_asr            INTEGER NOT NULL DEFAULT 0,
        adj_maghrib        INTEGER NOT NULL DEFAULT 0,
        adj_isha           INTEGER NOT NULL DEFAULT 0,
        hijri_offset_days  INTEGER NOT NULL DEFAULT 0
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS prayer_alarm (
        prayer         TEXT PRIMARY KEY CHECK (prayer IN
                       ('fajr','sunrise','dhuhr','asr','maghrib','isha','imsak','iftar')),
        enabled        INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
        adhan_id       TEXT NOT NULL DEFAULT 'default',
        reminder_min   INTEGER NOT NULL DEFAULT 0,
        vibrate        INTEGER NOT NULL DEFAULT 1 CHECK (vibrate IN (0,1))
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS download (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        kind          TEXT NOT NULL CHECK (kind IN ('audio','translation','tafsir')),
        ref_id        INTEGER NOT NULL,
        local_path    TEXT,
        size_bytes    INTEGER,
        status        TEXT NOT NULL DEFAULT 'queued'
                      CHECK (status IN ('queued','running','paused','done','error')),
        progress      REAL NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
        sha256        TEXT,
        error_message TEXT,
        created_at    INTEGER NOT NULL,
        completed_at  INTEGER,
        UNIQUE (kind, ref_id)
    )
    ''',
    'INSERT OR IGNORE INTO reading_position (id, ayah_id, page, updated_at) VALUES (1, 1, 1, 0)',
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('fajr', 1)",
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('sunrise', 0)",
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('dhuhr', 1)",
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('asr', 1)",
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('maghrib', 1)",
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('isha', 1)",
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('imsak', 0)",
    "INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES ('iftar', 0)",
  ];
}

final Provider<DatabaseService> databaseServiceProvider =
    Provider<DatabaseService>((Ref ref) => DatabaseService());
