#!/usr/bin/env python3
"""
tools/import_reciters.py
========================
Renseigne les tables `reciter` et `audio_file` dans `assets/db/quran.db` pour
2 récitateurs (URLs uniquement, aucun fichier audio lourd embarqué dans l'APK) :
1. Mishary Rashid Al-Afasy (Murattal, par défaut)
2. Mahmoud Khalil Al-Husary (Murattal)
"""

import pathlib
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "assets" / "db" / "quran.db"

RECITERS = [
    (
        1,
        "Mishary Rashid Al-Afasy",
        "Murattal",
        "https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/",
        "Usage personnel et non commercial gratuit — Source : QuranicAudio.com / EveryAyah.com",
        1,
    ),
    (
        2,
        "Mahmoud Khalil Al-Husary",
        "Murattal",
        "https://download.quranicaudio.com/quran/mahmood_khaleel_al-husaree/",
        "Usage personnel et éducatif gratuit — Source : QuranicAudio.com / EveryAyah.com",
        0,
    ),
]


def main() -> None:
    if not DB_PATH.exists():
        print("[ERREUR] Base quran.db absente. Exécutez d'abord tools/import_quran.py.", file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(str(DB_PATH))
    try:
        with conn:
            conn.execute("DELETE FROM audio_timing;")
            conn.execute("DELETE FROM audio_file;")
            conn.execute("DELETE FROM reciter;")

            conn.executemany(
                "INSERT INTO reciter(id, name, style, base_url, license, is_default) VALUES (?, ?, ?, ?, ?, ?);",
                RECITERS,
            )

            audio_id = 0
            for reciter_id, _, _, base_url, _, _ in RECITERS:
                for surah_id in range(1, 115):
                    audio_id += 1
                    file_name = f"{surah_id:03d}.mp3"
                    url = f"{base_url}{file_name}"
                    conn.execute(
                        """
                        INSERT INTO audio_file(id, reciter_id, surah_id, ayah_id, url, size_bytes, duration_ms)
                        VALUES (?, ?, ?, NULL, ?, NULL, NULL);
                        """,
                        (audio_id, reciter_id, surah_id, url),
                    )
        print(f"[OK] 2 récitateurs et {audio_id} URLs de sourates renseignés dans {DB_PATH.name}.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
