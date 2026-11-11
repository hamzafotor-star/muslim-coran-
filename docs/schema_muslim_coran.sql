-- ============================================================
-- Muslim Coran — Schéma de base de données SQLite
-- Version 1.0 — Novembre 2026
--
-- Deux bases séparées :
--   1) quran.db  : contenu en LECTURE SEULE (livré avec l'app ou
--                  téléchargé). Texte, traductions, métadonnées.
--   2) user.db   : données de l'UTILISATEUR (lecture/écriture).
--                  Signets, notes, progression, réglages, téléchargements.
-- Cette séparation permet de mettre à jour le contenu sans toucher
-- aux données personnelles.
-- ============================================================


-- ############################################################
-- PARTIE A — quran.db (contenu, lecture seule)
-- ############################################################

PRAGMA foreign_keys = ON;

-- Version et intégrité du contenu
CREATE TABLE meta (
    key     TEXT PRIMARY KEY,
    value   TEXT NOT NULL
);
-- Exemples : ('schema_version','1'), ('quran_text_source','Tanzil Uthmani'),
--            ('quran_text_sha256','<somme de contrôle>'), ('content_version','2026.11')

-- Sourates (114)
CREATE TABLE surah (
    id               INTEGER PRIMARY KEY CHECK (id BETWEEN 1 AND 114),
    name_ar          TEXT NOT NULL,
    name_translit    TEXT NOT NULL,           -- ex. Al-Baqara
    name_fr          TEXT,                    -- ex. La Vache
    name_en          TEXT,
    revelation_type  TEXT NOT NULL CHECK (revelation_type IN ('meccan','medinan')),
    revelation_order INTEGER,
    ayah_count       INTEGER NOT NULL CHECK (ayah_count > 0),
    has_bismillah    INTEGER NOT NULL DEFAULT 1 CHECK (has_bismillah IN (0,1))
);

-- Versets (6 236)
CREATE TABLE ayah (
    id               INTEGER PRIMARY KEY,     -- numéro global 1..6236
    surah_id         INTEGER NOT NULL REFERENCES surah(id),
    ayah_number      INTEGER NOT NULL CHECK (ayah_number > 0),
    text_uthmani     TEXT NOT NULL,           -- texte complet avec signes
    text_simple      TEXT NOT NULL,           -- sans voyelles (pour la recherche)
    juz              INTEGER NOT NULL CHECK (juz BETWEEN 1 AND 30),
    hizb_quarter     INTEGER NOT NULL CHECK (hizb_quarter BETWEEN 1 AND 240),
    manzil           INTEGER CHECK (manzil BETWEEN 1 AND 7),
    ruku             INTEGER,
    page_15          INTEGER,                 -- page du mushaf 15 lignes (1..604)
    sajda_type       TEXT CHECK (sajda_type IN ('recommended','obligatory')),
    UNIQUE (surah_id, ayah_number)
);
CREATE INDEX idx_ayah_juz   ON ayah(juz);
CREATE INDEX idx_ayah_page  ON ayah(page_15);
CREATE INDEX idx_ayah_hizb  ON ayah(hizb_quarter);

-- Mots du verset (pour surlignage mot à mot, option V1.x)
CREATE TABLE word (
    id           INTEGER PRIMARY KEY,
    ayah_id      INTEGER NOT NULL REFERENCES ayah(id),
    position     INTEGER NOT NULL,            -- ordre dans le verset
    text_ar      TEXT NOT NULL,
    translit     TEXT,
    translation  TEXT,
    UNIQUE (ayah_id, position)
);

-- Mise en page du mushaf (mode page) : 1 ligne = 1 ligne imprimée
CREATE TABLE mushaf_line (
    page         INTEGER NOT NULL,
    line_number  INTEGER NOT NULL,
    line_type    TEXT NOT NULL CHECK (line_type IN ('ayah','surah_name','bismillah')),
    first_word_id INTEGER REFERENCES word(id),
    last_word_id  INTEGER REFERENCES word(id),
    surah_id     INTEGER REFERENCES surah(id),
    PRIMARY KEY (page, line_number)
);

-- Traductions (une ligne par traduction disponible)
CREATE TABLE translation (
    id           INTEGER PRIMARY KEY,
    lang         TEXT NOT NULL,               -- 'fr', 'en', 'ar'...
    name         TEXT NOT NULL,               -- ex. « Hamidullah »
    translator   TEXT,
    source_url   TEXT,
    license      TEXT NOT NULL,               -- obligatoire : trace de la licence
    is_default   INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0,1)),
    UNIQUE (lang, name)
);

CREATE TABLE ayah_translation (
    ayah_id        INTEGER NOT NULL REFERENCES ayah(id),
    translation_id INTEGER NOT NULL REFERENCES translation(id),
    text           TEXT NOT NULL,
    PRIMARY KEY (ayah_id, translation_id)
);

-- Tafsir (V1.x)
CREATE TABLE tafsir (
    id         INTEGER PRIMARY KEY,
    lang       TEXT NOT NULL,
    name       TEXT NOT NULL,
    author     TEXT,
    source_url TEXT,
    license    TEXT NOT NULL,
    UNIQUE (lang, name)
);

CREATE TABLE ayah_tafsir (
    ayah_id   INTEGER NOT NULL REFERENCES ayah(id),
    tafsir_id INTEGER NOT NULL REFERENCES tafsir(id),
    text      TEXT NOT NULL,
    PRIMARY KEY (ayah_id, tafsir_id)
);

-- Récitateurs et fichiers audio
CREATE TABLE reciter (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    style       TEXT,                         -- Murattal, Mujawwad...
    base_url    TEXT NOT NULL,                -- source audio
    license     TEXT NOT NULL,
    is_default  INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0,1))
);

CREATE TABLE audio_file (
    id          INTEGER PRIMARY KEY,
    reciter_id  INTEGER NOT NULL REFERENCES reciter(id),
    surah_id    INTEGER NOT NULL REFERENCES surah(id),
    ayah_id     INTEGER REFERENCES ayah(id),  -- NULL = fichier de sourate entière
    url         TEXT NOT NULL,
    size_bytes  INTEGER,
    duration_ms INTEGER,
    UNIQUE (reciter_id, surah_id, ayah_id)
);
CREATE INDEX idx_audio_reciter_surah ON audio_file(reciter_id, surah_id);

-- Repères temporels pour surligner le verset pendant la lecture d'une sourate
CREATE TABLE audio_timing (
    audio_file_id INTEGER NOT NULL REFERENCES audio_file(id),
    ayah_id       INTEGER NOT NULL REFERENCES ayah(id),
    start_ms      INTEGER NOT NULL,
    end_ms        INTEGER NOT NULL,
    PRIMARY KEY (audio_file_id, ayah_id)
);

-- Recherche plein texte (FTS5) — arabe sans voyelles + traductions
CREATE VIRTUAL TABLE ayah_fts USING fts5(
    text_simple,
    content='ayah',
    content_rowid='id',
    tokenize='unicode61 remove_diacritics 2'
);

CREATE VIRTUAL TABLE translation_fts USING fts5(
    text,
    translation_id UNINDEXED,
    ayah_id UNINDEXED,
    tokenize='unicode61 remove_diacritics 2'
);

-- Villes (calcul des horaires et Qibla hors ligne) — source GeoNames
CREATE TABLE city (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    name_ascii  TEXT NOT NULL,
    country     TEXT NOT NULL,                -- code ISO 3166-1 alpha-2
    admin1      TEXT,
    latitude    REAL NOT NULL CHECK (latitude  BETWEEN -90  AND 90),
    longitude   REAL NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    timezone    TEXT NOT NULL,                -- ex. Africa/Ouagadougou
    population  INTEGER
);
CREATE INDEX idx_city_name    ON city(name_ascii);
CREATE INDEX idx_city_country ON city(country);

-- Invocations / Dhikr (V1.x)
CREATE TABLE dhikr_category (
    id        INTEGER PRIMARY KEY,
    name_ar   TEXT,
    name_fr   TEXT NOT NULL,
    name_en   TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE dhikr (
    id          INTEGER PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES dhikr_category(id),
    text_ar     TEXT NOT NULL,
    translit    TEXT,
    translation_fr TEXT,
    translation_en TEXT,
    repeat_count INTEGER NOT NULL DEFAULT 1,
    source      TEXT NOT NULL,                -- référence du hadith ou du verset
    license     TEXT,
    sort_order  INTEGER NOT NULL DEFAULT 0
);

-- Fêtes et événements du calendrier hégirien (V1.x)
CREATE TABLE islamic_event (
    id           INTEGER PRIMARY KEY,
    hijri_month  INTEGER NOT NULL CHECK (hijri_month BETWEEN 1 AND 12),
    hijri_day    INTEGER NOT NULL CHECK (hijri_day BETWEEN 1 AND 30),
    name_ar      TEXT,
    name_fr      TEXT NOT NULL,
    name_en      TEXT
);


-- ############################################################
-- PARTIE B — user.db (données utilisateur, lecture/écriture)
-- ############################################################
-- Les références aux versets (ayah_id) pointent vers quran.db.
-- SQLite ne gère pas de clé étrangère entre deux fichiers :
-- l'intégrité est vérifiée par l'application.
-- ------------------------------------------------------------

-- Réglages (clé / valeur)
CREATE TABLE settings (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,
    updated_at INTEGER NOT NULL               -- timestamp Unix (secondes)
);
-- Clés prévues : language, theme, arabic_font, arabic_font_size,
-- default_translation_id, show_translation, default_reciter_id,
-- reading_mode ('ayah'|'mushaf'), wifi_only_downloads

-- Signets
CREATE TABLE bookmark (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    ayah_id    INTEGER NOT NULL,
    label      TEXT,
    color      TEXT,
    created_at INTEGER NOT NULL,
    deleted_at INTEGER,                       -- suppression logique (synchro)
    UNIQUE (ayah_id)
);

-- Notes personnelles
CREATE TABLE note (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    ayah_id    INTEGER NOT NULL,
    body       TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);
CREATE INDEX idx_note_ayah ON note(ayah_id);

-- Historique de lecture (dernières positions)
CREATE TABLE reading_history (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    ayah_id    INTEGER NOT NULL,
    mode       TEXT NOT NULL CHECK (mode IN ('ayah','mushaf','audio')),
    read_at    INTEGER NOT NULL
);
CREATE INDEX idx_history_date ON reading_history(read_at DESC);

-- Position courante (une seule ligne : « Reprendre la lecture »)
CREATE TABLE reading_position (
    id         INTEGER PRIMARY KEY CHECK (id = 1),
    ayah_id    INTEGER NOT NULL,
    page       INTEGER,
    updated_at INTEGER NOT NULL
);

-- Lieu choisi pour les horaires
CREATE TABLE location_profile (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT NOT NULL,
    latitude       REAL NOT NULL,
    longitude      REAL NOT NULL,
    timezone       TEXT NOT NULL,
    source         TEXT NOT NULL CHECK (source IN ('gps','city','manual')),
    city_id        INTEGER,                   -- référence quran.db.city
    is_active      INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0,1)),
    created_at     INTEGER NOT NULL
);

-- Réglages des prières (une ligne par lieu)
CREATE TABLE prayer_settings (
    location_id        INTEGER PRIMARY KEY REFERENCES location_profile(id) ON DELETE CASCADE,
    calc_method        TEXT NOT NULL DEFAULT 'MWL',   -- MWL, UOIF, UmmAlQura, Egyptian, ISNA...
    asr_school         TEXT NOT NULL DEFAULT 'shafi'  CHECK (asr_school IN ('shafi','hanafi')),
    high_lat_rule      TEXT,
    adj_fajr           INTEGER NOT NULL DEFAULT 0,    -- minutes
    adj_sunrise        INTEGER NOT NULL DEFAULT 0,
    adj_dhuhr          INTEGER NOT NULL DEFAULT 0,
    adj_asr            INTEGER NOT NULL DEFAULT 0,
    adj_maghrib        INTEGER NOT NULL DEFAULT 0,
    adj_isha           INTEGER NOT NULL DEFAULT 0,
    hijri_offset_days  INTEGER NOT NULL DEFAULT 0
);

-- Notifications / Adhan par prière
CREATE TABLE prayer_alarm (
    prayer         TEXT PRIMARY KEY CHECK (prayer IN
                   ('fajr','sunrise','dhuhr','asr','maghrib','isha','imsak','iftar')),
    enabled        INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
    adhan_id       TEXT NOT NULL DEFAULT 'default',
    reminder_min   INTEGER NOT NULL DEFAULT 0,        -- rappel avant la prière
    vibrate        INTEGER NOT NULL DEFAULT 1 CHECK (vibrate IN (0,1))
);

-- Téléchargements (audio, traductions, tafsir)
CREATE TABLE download (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    kind          TEXT NOT NULL CHECK (kind IN ('audio','translation','tafsir')),
    ref_id        INTEGER NOT NULL,                   -- audio_file.id, translation.id...
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
CREATE TABLE reading_plan (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT NOT NULL,
    total_days     INTEGER NOT NULL CHECK (total_days > 0),
    start_date     TEXT NOT NULL,                     -- AAAA-MM-JJ
    pages_per_day  REAL NOT NULL,
    is_active      INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    completed_at   INTEGER
);

CREATE TABLE reading_plan_day (
    plan_id     INTEGER NOT NULL REFERENCES reading_plan(id) ON DELETE CASCADE,
    day_number  INTEGER NOT NULL,
    start_page  INTEGER NOT NULL,
    end_page    INTEGER NOT NULL,
    done_at     INTEGER,
    PRIMARY KEY (plan_id, day_number)
);

-- Mémorisation (Hifz) — révision espacée (V1.x)
CREATE TABLE memorization_item (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    surah_id      INTEGER NOT NULL,
    from_ayah     INTEGER NOT NULL,
    to_ayah       INTEGER NOT NULL,
    status        TEXT NOT NULL DEFAULT 'learning'
                  CHECK (status IN ('learning','memorized','review')),
    ease_factor   REAL NOT NULL DEFAULT 2.5,
    interval_days INTEGER NOT NULL DEFAULT 0,
    next_review   TEXT,                               -- AAAA-MM-JJ
    created_at    INTEGER NOT NULL
);
CREATE INDEX idx_memo_next ON memorization_item(next_review);

CREATE TABLE memorization_review (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id     INTEGER NOT NULL REFERENCES memorization_item(id) ON DELETE CASCADE,
    reviewed_at INTEGER NOT NULL,
    quality     INTEGER NOT NULL CHECK (quality BETWEEN 0 AND 5)
);

-- Compteur de dhikr / Tasbih (V1.x)
CREATE TABLE tasbih_counter (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    label       TEXT NOT NULL,
    target      INTEGER NOT NULL DEFAULT 33,
    count       INTEGER NOT NULL DEFAULT 0,
    updated_at  INTEGER NOT NULL
);

CREATE TABLE tasbih_log (
    day         TEXT NOT NULL,                        -- AAAA-MM-JJ
    counter_id  INTEGER NOT NULL REFERENCES tasbih_counter(id) ON DELETE CASCADE,
    total       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (day, counter_id)
);

-- Compte et synchronisation (optionnel, V1.x)
CREATE TABLE sync_state (
    entity        TEXT PRIMARY KEY,                   -- 'bookmark','note','reading_position'...
    last_sync_at  INTEGER,
    cursor        TEXT
);

-- Valeurs par défaut au premier lancement
INSERT INTO reading_position (id, ayah_id, page, updated_at) VALUES (1, 1, 1, 0);

INSERT INTO prayer_alarm (prayer) VALUES
    ('fajr'), ('dhuhr'), ('asr'), ('maghrib'), ('isha');
INSERT INTO prayer_alarm (prayer, enabled) VALUES
    ('sunrise', 0), ('imsak', 0), ('iftar', 0);
