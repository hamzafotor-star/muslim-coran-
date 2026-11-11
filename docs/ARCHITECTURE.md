# Architecture Technique — Muslim Coran (MVP)

## 1. Principes Directeurs
- **100 % Hors Ligne par défaut :** Lecture du Coran, recherche plein texte FTS5 (arabe & traductions), calcul astronomique des prières, boussole Qibla, signets et notes fonctionnent sans aucune connexion Internet.
- **Séparation stricte des bases SQLite :**
  1. **`quran.db` (Lecture seule, copiée depuis `assets/db/quran.db`)** : Contient le texte coranique Uthmani et Simple (`surah`, `ayah`), les traductions (`translation`, `ayah_translation`), les index plein texte (`ayah_fts`, `translation_fts`), le catalogue des récitateurs (`reciter`, `audio_file`, `audio_timing`) et la base des villes GeoNames (`city`). Son intégrité est protégée par la somme SHA-256 stockée dans `meta.quran_text_sha256`.
  2. **`user.db` (Lecture/Écriture, créée sur l'appareil)** : Contient les préférences (`settings`), signets (`bookmark`), notes (`note`), la position courante (`reading_position`), l'historique (`reading_history`), les profils géographiques (`location_profile`), les paramètres de prière (`prayer_settings`), les alarmes (`prayer_alarm`) et l'état des téléchargements (`download`).
- **Architecture `Feature-First` en 3 couches (`data` / `domain` / `presentation`) :** Aucune logique métier ni requête SQL dans les widgets Flutter.

---

## 2. Arborescence du Code (`lib/` & `tools/`)

```text
MUSLIM CORAN/
├── assets/
│   ├── db/                 # quran_schema.sql + quran.db générée par les scripts
│   ├── audio/              # Son d'alerte Adhan libre de droits (CC0)
│   └── fonts/              # Polices arabes OFL (AmiriQuran, ScheherazadeNew, Lateef)
├── docs/                   # Cahier des charges, Maquettes, Schéma, Licences, Questions
├── tools/                  # Pipeline d'import reproductible (Python & Node SQLite)
│   ├── sources/            # Fichiers officiels Tanzil (.txt) et métadonnées
│   ├── import_quran.py
│   ├── import_translations.py
│   ├── import_cities.py
│   ├── import_reciters.py
│   └── verify_quran_db.py
└── lib/
    ├── main.dart           # Point d'entrée et ProviderScope Riverpod
    ├── app.dart            # MaterialApp.router, thèmes Clair/Sombre/Sépia, i18n RTL
    ├── l10n/               # Fichiers ARB (fr, ar, en) et classe AppLocalizations
    ├── data/
    │   └── user_schema.sql # Schéma de migration de user.db
    ├── core/
    │   ├── database/       # Initialisation quran.db (RO) & user.db (RW) + contrôle SHA-256
    │   ├── router/         # Configuration go_router (E01 à E18)
    │   ├── theme/          # Charte graphique (#0F5132, #D1E7DD, #C9A227, Sépia #F4ECD8)
    │   └── widgets/        # Barre de navigation 5 onglets, cartes sobres sans icône figurative
    └── features/
        ├── onboarding/     # E01 (Splash), E02 (Bienvenue), E03 (Permissions)
        ├── home/           # E04 (Tableau de bord : prochaine prière, reprise, verset du jour)
        ├── quran/          # M1/M2 : E05 (Sourates/Juz/Pages), E06 (Lecteur verset), E08 (Menu)
        ├── search/         # M7 : E10 (Recherche FTS5 + normalisation arabe sans voyelles)
        ├── bookmarks/      # M8 : E14 (Signets, Notes personnelles, Historique)
        ├── prayer/         # M4/M5 : E11 (Horaires), E12 (Réglages & Batterie), E18 (Villes)
        ├── qibla/          # M6 : E13 (Boussole grand cercle, détection d'interférences)
        ├── audio/          # M3 : E09 (Mini-lecteur & lecteur plein écran, audio_service)
        ├── downloads/      # M3 : E17 (Téléchargements Dio avec pause/reprise)
        ├── more/           # E15 (Menu Plus avec modules V1.x marqués « Bientôt »)
        └── settings/       # E16 (Réglages d'affichage, langue, polices, confidentialité)
```

---

## 3. Sécurité, Confidentialité et Conformité Google Play
- **8 permissions Android uniquement :** `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `INTERNET`, `RECEIVE_BOOT_COMPLETED`.
- **Zéro service permanent inutile :** Les horaires d'Adhan reposent sur les alarmes exactes du système Android (`exactAllowWhileIdle`) reprogrammées à minuit et au démarrage (`BOOT_COMPLETED`). Le service de premier plan n'est actif que pendant l'écoute audio du Coran.
