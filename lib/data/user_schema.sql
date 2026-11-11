-- ============================================================
-- Muslim Coran — Schéma SQLite utilisateur : user.db (LECTURE / ÉCRITURE)
-- Extrait de docs/schema_muslim_coran.sql (PARTIE B)
-- ============================================================

PRAGMA foreign_keys = ON;

-- Réglages (clé / valeur)
CREATE TABLE IF NOT EXISTS settings (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Signets
CREATE TABLE IF NOT EXISTS bookmark (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    ayah_id    INTEGER NOT NULL,
    label      TEXT,
    color      TEXT,
    created_at INTEGER NOT NULL,
    deleted_at INTEGER,
    UNIQUE (ayah_id)
);

-- Notes personnelles
CREATE TABLE IF NOT EXISTS note (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    ayah_id    INTEGER NOT NULL,
    body       TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_note_ayah ON note(ayah_id);

-- Historique de lecture (dernières positions)
CREATE TABLE IF NOT EXISTS reading_history (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    ayah_id    INTEGER NOT NULL,
    mode       TEXT NOT NULL CHECK (mode IN ('ayah','mushaf','audio')),
    read_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_history_date ON reading_history(read_at DESC);

-- Position courante (une seule ligne : « Reprendre la lecture »)
CREATE TABLE IF NOT EXISTS reading_position (
    id         INTEGER PRIMARY KEY CHECK (id = 1),
    ayah_id    INTEGER NOT NULL,
    page       INTEGER,
    updated_at INTEGER NOT NULL
);

-- Lieu choisi pour les horaires
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
);

-- Réglages des prières (une ligne par lieu)
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
);

-- Notifications / Adhan par prière
CREATE TABLE IF NOT EXISTS prayer_alarm (
    prayer         TEXT PRIMARY KEY CHECK (prayer IN
                   ('fajr','sunrise','dhuhr','asr','maghrib','isha','imsak','iftar')),
    enabled        INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
    adhan_id       TEXT NOT NULL DEFAULT 'default',
    reminder_min   INTEGER NOT NULL DEFAULT 0,
    vibrate        INTEGER NOT NULL DEFAULT 1 CHECK (vibrate IN (0,1))
);

-- Téléchargements (audio, traductions, tafsir)
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
);

-- Objectifs de lecture / Khatma (V1.x)
CREATE TABLE IF NOT EXISTS reading_plan (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT NOT NULL,
    total_days     INTEGER NOT NULL CHECK (total_days > 0),
    start_date     TEXT NOT NULL,
    pages_per_day  REAL NOT NULL,
    is_active      INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    completed_at   INTEGER
);

CREATE TABLE IF NOT EXISTS reading_plan_day (
    plan_id     INTEGER NOT NULL REFERENCES reading_plan(id) ON DELETE CASCADE,
    day_number  INTEGER NOT NULL,
    start_page  INTEGER NOT NULL,
    end_page    INTEGER NOT NULL,
    done_at     INTEGER,
    PRIMARY KEY (plan_id, day_number)
);

-- Mémorisation (Hifz) — révision espacée (V1.x)
CREATE TABLE IF NOT EXISTS memorization_item (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    surah_id      INTEGER NOT NULL,
    from_ayah     INTEGER NOT NULL,
    to_ayah       INTEGER NOT NULL,
    status        TEXT NOT NULL DEFAULT 'learning'
                  CHECK (status IN ('learning','memorized','review')),
    ease_factor   REAL NOT NULL DEFAULT 2.5,
    interval_days INTEGER NOT NULL DEFAULT 0,
    next_review   TEXT,
    created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_memo_next ON memorization_item(next_review);

CREATE TABLE IF NOT EXISTS memorization_review (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id     INTEGER NOT NULL REFERENCES memorization_item(id) ON DELETE CASCADE,
    reviewed_at INTEGER NOT NULL,
    quality     INTEGER NOT NULL CHECK (quality BETWEEN 0 AND 5)
);

-- Compteur de dhikr / Tasbih (V1.x)
CREATE TABLE IF NOT EXISTS tasbih_counter (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    label       TEXT NOT NULL,
    target      INTEGER NOT NULL DEFAULT 33,
    count       INTEGER NOT NULL DEFAULT 0,
    updated_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS tasbih_log (
    day         TEXT NOT NULL,
    counter_id  INTEGER NOT NULL REFERENCES tasbih_counter(id) ON DELETE CASCADE,
    total       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (day, counter_id)
);

-- Compte et synchronisation (optionnel, V1.x)
CREATE TABLE IF NOT EXISTS sync_state (
    entity        TEXT PRIMARY KEY,
    last_sync_at  INTEGER,
    cursor        TEXT
);

-- Valeurs par défaut au premier lancement
INSERT OR IGNORE INTO reading_position (id, ayah_id, page, updated_at) VALUES (1, 1, 1, 0);

INSERT OR IGNORE INTO prayer_alarm (prayer) VALUES
    ('fajr'), ('dhuhr'), ('asr'), ('maghrib'), ('isha');
INSERT OR IGNORE INTO prayer_alarm (prayer, enabled) VALUES
    ('sunrise', 0), ('imsak', 0), ('iftar', 0);
