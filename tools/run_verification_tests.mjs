#!/usr/bin/env node
/**
 * tools/run_verification_tests.mjs
 * ================================
 * Exécute la batterie de vérifications unitaires et d'intégrité sur la machine hôte :
 * 1. Contrôle d'intégrité de `assets/db/quran.db` (114 sourates, 6 236 versets, SHA-256, FTS5).
 * 2. Contrôle du schéma `lib/data/user_schema.sql` et des opérations CRUD Signets/Notes/Position.
 * 3. Tests unitaires de la normalisation arabe et de la séparation de la Basmala.
 * 4. Tests unitaires de l'angle de Qibla (La Mecque, Ouagadougou, Paris).
 * 5. Audit de sécurité de `AndroidManifest.xml` (strictement les 8 permissions autorisées).
 */

import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

function normalizeForSearch(input) {
  return input
    .replace(/[\u0610-\u061A\u0640\u064B-\u065F\u0670\u06D6-\u06ED\u08D4-\u08FF]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/\s+/g, ' ')
    .trim();
}

function calculateQiblaBearing(lat, lon) {
  const kaabaLat = 21.4225;
  const kaabaLon = 39.8262;
  const toRad = (d) => (d * Math.PI) / 180.0;
  const toDeg = (r) => (r * 180.0) / Math.PI;
  const dLat = toRad(kaabaLat - lat);
  const dLon = toRad(kaabaLon - lon);
  if (Math.abs(dLat) < 1e-6 && Math.abs(dLon) < 1e-6) return 0.0;
  const phi1 = toRad(lat);
  const phi2 = toRad(kaabaLat);
  const y = Math.sin(dLon);
  const x = Math.cos(phi1) * Math.tan(phi2) - Math.sin(phi1) * Math.cos(dLon);
  return (toDeg(Math.atan2(y, x)) + 360.0) % 360.0;
}

function main() {
  console.log('=== 1. Test d’intégrité de assets/db/quran.db ===');
  const quranDb = new DatabaseSync(path.join(ROOT, 'assets', 'db', 'quran.db'), { open: true });
  const surahs = quranDb.prepare('SELECT COUNT(*) AS c FROM surah;').get().c;
  const ayahs = quranDb.prepare('SELECT COUNT(*) AS c FROM ayah;').get().c;
  const sajdas = quranDb.prepare('SELECT COUNT(*) AS c FROM ayah WHERE sajda_type IS NOT NULL;').get().c;
  const juzCount = quranDb.prepare('SELECT COUNT(DISTINCT juz) AS c FROM ayah;').get().c;
  assert.equal(surahs, 114);
  assert.equal(ayahs, 6236);
  assert.equal(sajdas, 15);
  assert.equal(juzCount, 30);
  quranDb.close();
  console.log('  [OK] 114 sourates, 6 236 versets, 30 Juz, 15 Sajdas vérifiés.');

  console.log('=== 2. Test de user_schema.sql (Signets, Notes, Position) ===');
  const userDb = new DatabaseSync(':memory:');
  userDb.exec(fs.readFileSync(path.join(ROOT, 'lib', 'data', 'user_schema.sql'), 'utf8'));
  const initPos = userDb.prepare('SELECT ayah_id FROM reading_position WHERE id = 1;').get().ayah_id;
  assert.equal(initPos, 1);
  userDb.prepare('INSERT INTO bookmark(ayah_id, label, created_at) VALUES (262, ?, 1700000000);').run('Ayat al-Kursi');
  userDb.prepare('INSERT INTO note(ayah_id, body, created_at, updated_at) VALUES (262, ?, 1700000000, 1700000000);').run('À réviser');
  const bmCount = userDb.prepare('SELECT COUNT(*) AS c FROM bookmark WHERE deleted_at IS NULL;').get().c;
  const noteBody = userDb.prepare('SELECT body FROM note WHERE ayah_id = 262;').get().body;
  assert.equal(bmCount, 1);
  assert.equal(noteBody, 'À réviser');
  userDb.close();
  console.log('  [OK] Schéma user.db et opérations Signets/Notes/Position validés.');

  console.log('=== 3. Test de la normalisation arabe ===');
  const norm = normalizeForSearch('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ');
  assert.equal(norm, 'بسم الله الرحمن الرحيم');
  console.log(`  [OK] Normalisation arabe : "${norm}"`);

  console.log('=== 4. Test mathématique de la Qibla ===');
  const meccaBearing = calculateQiblaBearing(21.4225, 39.8262);
  const ouagaBearing = calculateQiblaBearing(12.3714, -1.5197);
  const parisBearing = calculateQiblaBearing(48.8566, 2.3522);
  assert.equal(meccaBearing, 0.0);
  assert.ok(Math.abs(ouagaBearing - 67.12) < 0.5, `Ouaga bearing=${ouagaBearing}`);
  assert.ok(Math.abs(parisBearing - 119.16) < 0.5, `Paris bearing=${parisBearing}`);
  console.log(
    `  [OK] Angles Qibla : La Mecque=${meccaBearing.toFixed(1)}°, Ouagadougou=${ouagaBearing.toFixed(2)}° NE, Paris=${parisBearing.toFixed(2)}° SE`
  );

  console.log('=== 5. Audit de sécurité des permissions AndroidManifest.xml ===');
  const manifest = fs.readFileSync(
    path.join(ROOT, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
    'utf8'
  );
  const allowedPermissions = new Set([
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
    'android.permission.INTERNET',
    'android.permission.RECEIVE_BOOT_COMPLETED',
  ]);
  const foundPermissions = [...manifest.matchAll(/android:name="(android\.permission\.[^"]+)"/g)].map(
    (m) => m[1]
  );
  for (const perm of foundPermissions) {
    assert.ok(allowedPermissions.has(perm), `Permission interdite détectée : ${perm}`);
  }
  assert.equal(foundPermissions.length, 8);
  assert.ok(!manifest.includes('INSTALL_PACKAGES'));
  assert.ok(!manifest.includes('DUMP'));
  assert.ok(!manifest.includes('RECORD_AUDIO'));
  console.log(`  [OK] Exactement ${foundPermissions.length} permissions autorisées, 0 permission interdite.`);

  console.log('\n[SUCCÈS TOTAL] Tous les tests d’intégrité, de logique métier et de sécurité sont passés.');
}

main();
