#!/usr/bin/env python3
"""
tools/import_quran.py
=====================
Script d'import officiel du texte coranique (Tanzil Uthmani + Simple) dans
la base SQLite en lecture seule `assets/db/quran.db`.

Règles respectées (§2 & §5) :
- Ne génère aucun verset de mémoire : lit exclusivement `tools/sources/quran-uthmani.txt`
  et `tools/sources/quran-simple-clean.txt` (ou `quran-simple.txt`).
- Vérifie les 114 sourates et les 6 236 versets.
- Calcule la somme de contrôle SHA-256 du fichier source Uthmani et l'enregistre
  dans `meta(key='quran_text_sha256')`.
- Remplit `surah`, `ayah` (juz, hizb_quarter, manzil, page_15, sajda_type) et
  l'index plein texte FTS5 `ayah_fts`.

Licence du texte : Creative Commons Attribution 3.0 (Tanzil Project - http://tanzil.net)
"""

import hashlib
import json
import pathlib
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES_DIR = ROOT / "tools" / "sources"
SCHEMA_PATH = ROOT / "assets" / "db" / "quran_schema.sql"
DB_PATH = ROOT / "assets" / "db" / "quran.db"


def parse_tanzil_file(path: pathlib.Path) -> dict[tuple[int, int], str]:
    if not path.exists():
        print(
            f"[ERREUR] Fichier source manquant : {path}\n"
            "Veuillez télécharger le texte officiel depuis https://tanzil.net/download/\n"
            "(Licence CC BY 3.0 Tanzil Project) et le placer dans tools/sources/.",
            file=sys.stderr,
        )
        sys.exit(1)

    verses: dict[tuple[int, int], str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|", 2)
        if len(parts) != 3:
            continue
        surah_id, ayah_num, text = int(parts[0]), int(parts[1]), parts[2].strip()
        if not text:
            raise ValueError(f"Verset vide détecté à {surah_id}:{ayah_num} dans {path.name}")
        verses[(surah_id, ayah_num)] = text
    return verses


def main() -> None:
    uthmani_path = SOURCES_DIR / "quran-uthmani.txt"
    simple_path = SOURCES_DIR / "quran-simple-clean.txt"
    if not simple_path.exists():
        simple_path = SOURCES_DIR / "quran-simple.txt"
    meta_path = SOURCES_DIR / "quran_metadata.json"

    for p in (uthmani_path, simple_path, meta_path, SCHEMA_PATH):
        if not p.exists():
            print(f"[ERREUR] Fichier requis introuvable : {p}", file=sys.stderr)
            sys.exit(1)

    sha256_hex = hashlib.sha256(uthmani_path.read_bytes()).hexdigest()
    uthmani_verses = parse_tanzil_file(uthmani_path)
    simple_verses = parse_tanzil_file(simple_path)
    metadata = json.loads(meta_path.read_text(encoding="utf-8"))

    if len(uthmani_verses) != 6236 or len(simple_verses) != 6236:
        raise RuntimeError(
            f"Nombre de versets invalide : uthmani={len(uthmani_verses)}, simple={len(simple_verses)} (attendu: 6236)"
        )

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    try:
        conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))

        with conn:
            conn.execute("DELETE FROM ayah_fts;")
            conn.execute("DELETE FROM ayah;")
            conn.execute("DELETE FROM surah;")

            conn.executemany(
                "INSERT OR REPLACE INTO meta(key, value) VALUES (?, ?);",
                [
                    ("schema_version", "1"),
                    ("quran_text_source", "Tanzil Quran Text (Uthmani v1.1)"),
                    ("quran_text_license", "CC BY 3.0 (http://tanzil.net)"),
                    ("quran_text_sha256", sha256_hex),
                    ("content_version", "2026.11"),
                ],
            )

            for s in metadata["surahs"]:
                conn.execute(
                    """
                    INSERT INTO surah(
                        id, name_ar, name_translit, name_fr, name_en,
                        revelation_type, revelation_order, ayah_count, has_bismillah
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                    """,
                    (s[0], s[1].strip(), s[2], s[3], s[4], s[5], s[6], s[7], s[8]),
                )

            juz_starts = [tuple(x) for x in metadata["juz_starts"]]
            manzil_starts = [tuple(x) for x in metadata["manzil_starts"]]
            sajda_map = {(x[0], x[1]): x[2] for x in metadata["sajdas"]}

            def current_index(starts: list[tuple[int, int]], s_id: int, a_num: int) -> int:
                idx = 1
                for i, (st_s, st_a) in enumerate(starts, start=1):
                    if (s_id, a_num) >= (st_s, st_a):
                        idx = i
                return idx

            global_id = 0
            for s in metadata["surahs"]:
                surah_id, ayah_count = s[0], s[7]
                for ayah_num in range(1, ayah_count + 1):
                    global_id += 1
                    u_text = uthmani_verses[(surah_id, ayah_num)]
                    s_text = simple_verses[(surah_id, ayah_num)]
                    juz = current_index(juz_starts, surah_id, ayah_num)
                    manzil = current_index(manzil_starts, surah_id, ayah_num)
                    hizb_quarter = min(240, max(1, ((global_id - 1) * 240) // 6236 + 1))
                    page_15 = min(604, max(1, ((global_id - 1) * 604) // 6236 + 1))
                    sajda_type = sajda_map.get((surah_id, ayah_num))

                    conn.execute(
                        """
                        INSERT INTO ayah(
                            id, surah_id, ayah_number, text_uthmani, text_simple,
                            juz, hizb_quarter, manzil, ruku, page_15, sajda_type
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                        """,
                        (
                            global_id,
                            surah_id,
                            ayah_num,
                            u_text,
                            s_text,
                            juz,
                            hizb_quarter,
                            manzil,
                            None,
                            page_15,
                            sajda_type,
                        ),
                    )

            conn.execute("INSERT INTO ayah_fts(rowid, text_simple) SELECT id, text_simple FROM ayah;")
        print(f"[OK] 114 sourates et {global_id} versets importés dans {DB_PATH}")
        print(f"[OK] SHA-256 enregistré : {sha256_hex}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
