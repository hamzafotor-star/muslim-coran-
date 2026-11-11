-- ============================================================
-- Muslim Coran — Schéma SQLite de contenu : quran.db (LECTURE SEULE)
-- Extrait de docs/schema_muslim_coran.sql (PARTIE A)
-- ============================================================

PRAGMA foreign_keys = ON;

-- Version et intégrité du contenu
CREATE TABLE IF NOT EXISTS meta (
    key     TEXT PRIMARY KEY,
    value   TEXT NOT NULL
);

-- Sourates (114)
CREATE TABLE IF NOT EXISTS surah (
    id               INTEGER PRIMARY KEY CHECK (id BETWEEN 1 AND 114),
    name_ar          TEXT NOT NULL,
    name_translit    TEXT NOT NULL,
    name_fr          TEXT,
    name_en          TEXT,
    revelation_type  TEXT NOT NULL CHECK (revelation_type IN ('meccan','medinan')),
    revelation_order INTEGER,
    ayah_count       INTEGER NOT NULL CHECK (ayah_count > 0),
    has_bismillah    INTEGER NOT NULL DEFAULT 1 CHECK (has_bismillah IN (0,1))
);

-- Versets (6 236)
CREATE TABLE IF NOT EXISTS ayah (
    id               INTEGER PRIMARY KEY,
    surah_id         INTEGER NOT NULL REFERENCES surah(id),
    ayah_number      INTEGER NOT NULL CHECK (ayah_number > 0),
    text_uthmani     TEXT NOT NULL,
    text_simple      TEXT NOT NULL,
    juz              INTEGER NOT NULL CHECK (juz BETWEEN 1 AND 30),
    hizb_quarter     INTEGER NOT NULL CHECK (hizb_quarter BETWEEN 1 AND 240),
    manzil           INTEGER CHECK (manzil BETWEEN 1 AND 7),
    ruku             INTEGER,
    page_15          INTEGER,
    sajda_type       TEXT CHECK (sajda_type IN ('recommended','obligatory')),
    UNIQUE (surah_id, ayah_number)
);
CREATE INDEX IF NOT EXISTS idx_ayah_juz   ON ayah(juz);
CREATE INDEX IF NOT EXISTS idx_ayah_page  ON ayah(page_15);
CREATE INDEX IF NOT EXISTS idx_ayah_hizb  ON ayah(hizb_quarter);

-- Mots du verset (option V1.x)
CREATE TABLE IF NOT EXISTS word (
    id           INTEGER PRIMARY KEY,
    ayah_id      INTEGER NOT NULL REFERENCES ayah(id),
    position     INTEGER NOT NULL,
    text_ar      TEXT NOT NULL,
    translit     TEXT,
    translation  TEXT,
    UNIQUE (ayah_id, position)
);

-- Mise en page du mushaf (mode page, option V1.x)
CREATE TABLE IF NOT EXISTS mushaf_line (
    page          INTEGER NOT NULL,
    line_number   INTEGER NOT NULL,
    line_type     TEXT NOT NULL CHECK (line_type IN ('ayah','surah_name','bismillah')),
    first_word_id INTEGER REFERENCES word(id),
    last_word_id  INTEGER REFERENCES word(id),
    surah_id      INTEGER REFERENCES surah(id),
    PRIMARY KEY (page, line_number)
);

-- Traductions
CREATE TABLE IF NOT EXISTS translation (
    id           INTEGER PRIMARY KEY,
    lang         TEXT NOT NULL,
    name         TEXT NOT NULL,
    translator   TEXT,
    source_url   TEXT,
    license      TEXT NOT NULL,
    is_default   INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0,1)),
    UNIQUE (lang, name)
);

CREATE TABLE IF NOT EXISTS ayah_translation (
    ayah_id        INTEGER NOT NULL REFERENCES ayah(id),
    translation_id INTEGER NOT NULL REFERENCES translation(id),
    text           TEXT NOT NULL,
    PRIMARY KEY (ayah_id, translation_id)
);

-- Tafsir (V1.x)
CREATE TABLE IF NOT EXISTS tafsir (
    id         INTEGER PRIMARY KEY,
    lang       TEXT NOT NULL,
    name       TEXT NOT NULL,
    author     TEXT,
    source_url TEXT,
    license    TEXT NOT NULL,
    UNIQUE (lang, name)
);

CREATE TABLE IF NOT EXISTS ayah_tafsir (
    ayah_id   INTEGER NOT NULL REFERENCES ayah(id),
    tafsir_id INTEGER NOT NULL REFERENCES tafsir(id),
    text      TEXT NOT NULL,
    PRIMARY KEY (ayah_id, tafsir_id)
);

-- Récitateurs et fichiers audio
CREATE TABLE IF NOT EXISTS reciter (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    style       TEXT,
    base_url    TEXT NOT NULL,
    license     TEXT NOT NULL,
    is_default  INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0,1))
);

CREATE TABLE IF NOT EXISTS audio_file (
    id          INTEGER PRIMARY KEY,
    reciter_id  INTEGER NOT NULL REFERENCES reciter(id),
    surah_id    INTEGER NOT NULL REFERENCES surah(id),
    ayah_id     INTEGER REFERENCES ayah(id),
    url         TEXT NOT NULL,
    size_bytes  INTEGER,
    duration_ms INTEGER,
    UNIQUE (reciter_id, surah_id, ayah_id)
);
CREATE INDEX IF NOT EXISTS idx_audio_reciter_surah ON audio_file(reciter_id, surah_id);

-- Repères temporels audio
CREATE TABLE IF NOT EXISTS audio_timing (
    audio_file_id INTEGER NOT NULL REFERENCES audio_file(id),
    ayah_id       INTEGER NOT NULL REFERENCES ayah(id),
    start_ms      INTEGER NOT NULL,
    end_ms        INTEGER NOT NULL,
    PRIMARY KEY (audio_file_id, ayah_id)
);

-- Recherche plein texte (FTS5) — arabe sans voyelles + traductions
CREATE VIRTUAL TABLE IF NOT EXISTS ayah_fts USING fts5(
    text_simple,
    content='ayah',
    content_rowid='id',
    tokenize='unicode61 remove_diacritics 2'
);

CREATE VIRTUAL TABLE IF NOT EXISTS translation_fts USING fts5(
    text,
    translation_id UNINDEXED,
    ayah_id UNINDEXED,
    tokenize='unicode61 remove_diacritics 2'
);

-- Villes (GeoNames)
CREATE TABLE IF NOT EXISTS city (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    name_ascii  TEXT NOT NULL,
    country     TEXT NOT NULL,
    admin1      TEXT,
    latitude    REAL NOT NULL CHECK (latitude  BETWEEN -90  AND 90),
    longitude   REAL NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    timezone    TEXT NOT NULL,
    population  INTEGER
);
CREATE INDEX IF NOT EXISTS idx_city_name    ON city(name_ascii);
CREATE INDEX IF NOT EXISTS idx_city_country ON city(country);

-- Invocations / Dhikr (V1.x)
CREATE TABLE IF NOT EXISTS dhikr_category (
    id         INTEGER PRIMARY KEY,
    name_ar    TEXT,
    name_fr    TEXT NOT NULL,
    name_en    TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS dhikr (
    id             INTEGER PRIMARY KEY,
    category_id    INTEGER NOT NULL REFERENCES dhikr_category(id),
    text_ar        TEXT NOT NULL,
    translit       TEXT,
    translation_fr TEXT,
    translation_en TEXT,
    repeat_count   INTEGER NOT NULL DEFAULT 1,
    source         TEXT NOT NULL,
    license        TEXT,
    sort_order     INTEGER NOT NULL DEFAULT 0
);

-- Fêtes et événements du calendrier hégirien (V1.x)
CREATE TABLE IF NOT EXISTS islamic_event (
    id           INTEGER PRIMARY KEY,
    hijri_month  INTEGER NOT NULL CHECK (hijri_month BETWEEN 1 AND 12),
    hijri_day    INTEGER NOT NULL CHECK (hijri_day BETWEEN 1 AND 30),
    name_ar      TEXT,
    name_fr      TEXT NOT NULL,
    name_en      TEXT
);
