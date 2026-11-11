# Cahier des charges — Application « Muslim Coran »

Version 1.0 — Novembre 2026

---

## 1. Présentation du projet

**Nom :** Muslim Coran
**Type :** Application mobile (Android en priorité, iOS ensuite)
**Objectif :** Offrir aux musulmans une application complète, légère et fiable pour lire le Coran, connaître les horaires de prière, trouver la Qibla et suivre leur pratique quotidienne, avec un fonctionnement hors ligne.

**Cibles :** musulmans francophones et arabophones d'Afrique de l'Ouest et du monde (connexions limitées, smartphones d'entrée de gamme), puis anglophones.

**Positionnement :** une application légère (< 60 Mo), rapide, sans publicité intrusive, avec des textes sacrés fidèles et vérifiés.

---

## 2. Cadre juridique et éthique (obligatoire)

L'analyse fournie porte sur un APK **piraté et re-signé** de Quran Majeed. Il sert uniquement de référence pour la liste des fonctionnalités. Il faut respecter ces règles :

- **Ne réutiliser aucun code, ressource, base de données, police ou binaire** de Quran Majeed (`libQuranData1.so`, `libPrayerTime.so`, polices, traductions, etc.). Ils sont protégés par le droit d'auteur de leur éditeur.
- **Ne jamais intégrer** de mécanisme de contournement de signature (SignatureKiller, xhook, etc.). Il est illégal et fait passer l'application pour un malware (refus Google Play, Play Protect).
- **Sources de contenu légitimes à utiliser :**
  - Texte coranique : Tanzil.net (licence à respecter, texte non modifié, mention de la source) ou Quran.com API / Quran Foundation
  - Mushaf et polices : KFGQPC (Complexe du Roi Fahd), polices Amiri Quran, Scheherazade New (licence OFL)
  - Traductions et tafsir : sources avec licence libre ou autorisation écrite (Tanzil, Quran.com, Tafsir Ibn Kathir / Jalalayn selon licence)
  - Récitations audio : EveryAyah.com, Quran.com audio ou accord direct avec les récitateurs
  - Horaires de prière : calcul local avec la bibliothèque open source **Adhan** (Android/iOS), ou l'API Aladhan
- **Vérification religieuse :** faire relire le texte coranique, les traductions et les invocations par un savant ou une institution reconnue avant publication.
- **Protection des données :** politique de confidentialité claire, consentement pour la localisation, aucune revente de données.

---

## 3. Périmètre fonctionnel

### 3.1 Modules du MVP (version 1.0)

| # | Module | Description | Priorité |
|---|--------|-------------|----------|
| M1 | **Lecture du Coran** | Texte arabe complet, 114 sourates, navigation par sourate, juz', hizb et page. Mode mushaf (page) et mode liste (verset par verset). Police réglable, mode nuit. | Haute |
| M2 | **Traductions** | Français en priorité, puis anglais, plus une langue locale (mooré, dioula) si une source valide existe. Affichage verset par verset. | Haute |
| M3 | **Audio** | Récitation sourate par sourate ou verset par verset, plusieurs récitateurs, lecture en arrière-plan, téléchargement hors ligne, répétition de verset. | Haute |
| M4 | **Horaires de prière** | Calcul selon la position (GPS ou ville choisie), plusieurs méthodes de calcul (MWL, UOIF, Umm al-Qura, etc.), ajustements manuels. | Haute |
| M5 | **Adhan et notifications** | Alarmes exactes pour chaque prière, choix de l'Adhan, rappel avant la prière, fonctionnement après redémarrage du téléphone. | Haute |
| M6 | **Qibla** | Boussole utilisant le capteur du téléphone et le calcul d'angle vers la Kaaba, avec calibration. | Haute |
| M7 | **Recherche** | Recherche dans le texte arabe (avec ou sans voyelles) et dans les traductions. | Haute |
| M8 | **Marque-pages et dernière lecture** | Reprise automatique, signets, notes personnelles. | Haute |

### 3.2 Modules de la version 1.x (évolutions)

| # | Module | Description |
|---|--------|-------------|
| M9 | **Tafsir** | Explications des versets, hors ligne. |
| M10 | **Mémorisation (Hifz)** | Suivi de mémorisation, révision espacée, répétition audio d'un passage. |
| M11 | **Objectifs de lecture (Khatma)** | Plan de lecture (30 jours, Ramadan), progression, rappels. |
| M12 | **Tasbih / Dhikr** | Compteur numérique, invocations du matin et du soir (Hisn al-Muslim). |
| M13 | **Calendrier hégirien** | Dates islamiques, fêtes, jours blancs, jeûne. |
| M14 | **Qaida Noorania / apprentissage** | Leçons d'apprentissage de l'arabe coranique pour débutants. |
| M15 | **Widgets** | Widget Android avec prochaine prière. |
| M16 | **Noms d'Allah, invocations** | Contenu éducatif avec audio. |
| M17 | **Reconnaissance de récitation** | Outil de correction de récitation (phase de R&D, optionnelle). |

---

## 4. Exigences fonctionnelles détaillées

### 4.1 Lecture du Coran
- RF-01 : Afficher la basmala et les marqueurs de verset conformément au mushaf choisi.
- RF-02 : Surligner le verset en cours de lecture audio.
- RF-03 : Choix de la taille et de la police arabe (minimum 3 polices).
- RF-04 : Indicateurs de sajda (prosternation) et de pause (waqf).
- RF-05 : Partage d'un verset (texte, image, lien) avec source et numéro.
- RF-06 : Mode lecture continue avec défilement fluide.

### 4.2 Horaires de prière
- RF-07 : Calcul 100 % local (hors ligne) après sélection de la position.
- RF-08 : Prières affichées : Fajr, Chourouk, Dhuhr, Asr, Maghrib, Isha.
- RF-09 : Décompte jusqu'à la prochaine prière.
- RF-10 : Prise en charge de l'heure d'été et des fuseaux, ajustement des minutes par prière.
- RF-11 : Mode jeûne : affichage Imsak et Iftar pendant le Ramadan.

### 4.3 Qibla
- RF-12 : Direction de la Kaaba via le magnétomètre, avec indication de précision.
- RF-13 : Message d'avertissement en cas d'interférences magnétiques.

### 4.4 Paramètres et compte
- RF-14 : Langue de l'interface : français, arabe, anglais (RTL géré correctement).
- RF-15 : Thème clair, sombre et sépia.
- RF-16 : Compte optionnel pour sauvegarder signets et progression dans le cloud.
- RF-17 : Utilisation complète sans compte ni connexion permanente.

---

## 5. Exigences non fonctionnelles

| Domaine | Exigence |
|---------|----------|
| **Performance** | Démarrage < 2 s sur un téléphone d'entrée de gamme (2 Go de RAM). Ouverture d'une sourate < 300 ms. |
| **Poids** | APK de base < 60 Mo. Audio et traductions supplémentaires téléchargeables à la demande. |
| **Hors ligne** | Lecture, horaires, Qibla et recherche accessibles sans internet. |
| **Compatibilité** | Android 8.0+ (API 26) minimum, adaptation aux petits écrans et tablettes. |
| **Accessibilité** | Taille de texte réglable, contraste suffisant, compatibilité TalkBack. |
| **Batterie** | Notifications par alarmes exactes planifiées, pas de service permanent gourmand. |
| **Sécurité** | HTTPS uniquement, aucune donnée sensible stockée en clair, signature de release avec **votre propre clé**. |
| **Intégrité du texte** | Contrôle d'intégrité (somme de contrôle) du fichier de texte coranique pour garantir qu'il n'est pas altéré. |
| **Fiabilité** | Taux de plantage < 1 %. |

---

## 6. Architecture technique proposée

### 6.1 Choix technologique

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| **Flutter** (recommandé) | Un seul code Android + iOS, bon rendu de l'arabe, rapide à développer, bonne communauté | Taille de base un peu plus élevée |
| Kotlin natif | Performances et intégration système maximales | Code iOS séparé à prévoir |

**Recommandation :** Flutter (Dart) pour la V1, avec modules natifs Kotlin pour les alarmes exactes et la boussole si nécessaire. Vous pouvez aussi le construire avec votre outil (Antigravity) en suivant cette structure.

### 6.2 Composants

- **Interface** : Flutter, gestion d'état avec Riverpod ou Bloc.
- **Base de données locale** : SQLite (Drift ou sqflite) pour le texte, les traductions, les signets. Index de recherche FTS5.
- **Audio** : `just_audio` + `audio_service` (lecture en arrière-plan).
- **Prières** : package Adhan (Dart) ou implémentation de la bibliothèque Adhan.
- **Localisation** : `geolocator` + base de villes open source (GeoNames).
- **Notifications** : `flutter_local_notifications` + alarmes exactes Android.
- **Boussole** : `flutter_compass` / capteurs natifs.
- **Backend (optionnel, V1.x)** : Firebase ou Supabase pour la synchronisation des signets.
- **Stockage des médias** : CDN ou stockage objet pour les audios téléchargeables.

### 6.3 Schéma de données simplifié

```
surah(id, name_ar, name_fr, name_en, revelation_type, ayah_count)
ayah(id, surah_id, ayah_number, text_ar, text_ar_simple, juz, hizb, page, sajda)
translation(id, lang, translator, source, license)
ayah_translation(ayah_id, translation_id, text)
bookmark(id, ayah_id, note, created_at)
reading_progress(id, ayah_id, updated_at)
reciter(id, name, source_url)
settings(key, value)
```

### 6.4 Permissions Android

| Permission | Usage | Remarque |
|------------|-------|----------|
| `ACCESS_COARSE_LOCATION` / `FINE_LOCATION` | Horaires et Qibla | Demandée au moment de l'usage, ville manuelle possible |
| `POST_NOTIFICATIONS` | Rappels de prière | Android 13+ |
| `SCHEDULE_EXACT_ALARM` | Adhan à l'heure précise | Justification à fournir à Google Play |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Audio en arrière-plan | |
| `INTERNET` | Téléchargements | |

> Éviter les permissions sensibles inutiles. `INSTALL_PACKAGES` et `DUMP`, vues dans l'analyse, ne doivent **pas** être demandées.

---

## 7. Monétisation (options éthiques)

1. **Gratuit sans publicité** + dons (sadaqah jariyah), option cohérente avec le positionnement.
2. **Gratuit + publicités discrètes** (bannières hors lecture du Coran, jamais pendant la lecture ni l'audio).
3. **Version Premium** : thèmes, récitateurs supplémentaires, sauvegarde cloud, sans publicité (via Google Play Billing, vrai système de paiement).

Éviter les publicités sur les écrans du texte sacré.

---

## 8. Design et expérience utilisateur

- Interface sobre, apaisante, lisible, couleurs sobres (vert profond, blanc, or léger).
- Navigation à 5 onglets : **Coran – Prières – Qibla – Signets – Plus**.
- Page d'accueil : prochaine prière, dernière lecture, verset du jour.
- Support complet de la lecture de droite à gauche (RTL).
- Éviter toute iconographie figurative.
- Maquettes (Figma) à valider avant le développement.

---

## 9. Planning prévisionnel

| Phase | Contenu | Durée estimée |
|-------|---------|---------------|
| 0 | Cadrage, choix des sources et licences, maquettes | 2 semaines |
| 1 | Base de données du Coran + lecteur (M1, M2, M7, M8) | 4 semaines |
| 2 | Horaires, Adhan, notifications, Qibla (M4, M5, M6) | 3 semaines |
| 3 | Audio et téléchargements (M3) | 3 semaines |
| 4 | Tests, correction, relecture religieuse, optimisation | 3 semaines |
| 5 | Publication Google Play (bêta puis production) | 2 semaines |
| **Total MVP** | | **≈ 4 mois** (selon équipe) |

---

## 10. Tests et recette

- Tests unitaires : calcul des horaires (comparaison avec sources officielles), recherche, navigation.
- Vérification du texte : comparaison automatique avec la source et relecture humaine.
- Tests sur appareils réels : téléphones d'entrée de gamme, Android 8 à 15.
- Tests des alarmes : redémarrage, économie d'énergie (Xiaomi, Tecno, Infinix, Samsung).
- Tests de localisation : Ouagadougou, Paris, La Mecque, hautes latitudes.
- Bêta fermée avec 20 à 50 utilisateurs avant publication.

---

## 11. Livrables

1. Maquettes Figma validées
2. Code source versionné (Git)
3. Application Android (AAB) signée avec votre clé
4. Documentation technique et guide de maintenance
5. Politique de confidentialité et conditions d'utilisation
6. Fiche Google Play (textes, captures, icône)

---

## 12. Risques et parades

| Risque | Parade |
|--------|--------|
| Violation de droits d'auteur (contenu copié) | Sources sous licence uniquement, liste des licences tenue à jour |
| Erreur dans le texte coranique | Source officielle, somme de contrôle, relecture par un spécialiste |
| Alarmes non fiables selon les marques de téléphones | Tests ciblés, guide d'exclusion de l'optimisation batterie |
| Application trop lourde | Téléchargement à la demande, compression des audios |
| Refus Google Play | Respect des politiques (permissions, données, contenu religieux) |
| Calcul des prières contesté | Choix de plusieurs méthodes, ajustements manuels |

---

## 13. Prochaines étapes

1. Valider le nom « Muslim Coran » (vérifier sa disponibilité sur Google Play et comme marque).
2. Choisir la technologie (Flutter recommandé).
3. Sélectionner et documenter les sources de contenu avec leurs licences.
4. Réaliser les maquettes des écrans principaux.
5. Lancer la phase 1 (lecteur du Coran).
