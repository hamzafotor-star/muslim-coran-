# Prompt Antigravity — Muslim Coran (MVP v1.0)

## Avant de lancer
1. Créez un dossier de projet vide `muslim_coran/`.
2. Dans ce dossier, créez un sous-dossier `docs/` et placez-y ces 3 fichiers :
   - `Cahier_des_charges_Muslim_Coran.md`
   - `Cahier_de_maquettes_Muslim_Coran.md`
   - `schema_muslim_coran.sql`
3. Ouvrez le dossier dans Antigravity, choisissez le mode **Planning** (plan puis exécution), puis collez le prompt ci-dessous.

---

## PROMPT À COLLER

```
Tu es un ingénieur mobile senior (Flutter/Dart). Construis la PREMIÈRE VERSION (MVP) de l'application Android « Muslim Coran » dans ce dossier.

# 0. Documents de référence (à lire en premier, ils font autorité)
- docs/Cahier_des_charges_Muslim_Coran.md : périmètre, exigences, architecture, permissions.
- docs/Cahier_de_maquettes_Muslim_Coran.md : charte graphique et 18 écrans (E01 à E18).
- docs/schema_muslim_coran.sql : schéma SQLite (quran.db en lecture seule + user.db en lecture/écriture).
Lis les trois avant d'écrire du code. En cas de conflit, suis le cahier des charges, puis les maquettes, puis le schéma. Signale-moi tout conflit dans un fichier docs/QUESTIONS.md au lieu de deviner.

# 1. Objectif
Application mobile légère (< 60 Mo de base), rapide, 100 % utilisable hors ligne pour : lire le Coran, rechercher, marquer des versets, connaître les horaires de prière, recevoir l'Adhan, trouver la Qibla. Cible : smartphones Android d'entrée de gamme (2 Go de RAM, Android 8+, API 26), utilisateurs francophones et arabophones d'Afrique de l'Ouest.

# 2. Règles absolues (non négociables)
1. N'utilise AUCUN code, donnée, police, binaire ou ressource de l'application « Quran Majeed » ou de tout APK modifié. Écris tout toi-même.
2. N'ajoute AUCUN mécanisme de contournement de signature, d'obfuscation DEX-to-C, ni de hook (xhook, SignatureKiller…).
3. Le texte coranique ne doit JAMAIS être écrit de mémoire ni généré par toi. Il doit provenir d'un fichier source officiel importé par un script (voir §5). Si la source n'est pas disponible, utilise un jeu de DONNÉES DE TEST clairement marqué « TEST — NE PAS PUBLIER » (3 à 5 sourates courtes) et signale-le en tête du README.
4. Chaque traduction, récitateur et police doit avoir sa licence documentée dans docs/LICENSES.md.
5. Aucune publicité, aucun traceur, aucune analytique dans le MVP.
6. Permissions Android limitées à : ACCESS_COARSE_LOCATION, ACCESS_FINE_LOCATION, POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK, INTERNET, RECEIVE_BOOT_COMPLETED. Aucune autre (surtout pas INSTALL_PACKAGES, DUMP, RECORD_AUDIO).

# 3. Stack imposée
- Flutter (dernière version stable) + Dart, null-safety, Material 3.
- Gestion d'état : Riverpod (flutter_riverpod) avec génération de code si utile.
- Navigation : go_router.
- Base de données : SQLite via Drift (ou sqflite si Drift pose problème), 2 bases : quran.db (assets, copiée au 1er lancement, lecture seule) et user.db (créée à l'exécution). Reprends le schéma de docs/schema_muslim_coran.sql, découpé en deux fichiers de migration : `assets/db/quran_schema.sql` et `lib/data/user_schema.sql`.
- Recherche : FTS5 pour l'arabe sans voyelles et pour les traductions.
- Audio : just_audio + audio_service (lecture en arrière-plan, notification de contrôle).
- Horaires de prière : package `adhan` (Dart), calcul 100 % local.
- Position : geolocator ; villes hors ligne depuis la table `city`.
- Notifications et Adhan : flutter_local_notifications + alarmes exactes Android (zonedSchedule, `AndroidScheduleMode.exactAllowWhileIdle`), replanification après redémarrage (BOOT_COMPLETED).
- Boussole : flutter_compass ; angle de Qibla calculé avec la formule du grand cercle vers la Kaaba (21.4225° N, 39.8262° E).
- Téléchargements : dio avec reprise, stockage dans le dossier privé de l'app.
- Internationalisation : flutter_localizations + ARB (fr, ar, en). RTL géré pour l'arabe.
- Tests : flutter_test (unitaires), tests de widgets pour les écrans clés.
- Architecture : feature-first, couches data / domain / presentation. Pas de logique métier dans les widgets.

# 4. Périmètre du MVP (modules M1 à M8 uniquement)
Implémente UNIQUEMENT :
- M1 Lecture du Coran (E05, E06, E07 en option, E08)
- M2 Traductions (français d'abord, anglais ensuite)
- M3 Audio (E09, E17) : sourate par sourate, streaming + téléchargement, lecture en arrière-plan, surlignage du verset si les repères existent, répétition, vitesse, minuteur
- M4 Horaires de prière (E11, E12, E18)
- M5 Adhan et notifications
- M6 Qibla (E13)
- M7 Recherche (E10)
- M8 Signets, notes, dernière lecture (E14)
Plus les écrans transverses : E01 à E04, E15 (menu « Plus » avec les modules V1.x grisés « Bientôt »), E16.
NE PAS implémenter : tafsir, mémorisation, Khatma, Tasbih, calendrier hégirien, Qaida, widgets, reconnaissance vocale, compte cloud.

# 5. Données et import (à faire par script, pas à la main)
Crée un dossier `tools/` avec des scripts Dart ou Python documentés :
- `tools/import_quran.py` : lit un fichier texte Tanzil (texte uthmani + version simple) placé dans `tools/sources/`, remplit `surah`, `ayah` (juz', hizb, page, sajda), calcule la somme SHA-256 et l'écrit dans `meta.quran_text_sha256`. Génère `assets/db/quran.db`.
- `tools/import_translations.py` : importe une traduction française et une anglaise (formats Tanzil), remplit `translation`, `ayah_translation`, `translation_fts`, avec la licence.
- `tools/import_cities.py` : importe GeoNames `cities15000` (ou un sous-ensemble Afrique de l'Ouest + grandes villes mondiales + villes saintes) dans `city`.
- `tools/import_reciters.py` : renseigne `reciter` et `audio_file` pour 2 récitateurs depuis EveryAyah ou Quran.com (URL uniquement, pas de fichiers audio embarqués).
- Un test automatique qui vérifie : 114 sourates, 6 236 versets, somme de contrôle conforme, aucune ligne vide.
Si les fichiers sources manquent, le script doit s'arrêter avec un message clair indiquant où les télécharger et sous quelle licence. Ne télécharge rien sans que je le confirme.

# 6. Exigences fonctionnelles clés
- Au 1er lancement : E01 → E02 → E03 → E04. Permissions expliquées avant la demande système ; refus toléré (choix manuel de la ville).
- Lecteur : texte arabe avec police réglable (Amiri Quran + 2 autres polices OFL, embarquées avec leur licence), taille réglable, traduction masquable, basmala correcte (absente pour At-Tawba, intégrée pour Al-Fatiha), marqueurs de sajda, reprise automatique à la dernière position, partage d'un verset (texte avec sourate, numéro, source).
- Mode mushaf (E07) : à ne livrer que si une source de mise en page sous licence est présente ; sinon, masque l'option et documente-le.
- Recherche : arabe avec ou sans voyelles (normalisation des diacritiques), traduction, surlignage du mot, historique des recherches.
- Horaires : 6 moments, décompte en direct, méthodes MWL, UOIF, Umm al-Qura, Égypte, ISNA ; école Asr ; ajustements par prière (−30 à +30 min) ; Imsak et Iftar affichés pendant le Ramadan ; fuseau de la ville.
- Adhan : alarme exacte par prière, son choisi (embarque 1 Adhan libre de droits ou un son de notification neutre en attendant ; documente la source), rappel avant la prière, vibration, replanification automatique à minuit, au changement de lieu/réglage et après redémarrage. Prévoir l'écran « Optimisation batterie » avec guide pour Xiaomi, Tecno, Infinix, Samsung.
- Qibla : flèche en temps réel, indicateur de précision, avertissement d'interférence magnétique, mode de repli sans capteur.
- Signets : un par verset, étiquette optionnelle, notes, historique, suppression par glissement.
- Thèmes clair / sombre / sépia (couleurs de la charte des maquettes : #0F5132, #D1E7DD, #C9A227, fonds #FFFFFF / #121614 / #F4ECD8).
- Aucune icône figurative (pas de visages, de personnes, d'animaux).
- Textes de l'interface en français par défaut, avec fichiers ARB fr / ar / en.

# 7. Qualité et performance
- Démarrage < 2 s ; ouverture d'une sourate < 300 ms ; listes virtualisées (ListView.builder), requêtes SQL paginées.
- Pas de service permanent en arrière-plan : uniquement des alarmes planifiées + le service audio pendant la lecture.
- `flutter analyze` sans avertissement, formatage `dart format`.
- Tests unitaires obligatoires pour : normalisation arabe de la recherche, angle de Qibla (La Mecque ≈ 0 m, Ouagadougou ≈ 62–63° NE à vérifier), calcul des horaires sur 3 villes de référence contre une valeur attendue documentée, repositories signets/notes, replanification des alarmes.
- Build de release : `flutter build appbundle --release` avec signature via un keystore que je fournirai (ne génère pas de clé en dur dans le dépôt ; utilise key.properties ignoré par git). Active R8, supprime les ressources inutiles, découpe par ABI. Cible APK de base < 60 Mo.

# 8. Méthode de travail
1. PLAN d'abord : produis un plan en phases (voir §9), liste les fichiers à créer et les risques. Attends mon accord avant de coder.
2. Travaille phase par phase. À la fin de chaque phase : exécute `flutter analyze` et les tests, corrige, puis résume en 5 lignes ce qui est fait et ce qui reste.
3. Commits courts et fréquents, message à l'impératif en français.
4. Ne fabrique jamais de données religieuses ni de contenu de test présenté comme réel. Marque tout ce qui est factice.
5. Si une décision change l'architecture, demande-moi avant.

# 9. Phases
- Phase 0 : initialisation du projet, arborescence, thème, navigation, i18n, CI locale (analyze + test), docs/LICENSES.md, README.
- Phase 1 : base de données (quran.db + user.db), scripts d'import, dépôt de données, E05, E06, E08, E10, E14, E04 (partiel).
- Phase 2 : localisation, E18, horaires E11/E12, Adhan et alarmes exactes, E13 Qibla, E03.
- Phase 3 : audio E09 et téléchargements E17.
- Phase 4 : E01, E02, E15, E16, finitions RTL, accessibilité (TalkBack, tailles de texte), états vides / erreur / hors ligne.
- Phase 5 : tests, optimisation de taille et de performance, guide de publication Play Store (fiche, politique de confidentialité à générer dans docs/).

# 10. Livrables attendus
- Projet Flutter complet qui compile et se lance sur émulateur Android (API 26 à 35).
- Scripts d'import + base `quran.db` générée si les sources sont présentes.
- README (installation, commandes, import des données, build).
- docs/LICENSES.md, docs/QUESTIONS.md, docs/ARCHITECTURE.md (1 page).
- Rapport final : ce qui est livré, ce qui manque (sources de données, Adhan, mushaf), risques.

Commence par la lecture des 3 documents, puis donne-moi le plan de la Phase 0 à 5 pour validation.
```

---

## Conseils d'utilisation
- **Une phase à la fois.** Après validation du plan, dites « Exécute la Phase 0 », puis la suivante. Un seul gros prompt « fais tout » donne un résultat fragile.
- **Données à préparer vous-même :** fichiers Tanzil (texte et traductions), liste GeoNames, un Adhan libre de droits. L'agent ne doit pas les inventer.
- **Test réel :** essayez les alarmes sur un vrai téléphone (Tecno, Infinix, Xiaomi), c'est là que les problèmes apparaissent.
- **Avant publication :** faites relire le texte et les traductions par une personne compétente.
