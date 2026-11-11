# Questions, Conflits Documentaires & Points d'Arbitrage — Muslim Coran (MVP)

Ce document recense les conflits et ambiguïtés identifiés lors de la lecture croisée des trois documents de référence :
1. `Cahier_des_charges_Muslim_Coran.md` (Priorité 1)
2. `Cahier_de_maquettes_Muslim_Coran.md` (Priorité 2)
3. `schema_muslim_coran.sql` (Priorité 3)
ainsi que l'état actuel des fichiers sources présents dans le dépôt.

---

## 1. Conflits entre les 3 documents de référence

### Q1 — Schéma de données simplifié (§6.3 Cahier des charges) vs Double base SQLite (`schema_muslim_coran.sql`)
- **Constat :** Le §6.3 du *Cahier des charges* présente un schéma simplifié à 8 tables (`ayah.text_ar`, `bookmark.note`, `reading_progress`), tandis que `schema_muslim_coran.sql` et le §3 de vos instructions imposent **deux bases distinctes** (`quran.db` en lecture seule et `user.db` en lecture/écriture) avec des tables et colonnes plus riches (`text_uthmani`, `text_simple`, `hizb_quarter`, `page_15`, `sajda_type`, tables séparées `bookmark` et `note`, `reading_position` + `reading_history`).
- **Résolution appliquée par défaut :** Utilisation stricte de `schema_muslim_coran.sql`, découpé en `assets/db/quran_schema.sql` et `lib/data/user_schema.sql`.

### Q2 — Navigation à 5 onglets vs Accès au Tableau de bord (E04)
- **Constat :** La charte des maquettes (§0 et bas des écrans E04, E05, E14) définit 5 onglets dans la barre de navigation inférieure : **`Coran · Prières · Qibla · Signets · Plus`**. Or l'écran **E04 (Accueil / Tableau de bord)** n'a pas d'onglet dédié dans cette barre à 5 entrées (l'onglet « Coran » correspond à E05 — Liste des sourates).
- **Options d'arbitrage :**
  - **Option A (recommandée) :** Conserver les 5 onglets exacts (`Coran · Prières · Qibla · Signets · Plus`), ouvrir l'application sur **E04**, et permettre de revenir à **E04** via une icône « Accueil » dans l'AppBar des onglets (ou afficher le tableau de bord E04 en en-tête repliable de l'onglet Coran).
  - **Option B :** Remplacer l'onglet « Signets » de la barre du bas par « Accueil » (`Accueil · Coran · Prières · Qibla · Plus`) et rendre **E14 (Signets)** accessible depuis E04, E05 et E15.
- **Question :** Quelle option préférez-vous (A ou B) ?

### Q3 — Gestion de la Basmala dans `quran-uthmani.txt` (E06 & Licence Tanzil)
- **Constat :**
  - Dans les fichiers `quran-uthmani.txt` et `quran-simple.txt` présents dans le dossier, Tanzil inclut la Basmala au début du texte du verset 1 de chaque sourate (ex. `2|1|بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ الٓمٓ`), sauf pour la sourate 9 (*At-Tawba*) où elle est absente et la sourate 1 (*Al-Fâtiha*) où elle constitue l'intégralité du verset 1.
  - La maquette **E06** affiche la Basmala dans un bandeau supérieur dédié avant la carte du verset 1 (`الٓمٓ`).
  - La licence Tanzil interdit de modifier le texte coranique distribué, mais si l'on affiche le bandeau Basmala **et** le verset `2:1` tel quel, la Basmala apparaîtra deux fois.
- **Résolution proposée :**
  - Conserver le texte Tanzil **strictement intact** dans `quran.db` (pour que la somme de contrôle `meta.quran_text_sha256` corresponde exactement au texte officiel Tanzil sans altération), et retirer visuellement le préfixe de la Basmala du verset 1 (pour les sourates 2 à 114 hors sourate 9) **uniquement au moment du rendu dans le widget E06** lorsque le bandeau Basmala séparé est affiché. Confirmez-vous ce choix ?

### Q4 — Partage de verset en image (RF-05, E08) vs Périmètre MVP
- **Constat :** Le *Cahier des charges* (RF-05) et la maquette **E08** mentionnent « Partager (texte) » et « Partager (image) », tandis que vos instructions (§6) précisent : *« partage d'un verset (texte avec sourate, numéro, source) »*.
- **Proposition :** Implémenter en priorité le partage texte formaté (`share_plus`) et la copie presse-papiers, ainsi qu'un générateur de carte image sobre (`RepaintBoundary` → PNG) depuis E08.

---

## 2. Questions sur les fichiers sources présents dans le dossier

### Q5 — Traduction anglaise manquante (`en.transliteration.txt` vs Traduction EN)
- **Constat :** Le dossier racine contient actuellement :
  - `quran-uthmani.txt`, `quran-uthmani-min.txt`, `quran-simple.txt`, `quran-simple-clean.txt`, `quran-simple-min.txt`, `quran-simple-plain.txt`
  - `fr.hamidullah.txt` (Traduction française — Muhammad Hamidullah)
  - `en.transliteration.txt` (Translittération phonétique anglaise contenant des balises HTML `<u>`, `<b>`, `<i>`, et non une traduction en langue anglaise).
- **Question :** Souhaitez-vous ajouter un fichier de traduction anglaise Tanzil (ex. `en.sahih.txt` ou `en.yusufali.txt`) dans `tools/sources/`, ou devons-nous importer `en.transliteration.txt` (nettoyé de ses balises HTML) en tant que second texte pour le MVP ?

### Q6 — Fichier source des villes (`cities15000`)
- **Constat :** Aucun fichier GeoNames (`cities15000.txt`) n'est présent dans le dossier pour le moment.
- **Proposition :** Conformément au §5 (*« Si les fichiers sources manquent, le script doit s'arrêter avec un message clair indiquant où les télécharger et sous quelle licence. Ne télécharge rien sans que je le confirme »*), `tools/import_cities.py` vérifiera la présence de `tools/sources/cities15000.txt` (ou d'un fichier CSV/TSV de villes Afrique de l'Ouest + grandes villes mondiales + La Mecque/Médine) et affichera les instructions exactes si absent, tout en permettant un jeu de villes de référence documenté pour les tests unitaires obligatoires (Ouagadougou, Bobo-Dioulasso, Abidjan, Dakar, Bamako, Niamey, Paris, La Mecque, Médine).

### Q7 — Mode Mushaf (E07)
- **Constat :** Aucune base de lignes/mots KFGQPC (`word`, `mushaf_line`) ni police par page n'est présente dans les sources actuelles.
- **Résolution appliquée (conforme au §6) :** L'écran E07 et le sélecteur de mode Mushaf seront masqués dans l'interface MVP et documentés dans `README.md` et `docs/ARCHITECTURE.md` jusqu'à fourniture d'une source KFGQPC sous licence. (La navigation par numéro de page `1..604` dans l'onglet « Pages » de E05 restera active et ouvrira le lecteur en mode verset E06 au début de la page correspondante).

---

## 3. Environnement technique & Permissions

### Q8 — Installation de Flutter SDK et Python sur votre poste Windows
- **Constat :** Les commandes `flutter`, `dart` et `python` ne sont pas encore accessibles dans le `PATH` système de cette session PowerShell (seuls `git`, `node` et `java` JRE 21 sont détectés).
- **Question :**
  1. Avez-vous déjà installé le SDK Flutter et Python dans un répertoire spécifique sur votre disque (ex. `C:\src\flutter`, `D:\flutter`, etc.) ? Si oui, indiquez-moi leurs chemins.
  2. Pour les scripts de `tools/` (`import_quran`, `import_translations`, `import_cities`, `import_reciters`), souhaitez-vous conserver les scripts `.py` en Python (avec un équivalent exécutable ou l'installation de Python/SQLite) ?

### Q9 — Permission `VIBRATE` pour la boussole Qibla (E13) et l'Adhan (E12)
- **Constat :** Le §2.6 limite strictement le `AndroidManifest.xml` à 8 permissions (`ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `INTERNET`, `RECEIVE_BOOT_COMPLETED`).
- **Résolution proposée :** Respecter strictement cette liste de 8 permissions dans `AndroidManifest.xml` et utiliser `HapticFeedback.lightImpact()` (qui ne requiert pas la permission `VIBRATE` sur Android) pour l'alignement Qibla (E13) ainsi que le comportement natif du canal de notification pour l'Adhan.
