#!/usr/bin/env python3
"""
tools/import_translations.py
============================
Importe les traductions française (`fr.hamidullah.txt`) et anglaise/translittérée
(`en.sahih.txt` ou `en.transliteration.txt`) au format Tanzil dans `assets/db/quran.db`.

Remplit `translation`, `ayah_translation` et l'index FTS5 `translation_fts` avec
mention explicite des licences (conformément à docs/LICENSES.md).
"""

import pathlib
import re
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES_DIR = ROOT / "tools" / "sources"
DB_PATH = ROOT / "assets" / "db" / "quran.db"

HTML_TAG_RE = re.compile(r"<[^>]+>")


def parse_translation(path: pathlib.Path, strip_html: bool = False) -> dict[tuple[int, int], str]:
    if not path.exists():
        print(
            f"[ERREUR] Fichier de traduction introuvable : {path}\n"
            "Téléchargez-le depuis https://tanzil.net/trans/ et placez-le dans tools/sources/.",
            file=sys.stderr,
        )
        sys.exit(1)

    rows: dict[tuple[int, int], str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|", 2)
        if len(parts) != 3:
            continue
        s_id, a_num, txt = int(parts[0]), int(parts[1]), parts[2].strip()
        if strip_html:
            txt = HTML_TAG_RE.sub("", txt)
        if not txt:
            raise ValueError(f"Traduction vide à {s_id}:{a_num} dans {path.name}")
        rows[(s_id, a_num)] = txt
    return rows


def main() -> None:
    if not DB_PATH.exists():
        print("[ERREUR] Exécutez d'abord tools/import_quran.py pour créer quran.db.", file=sys.stderr)
        sys.exit(1)

    fr_path = SOURCES_DIR / "fr.hamidullah.txt"
    en_path = SOURCES_DIR / "en.sahih.txt"
    is_translit = False
    if not en_path.exists():
        en_path = SOURCES_DIR / "en.transliteration.txt"
        is_translit = True

    fr_map = parse_translation(fr_path, strip_html=False)
    en_map = parse_translation(en_path, strip_html=is_translit)

    conn = sqlite3.connect(str(DB_PATH))
    try:
        ayah_lookup = {
            (s_id, a_num): a_id
            for a_id, s_id, a_num in conn.execute("SELECT id, surah_id, ayah_number FROM ayah;")
        }
        if len(ayah_lookup) != 6236:
            raise RuntimeError("La table ayah doit contenir 6 236 versets avant d'importer les traductions.")

        with conn:
            conn.execute("DELETE FROM translation_fts;")
            conn.execute("DELETE FROM ayah_translation;")
            conn.execute("DELETE FROM translation;")

            conn.execute(
                """
                INSERT INTO translation(id, lang, name, translator, source_url, license, is_default)
                VALUES (1, 'fr', 'Hamidullah', 'Muhammad Hamidullah', 'https://tanzil.net/trans/fr.hamidullah',
                        'Domaine public / Distribution libre non altérée via Tanzil.net', 1);
                """
            )
            en_name = "Transliteration (EN)" if is_translit else "Saheeh International"
            en_translator = "Tanzil Transliteration" if is_translit else "Saheeh International"
            conn.execute(
                """
                INSERT INTO translation(id, lang, name, translator, source_url, license, is_default)
                VALUES (2, 'en', ?, ?, 'https://tanzil.net/trans/',
                        'Usage gratuit non commercial avec attribution Tanzil.net', 0);
                """,
                (en_name, en_translator),
            )

            for key, ayah_id in ayah_lookup.items():
                fr_text = fr_map[key]
                en_text = en_map[key]
                conn.execute(
                    "INSERT INTO ayah_translation(ayah_id, translation_id, text) VALUES (?, 1, ?);",
                    (ayah_id, fr_text),
                )
                conn.execute(
                    "INSERT INTO ayah_translation(ayah_id, translation_id, text) VALUES (?, 2, ?);",
                    (ayah_id, en_text),
                )

            conn.execute(
                "INSERT INTO translation_fts(text, translation_id, ayah_id) "
                "SELECT text, translation_id, ayah_id FROM ayah_translation;"
            )
        print("[OK] Traductions FR (Hamidullah) et EN importées et indexées dans translation_fts (12 472 entrées).")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
