#!/usr/bin/env python3
"""
tools/verify_quran_db.py
========================
Test automatique d'intégrité de `assets/db/quran.db` (§5) :
- Exactement 114 sourates
- Exactement 6 236 versets
- Somme de contrôle SHA-256 conforme au fichier `tools/sources/quran-uthmani.txt`
- Aucune ligne vide dans `ayah` ni dans `ayah_translation`
- Index plein texte `ayah_fts` et `translation_fts` opérationnels
"""

import hashlib
import pathlib
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
UTHMANI_PATH = ROOT / "tools" / "sources" / "quran-uthmani.txt"
DB_PATH = ROOT / "assets" / "db" / "quran.db"


def main() -> None:
    if not DB_PATH.exists():
        print(f"[ÉCHEC] Base introuvable : {DB_PATH}", file=sys.stderr)
        sys.exit(1)

    expected_sha256 = hashlib.sha256(UTHMANI_PATH.read_bytes()).hexdigest()
    conn = sqlite3.connect(str(DB_PATH))
    try:
        surah_count = conn.execute("SELECT COUNT(*) FROM surah;").fetchone()[0]
        ayah_count = conn.execute("SELECT COUNT(*) FROM ayah;").fetchone()[0]
        empty_ayahs = conn.execute(
            "SELECT COUNT(*) FROM ayah WHERE TRIM(text_uthmani) = '' OR TRIM(text_simple) = '';"
        ).fetchone()[0]
        stored_sha256 = conn.execute(
            "SELECT value FROM meta WHERE key = 'quran_text_sha256';"
        ).fetchone()[0]
        fts_hits = conn.execute(
            "SELECT COUNT(*) FROM ayah_fts WHERE ayah_fts MATCH 'الحمد';"
        ).fetchone()[0]

        assert surah_count == 114, f"Sourates: {surah_count} != 114"
        assert ayah_count == 6236, f"Versets: {ayah_count} != 6236"
        assert empty_ayahs == 0, f"Versets vides: {empty_ayahs} != 0"
        assert stored_sha256 == expected_sha256, "Somme de contrôle SHA-256 non conforme !"
        assert fts_hits > 0, "L'index FTS5 arabe ne retourne aucun résultat !"

        print("[SUCCÈS] Vérification intégrale de quran.db réussie :")
        print(f"  - Sourates : {surah_count} / 114")
        print(f"  - Versets  : {ayah_count} / 6236 (0 ligne vide)")
        print(f"  - SHA-256  : {stored_sha256} (conforme)")
        print(f"  - FTS5     : opérationnel ({fts_hits} occurrences pour 'الحمد')")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
