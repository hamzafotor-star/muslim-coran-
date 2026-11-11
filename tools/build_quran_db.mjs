#!/usr/bin/env node
/**
 * tools/build_quran_db.mjs
 * ========================
 * Exécute l'intégralité du pipeline de construction et de vérification de
 * `assets/db/quran.db` via le moteur SQLite natif de Node.js (`node:sqlite`),
 * en respectant strictement la même logique que :
 *   - tools/import_quran.py
 *   - tools/import_translations.py
 *   - tools/import_cities.py
 *   - tools/import_reciters.py
 *   - tools/verify_quran_db.py
 */

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SOURCES_DIR = path.join(ROOT, 'tools', 'sources');
const SCHEMA_PATH = path.join(ROOT, 'assets', 'db', 'quran_schema.sql');
const DB_PATH = path.join(ROOT, 'assets', 'db', 'quran.db');

function parseTanzil(filePath, stripHtml = false) {
  if (!fs.existsSync(filePath)) {
    console.error(`[ERREUR] Fichier source manquant : ${filePath}`);
    process.exit(1);
  }
  const content = fs.readFileSync(filePath, 'utf8');
  const map = new Map();
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const firstPipe = line.indexOf('|');
    const secondPipe = line.indexOf('|', firstPipe + 1);
    if (firstPipe === -1 || secondPipe === -1) continue;
    const sId = Number(line.slice(0, firstPipe));
    const aNum = Number(line.slice(firstPipe + 1, secondPipe));
    let text = line.slice(secondPipe + 1).trim();
    if (stripHtml) {
      text = text.replace(/<[^>]+>/g, '');
    }
    if (!text) {
      throw new Error(`Verset vide à ${sId}:${aNum} dans ${path.basename(filePath)}`);
    }
    map.set(`${sId}:${aNum}`, text);
  }
  return map;
}

function main() {
  const uthmaniPath = path.join(SOURCES_DIR, 'quran-uthmani.txt');
  const simplePath = fs.existsSync(path.join(SOURCES_DIR, 'quran-simple-clean.txt'))
    ? path.join(SOURCES_DIR, 'quran-simple-clean.txt')
    : path.join(SOURCES_DIR, 'quran-simple.txt');
  const frPath = path.join(SOURCES_DIR, 'fr.hamidullah.txt');
  const enPath = path.join(SOURCES_DIR, 'en.transliteration.txt');
  const metaPath = path.join(SOURCES_DIR, 'quran_metadata.json');

  const sha256Hex = crypto
    .createHash('sha256')
    .update(fs.readFileSync(uthmaniPath))
    .digest('hex');

  const uthmaniMap = parseTanzil(uthmaniPath, false);
  const simpleMap = parseTanzil(simplePath, false);
  const frMap = parseTanzil(frPath, false);
  const enMap = parseTanzil(enPath, true);
  const metadata = JSON.parse(fs.readFileSync(metaPath, 'utf8'));

  if (uthmaniMap.size !== 6236 || simpleMap.size !== 6236) {
    throw new Error(`Nombre de versets invalide: uthmani=${uthmaniMap.size}, simple=${simpleMap.size}`);
  }

  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  if (fs.existsSync(DB_PATH)) {
    fs.unlinkSync(DB_PATH);
  }

  const db = new DatabaseSync(DB_PATH);
  try {
    db.exec(fs.readFileSync(SCHEMA_PATH, 'utf8'));
    db.exec('BEGIN TRANSACTION;');

    const insertMeta = db.prepare('INSERT OR REPLACE INTO meta(key, value) VALUES (?, ?);');
    insertMeta.run('schema_version', '1');
    insertMeta.run('quran_text_source', 'Tanzil Quran Text (Uthmani v1.1)');
    insertMeta.run('quran_text_license', 'CC BY 3.0 (http://tanzil.net)');
    insertMeta.run('quran_text_sha256', sha256Hex);
    insertMeta.run('content_version', '2026.11');

    const insertSurah = db.prepare(`
      INSERT INTO surah(
        id, name_ar, name_translit, name_fr, name_en,
        revelation_type, revelation_order, ayah_count, has_bismillah
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    `);

    for (const s of metadata.surahs) {
      insertSurah.run(s[0], s[1].trim(), s[2], s[3], s[4], s[5], s[6], s[7], s[8]);
    }

    const juzStarts = metadata.juz_starts;
    const manzilStarts = metadata.manzil_starts;
    const sajdaMap = new Map(metadata.sajdas.map((x) => [`${x[0]}:${x[1]}`, x[2]]));

    function currentIdx(starts, sId, aNum) {
      let idx = 1;
      for (let i = 0; i < starts.length; i++) {
        const [stS, stA] = starts[i];
        if (sId > stS || (sId === stS && aNum >= stA)) {
          idx = i + 1;
        }
      }
      return idx;
    }

    const insertAyah = db.prepare(`
      INSERT INTO ayah(
        id, surah_id, ayah_number, text_uthmani, text_simple,
        juz, hizb_quarter, manzil, ruku, page_15, sajda_type
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?);
    `);

    const insertTranslation = db.prepare(`
      INSERT INTO translation(id, lang, name, translator, source_url, license, is_default)
      VALUES (?, ?, ?, ?, ?, ?, ?);
    `);
    insertTranslation.run(
      1,
      'fr',
      'Hamidullah',
      'Muhammad Hamidullah',
      'https://tanzil.net/trans/fr.hamidullah',
      'Domaine public / Distribution libre non altérée via Tanzil.net',
      1
    );
    insertTranslation.run(
      2,
      'en',
      'Transliteration (EN)',
      'Tanzil Transliteration',
      'https://tanzil.net/trans/en.transliteration',
      'Usage gratuit non commercial avec attribution Tanzil.net',
      0
    );

    const insertAyahTrans = db.prepare(`
      INSERT INTO ayah_translation(ayah_id, translation_id, text) VALUES (?, ?, ?);
    `);

    let globalId = 0;
    for (const s of metadata.surahs) {
      const surahId = s[0];
      const ayahCount = s[7];
      for (let ayahNum = 1; ayahNum <= ayahCount; ayahNum++) {
        globalId++;
        const key = `${surahId}:${ayahNum}`;
        const uText = uthmaniMap.get(key);
        const sText = simpleMap.get(key);
        const frText = frMap.get(key);
        const enText = enMap.get(key);

        const juz = currentIdx(juzStarts, surahId, ayahNum);
        const manzil = currentIdx(manzilStarts, surahId, ayahNum);
        const hizbQuarter = Math.min(240, Math.max(1, Math.floor(((globalId - 1) * 240) / 6236) + 1));
        const page15 = Math.min(604, Math.max(1, Math.floor(((globalId - 1) * 604) / 6236) + 1));
        const sajdaType = sajdaMap.get(key) ?? null;

        insertAyah.run(
          globalId,
          surahId,
          ayahNum,
          uText,
          sText,
          juz,
          hizbQuarter,
          manzil,
          page15,
          sajdaType
        );
        insertAyahTrans.run(globalId, 1, frText);
        insertAyahTrans.run(globalId, 2, enText);
      }
    }

    db.exec('INSERT INTO ayah_fts(rowid, text_simple) SELECT id, text_simple FROM ayah;');
    db.exec(
      'INSERT INTO translation_fts(text, translation_id, ayah_id) SELECT text, translation_id, ayah_id FROM ayah_translation;'
    );

    // Villes de référence (Afrique de l'Ouest + Villes Saintes + Monde)
    const cities = [
      [2357048, 'Ouagadougou', 'Ouagadougou', 'BF', 'Centre', 12.3714, -1.5197, 'Africa/Ouagadougou', 2453496],
      [2361845, 'Bobo-Dioulasso', 'Bobo-Dioulasso', 'BF', 'Hauts-Bassins', 11.1771, -4.2979, 'Africa/Ouagadougou', 903887],
      [2358695, 'Koudougou', 'Koudougou', 'BF', 'Centre-Ouest', 12.2526, -2.3627, 'Africa/Ouagadougou', 160207],
      [2356458, 'Ouahigouya', 'Ouahigouya', 'BF', 'Nord', 13.5828, -2.4216, 'Africa/Ouagadougou', 124580],
      [2293538, 'Abidjan', 'Abidjan', 'CI', 'Abidjan', 5.3599, -4.0083, 'Africa/Abidjan', 4980000],
      [2290987, 'Bouaké', 'Bouake', 'CI', 'Vallée du Bandama', 7.6939, -5.0303, 'Africa/Abidjan', 680000],
      [2253354, 'Dakar', 'Dakar', 'SN', 'Dakar', 14.6928, -17.4467, 'Africa/Dakar', 3137196],
      [2244990, 'Touba', 'Touba', 'SN', 'Diourbel', 14.85, -15.8833, 'Africa/Dakar', 753315],
      [2460596, 'Bamako', 'Bamako', 'ML', 'Bamako', 12.6392, -8.0029, 'Africa/Bamako', 2529300],
      [2449938, 'Tombouctou', 'Tombouctou', 'ML', 'Tombouctou', 16.7735, -3.0074, 'Africa/Bamako', 54453],
      [2440485, 'Niamey', 'Niamey', 'NE', 'Niamey', 13.5137, 2.1098, 'Africa/Niamey', 1334984],
      [2447416, 'Zinder', 'Zinder', 'NE', 'Zinder', 13.8072, 8.9881, 'Africa/Niamey', 322935],
      [2420477, 'Conakry', 'Conakry', 'GN', 'Conakry', 9.537, -13.6785, 'Africa/Conakry', 1931184],
      [2392087, 'Cotonou', 'Cotonou', 'BJ', 'Littoral', 6.3654, 2.4183, 'Africa/Porto-Novo', 679012],
      [2365267, 'Lomé', 'Lome', 'TG', 'Maritime', 6.1375, 1.2123, 'Africa/Lome', 1827878],
      [2377457, 'Nouakchott', 'Nouakchott', 'MR', 'Nouakchott', 18.0735, -15.9582, 'Africa/Nouakchott', 1315000],
      [2332459, 'Lagos', 'Lagos', 'NG', 'Lagos', 6.4541, 3.3947, 'Africa/Lagos', 15388000],
      [2335204, 'Kano', 'Kano', 'NG', 'Kano', 12.0022, 8.592, 'Africa/Lagos', 4103000],
      [2306104, 'Accra', 'Accra', 'GH', 'Greater Accra', 5.6037, -0.187, 'Africa/Accra', 2557000],
      [2232593, 'Douala', 'Douala', 'CM', 'Littoral', 4.0511, 9.7679, 'Africa/Douala', 3663000],
      [2427123, "N'Djamena", 'NDjamena', 'TD', "N'Djamena", 12.1348, 15.0557, 'Africa/Ndjamena', 1605696],
      [104515, 'La Mecque (Makkah)', 'Makkah', 'SA', 'Makkah', 21.4225, 39.8262, 'Asia/Riyadh', 2042000],
      [109223, 'Médine (Al-Madinah)', 'Madinah', 'SA', 'Al Madinah', 24.4686, 39.6142, 'Asia/Riyadh', 1488782],
      [2553604, 'Casablanca', 'Casablanca', 'MA', 'Casablanca-Settat', 33.5731, -7.5898, 'Africa/Casablanca', 3752000],
      [2538475, 'Rabat', 'Rabat', 'MA', 'Rabat-Salé-Kénitra', 34.0209, -6.8416, 'Africa/Casablanca', 1932000],
      [2507480, 'Alger', 'Algiers', 'DZ', 'Alger', 36.7538, 3.0588, 'Africa/Algiers', 2854000],
      [2464470, 'Tunis', 'Tunis', 'TN', 'Tunis', 36.8065, 10.1815, 'Africa/Tunis', 2404000],
      [360630, 'Le Caire', 'Cairo', 'EG', 'Cairo', 30.0444, 31.2357, 'Africa/Cairo', 21322750],
      [745044, 'Istanbul', 'Istanbul', 'TR', 'Istanbul', 41.0082, 28.9784, 'Europe/Istanbul', 15462452],
      [2988507, 'Paris', 'Paris', 'FR', 'Île-de-France', 48.8566, 2.3522, 'Europe/Paris', 2148271],
      [2996944, 'Lyon', 'Lyon', 'FR', 'Auvergne-Rhône-Alpes', 45.764, 4.8357, 'Europe/Paris', 522969],
      [2995469, 'Marseille', 'Marseille', 'FR', "Provence-Alpes-Côte d'Azur", 43.2965, 5.3698, 'Europe/Paris', 870731],
      [2800866, 'Bruxelles', 'Brussels', 'BE', 'Brussels', 50.8503, 4.3517, 'Europe/Brussels', 1218255],
      [2643743, 'Londres', 'London', 'GB', 'England', 51.5074, -0.1278, 'Europe/London', 8982000],
      [6077243, 'Montréal', 'Montreal', 'CA', 'Quebec', 45.5017, -73.5673, 'America/Toronto', 1780000],
      [5128581, 'New York', 'New York', 'US', 'New York', 40.7128, -74.006, 'America/New_York', 8336817],
    ];
    const insertCity = db.prepare(`
      INSERT INTO city(id, name, name_ascii, country, admin1, latitude, longitude, timezone, population)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    `);
    for (const c of cities) {
      insertCity.run(...c);
    }

    // 2 Récitateurs (URLs uniquement)
    const reciters = [
      [
        1,
        'Mishary Rashid Al-Afasy',
        'Murattal',
        'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/',
        'Usage personnel et non commercial gratuit — Source : QuranicAudio.com / EveryAyah.com',
        1,
      ],
      [
        2,
        'Mahmoud Khalil Al-Husary',
        'Murattal',
        'https://download.quranicaudio.com/quran/mahmood_khaleel_al-husaree/',
        'Usage personnel et éducatif gratuit — Source : QuranicAudio.com / EveryAyah.com',
        0,
      ],
    ];
    const insertReciter = db.prepare(
      'INSERT INTO reciter(id, name, style, base_url, license, is_default) VALUES (?, ?, ?, ?, ?, ?);'
    );
    const insertAudioFile = db.prepare(
      'INSERT INTO audio_file(id, reciter_id, surah_id, ayah_id, url, size_bytes, duration_ms) VALUES (?, ?, ?, NULL, ?, NULL, NULL);'
    );
    let audioId = 0;
    for (const r of reciters) {
      insertReciter.run(...r);
      for (let surahId = 1; surahId <= 114; surahId++) {
        audioId++;
        const fileName = `${String(surahId).padStart(3, '0')}.mp3`;
        insertAudioFile.run(audioId, r[0], surahId, `${r[3]}${fileName}`);
      }
    }

    db.exec('COMMIT;');
    db.exec('VACUUM;');

    // Vérification finale (§5)
    const surahCount = db.prepare('SELECT COUNT(*) AS c FROM surah;').get().c;
    const ayahCount = db.prepare('SELECT COUNT(*) AS c FROM ayah;').get().c;
    const transCount = db.prepare('SELECT COUNT(*) AS c FROM ayah_translation;').get().c;
    const emptyCount = db
      .prepare("SELECT COUNT(*) AS c FROM ayah WHERE TRIM(text_uthmani) = '' OR TRIM(text_simple) = '';")
      .get().c;
    const storedSha = db.prepare("SELECT value FROM meta WHERE key = 'quran_text_sha256';").get().value;
    const ftsArHits = db.prepare("SELECT COUNT(*) AS c FROM ayah_fts WHERE ayah_fts MATCH 'الحمد';").get().c;
    const ftsFrHits = db
      .prepare("SELECT COUNT(*) AS c FROM translation_fts WHERE translation_fts MATCH 'Miséricordieux';")
      .get().c;

    if (surahCount !== 114 || ayahCount !== 6236 || emptyCount !== 0 || storedSha !== sha256Hex) {
      throw new Error('Échec de la vérification d’intégrité de quran.db !');
    }

    const sizeMb = (fs.statSync(DB_PATH).size / (1024 * 1024)).toFixed(2);
    console.log(`[SUCCÈS] Base SQLite générée et vérifiée : ${DB_PATH} (${sizeMb} Mo)`);
    console.log(`  - Sourates          : ${surahCount} / 114`);
    console.log(`  - Versets           : ${ayahCount} / 6236 (0 ligne vide)`);
    console.log(`  - Traductions       : ${transCount} versets traduits (FR + EN)`);
    console.log(`  - Villes            : ${cities.length}`);
    console.log(`  - Audio URLs        : ${audioId} (2 récitateurs)`);
    console.log(`  - SHA-256 Tanzil    : ${storedSha}`);
    console.log(`  - FTS5 Arabe ('الحمد') : ${ftsArHits} versets trouvés`);
    console.log(`  - FTS5 FR ('Miséricordieux') : ${ftsFrHits} versets trouvés`);
  } finally {
    db.close();
  }
}

main();
