# Muslim Coran — Application Mobile (MVP v1.0)

Application mobile Android (Flutter / Dart) légère (`< 60 Mo`), rapide et **100 % fonctionnelle hors ligne** permettant de :
- **Lire le Saint Coran** (114 sourates, 6 236 versets, texte Uthmani vérifié par somme de contrôle SHA-256, navigation par Sourate, Juz' et Page, polices arabes OFL réglables, thèmes Clair / Sombre / Sépia).
- **Lire les traductions** (Français *Muhammad Hamidullah* par défaut, translittération / Anglais).
- **Rechercher hors ligne** en arabe (avec ou sans voyelles grâce à la normalisation des diacritiques et SQLite FTS5) et dans les traductions.
- **Marquer et annoter** ses versets (Signets, Notes personnelles, Historique et reprise automatique de la dernière lecture).
- **Calculer les horaires de prière 100 % en local** (Fajr, Chourouk, Dhuhr, Asr, Maghrib, Isha + Imsak/Iftar pendant le Ramadan) selon les méthodes `MWL`, `UOIF`, `UmmAlQura`, `Egyptian`, `ISNA`, avec base de villes hors ligne.
- **Recevoir l'Adhan** par alarmes exactes Android (`SCHEDULE_EXACT_ALARM`) avec guide d'optimisation batterie pour Xiaomi, Tecno, Infinix et Samsung.
- **Trouver la Qibla** par boussole temps réel (formule du grand cercle vers la Kaaba `21.4225° N, 39.8262° E`) et mode de repli sans capteur.
- **Écouter et télécharger les récitations audio** sourate par sourate en arrière-plan avec pause et reprise.

---

## 1. Prérequis

- **Flutter SDK** `>= 3.22.0` (Dart `>= 3.3.0`)
- **Android SDK** : `minSdkVersion 26` (Android 8.0) à `targetSdkVersion 35` (Android 15)
- **Python 3.10+** (ou **Node.js 22.5+ / 26+** avec `node:sqlite` intégré) pour exécuter les scripts de génération de `assets/db/quran.db`.

---

## 2. Génération de la Base de Données (`assets/db/quran.db`)

Les fichiers officiels Tanzil sont placés dans `tools/sources/` :
- `tools/sources/quran-uthmani.txt` (Texte Uthmani v1.1 — Tanzil Project)
- `tools/sources/quran-simple-clean.txt` (Texte Simple sans diacritiques — Tanzil Project)
- `tools/sources/fr.hamidullah.txt` (Traduction française — Muhammad Hamidullah)
- `tools/sources/en.transliteration.txt` (Translittération / Traduction anglaise)

### Exécution des scripts d'import (Python)
```bash
python tools/import_quran.py
python tools/import_translations.py
python tools/import_cities.py --fallback-reference
python tools/import_reciters.py
python tools/verify_quran_db.py
```

### Alternative directe avec Node.js (`node:sqlite` intégré, sans dépendance externe)
```bash
node tools/build_quran_db.mjs
```
Cette commande exécute la totalité du pipeline (`quran_schema.sql`, import des 114 sourates, des 6 236 versets Uthmani + Simple, calcul du `SHA-256`, import des traductions, des villes de référence et des 2 récitateurs, puis vérification automatique des 6 236 versets).

---

## 3. Commandes de Développement et de Test

```bash
# Récupérer les dépendances
flutter pub get

# Vérifier la qualité du code (0 warning)
flutter analyze

# Formater le code
dart format lib test

# Exécuter tous les tests unitaires et de widgets
flutter test
```

---

## 4. Build de Release (Google Play App Bundle)

1. Copiez `android/key.properties.example` vers `android/key.properties` (ce fichier est ignoré par Git) et renseignez le chemin de votre keystore personnel.
2. Lancez la compilation :
```bash
# App Bundle (.aab) pour Google Play
flutter build appbundle --release

# APK découpé par ABI (< 25 Mo par architecture)
flutter build apk --release --split-per-abi
```

---

## 5. Documentation de Référence (`docs/`)

- [Cahier des charges](docs/Cahier_des_charges_Muslim_Coran.md)
- [Cahier de maquettes (E01 à E18)](docs/Cahier_de_maquettes_Muslim_Coran.md)
- [Schéma SQLite complet](docs/schema_muslim_coran.sql)
- [Architecture technique](docs/ARCHITECTURE.md)
- [Licences des contenus, polices et bibliothèques](docs/LICENSES.md)
- [Questions & arbitrages documentaires](docs/QUESTIONS.md)
