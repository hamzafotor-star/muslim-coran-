#!/usr/bin/env python3
"""
tools/import_cities.py
======================
Importe les villes dans la table `city` de `assets/db/quran.db` pour le calcul
100 % hors ligne des horaires de prière et de la Qibla.

- Si `tools/sources/cities15000.txt` (GeoNames CC BY 4.0) est présent, l'importe.
- Sinon, s'arrête avec un message explicite indiquant où le télécharger
  (`https://download.geonames.org/export/dump/cities15000.zip`, licence CC BY 4.0),
  sauf si l'option `--fallback-reference` est passée pour insérer le sous-ensemble
  vérifié Afrique de l'Ouest + villes saintes + grandes métropoles mondiales.
"""

import pathlib
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES_DIR = ROOT / "tools" / "sources"
DB_PATH = ROOT / "assets" / "db" / "quran.db"

REFERENCE_CITIES = [
    # Villes d'Afrique de l'Ouest & Centrale (cible prioritaire §1)
    (2357048, "Ouagadougou", "Ouagadougou", "BF", "Centre", 12.3714, -1.5197, "Africa/Ouagadougou", 2453496),
    (2361845, "Bobo-Dioulasso", "Bobo-Dioulasso", "BF", "Hauts-Bassins", 11.1771, -4.2979, "Africa/Ouagadougou", 903887),
    (2358695, "Koudougou", "Koudougou", "BF", "Centre-Ouest", 12.2526, -2.3627, "Africa/Ouagadougou", 160207),
    (2356458, "Ouahigouya", "Ouahigouya", "BF", "Nord", 13.5828, -2.4216, "Africa/Ouagadougou", 124580),
    (2293538, "Abidjan", "Abidjan", "CI", "Abidjan", 5.3599, -4.0083, "Africa/Abidjan", 4980000),
    (2290987, "Bouaké", "Bouake", "CI", "Vallée du Bandama", 7.6939, -5.0303, "Africa/Abidjan", 680000),
    (2253354, "Dakar", "Dakar", "SN", "Dakar", 14.6928, -17.4467, "Africa/Dakar", 3137196),
    (2244990, "Touba", "Touba", "SN", "Diourbel", 14.8500, -15.8833, "Africa/Dakar", 753315),
    (2460596, "Bamako", "Bamako", "ML", "Bamako", 12.6392, -8.0029, "Africa/Bamako", 2529300),
    (2449938, "Tombouctou", "Tombouctou", "ML", "Tombouctou", 16.7735, -3.0074, "Africa/Bamako", 54453),
    (2440485, "Niamey", "Niamey", "NE", "Niamey", 13.5137, 2.1098, "Africa/Niamey", 1334984),
    (2447416, "Zinder", "Zinder", "NE", "Zinder", 13.8072, 8.9881, "Africa/Niamey", 322935),
    (2420477, "Conakry", "Conakry", "GN", "Conakry", 9.5370, -13.6785, "Africa/Conakry", 1931184),
    (2392087, "Cotonou", "Cotonou", "BJ", "Littoral", 6.3654, 2.4183, "Africa/Porto-Novo", 679012),
    (2365267, "Lomé", "Lome", "TG", "Maritime", 6.1375, 1.2123, "Africa/Lome", 1827878),
    (2377457, "Nouakchott", "Nouakchott", "MR", "Nouakchott", 18.0735, -15.9582, "Africa/Nouakchott", 1315000),
    (2332459, "Lagos", "Lagos", "NG", "Lagos", 6.4541, 3.3947, "Africa/Lagos", 15388000),
    (2335204, "Kano", "Kano", "NG", "Kano", 12.0022, 8.5920, "Africa/Lagos", 4103000),
    (2306104, "Accra", "Accra", "GH", "Greater Accra", 5.6037, -0.1870, "Africa/Accra", 2557000),
    (2232593, "Douala", "Douala", "CM", "Littoral", 4.0511, 9.7679, "Africa/Douala", 3663000),
    (2427123, "N'Djamena", "NDjamena", "TD", "N'Djamena", 12.1348, 15.0557, "Africa/Ndjamena", 1605696),
    # Villes Saintes & Maghreb / Moyen-Orient / Europe / Monde
    (104515, "La Mecque (Makkah)", "Makkah", "SA", "Makkah", 21.4225, 39.8262, "Asia/Riyadh", 2042000),
    (109223, "Médine (Al-Madinah)", "Madinah", "SA", "Al Madinah", 24.4686, 39.6142, "Asia/Riyadh", 1488782),
    (2553604, "Casablanca", "Casablanca", "MA", "Casablanca-Settat", 33.5731, -7.5898, "Africa/Casablanca", 3752000),
    (2538475, "Rabat", "Rabat", "MA", "Rabat-Salé-Kénitra", 34.0209, -6.8416, "Africa/Casablanca", 1932000),
    (2507480, "Alger", "Algiers", "DZ", "Alger", 36.7538, 3.0588, "Africa/Algiers", 2854000),
    (2464470, "Tunis", "Tunis", "TN", "Tunis", 36.8065, 10.1815, "Africa/Tunis", 2404000),
    (360630, "Le Caire", "Cairo", "EG", "Cairo", 30.0444, 31.2357, "Africa/Cairo", 21322750),
    (745044, "Istanbul", "Istanbul", "TR", "Istanbul", 41.0082, 28.9784, "Europe/Istanbul", 15462452),
    (2988507, "Paris", "Paris", "FR", "Île-de-France", 48.8566, 2.3522, "Europe/Paris", 2148271),
    (2996944, "Lyon", "Lyon", "FR", "Auvergne-Rhône-Alpes", 45.7640, 4.8357, "Europe/Paris", 522969),
    (2995469, "Marseille", "Marseille", "FR", "Provence-Alpes-Côte d'Azur", 43.2965, 5.3698, "Europe/Paris", 870731),
    (2800866, "Bruxelles", "Brussels", "BE", "Brussels", 50.8503, 4.3517, "Europe/Brussels", 1218255),
    (2643743, "Londres", "London", "GB", "England", 51.5074, -0.1278, "Europe/London", 8982000),
    (6077243, "Montréal", "Montreal", "CA", "Quebec", 45.5017, -73.5673, "America/Toronto", 1780000),
    (5128581, "New York", "New York", "US", "New York", 40.7128, -74.0060, "America/New_York", 8336817),
]


def main() -> None:
    geonames_path = SOURCES_DIR / "cities15000.txt"
    use_fallback = "--fallback-reference" in sys.argv

    if not geonames_path.exists() and not use_fallback:
        print(
            "[ERREUR] Fichier GeoNames 'tools/sources/cities15000.txt' absent.\n"
            "  -> Où le télécharger : https://download.geonames.org/export/dump/cities15000.zip\n"
            "  -> Licence : Creative Commons Attribution 4.0 (CC BY 4.0 - GeoNames.org)\n"
            "  -> Ou relancez avec '--fallback-reference' pour charger le sous-ensemble Afrique de l'Ouest + Villes Saintes + Monde.",
            file=sys.stderr,
        )
        sys.exit(1)

    conn = sqlite3.connect(str(DB_PATH))
    try:
        with conn:
            conn.execute("DELETE FROM city;")
            if geonames_path.exists():
                count = 0
                for line in geonames_path.read_text(encoding="utf-8").splitlines():
                    if not line or line.startswith("#"):
                        continue
                    cols = line.split("\t")
                    if len(cols) < 18:
                        continue
                    conn.execute(
                        """
                        INSERT OR REPLACE INTO city(
                            id, name, name_ascii, country, admin1, latitude, longitude, timezone, population
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                        """,
                        (
                            int(cols[0]),
                            cols[1],
                            cols[2] or cols[1],
                            cols[8],
                            cols[10],
                            float(cols[4]),
                            float(cols[5]),
                            cols[17],
                            int(cols[14] or 0),
                        ),
                    )
                    count += 1
                print(f"[OK] {count} villes GeoNames importées depuis {geonames_path.name}.")
            else:
                conn.executemany(
                    """
                    INSERT INTO city(
                        id, name, name_ascii, country, admin1, latitude, longitude, timezone, population
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                    """,
                    REFERENCE_CITIES,
                )
                print(f"[OK] {len(REFERENCE_CITIES)} villes de référence (Afrique de l'Ouest, Villes Saintes, Monde) importées.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
