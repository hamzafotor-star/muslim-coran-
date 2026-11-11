# Guide de Publication & Fiche Google Play Store — Muslim Coran (MVP)

Ce document réunit tous les textes, déclarations réglementaires et étapes techniques requis dans la **Google Play Console** pour publier la version 1.0 de **Muslim Coran** sans rejet.

---

## 1. Textes de la Fiche Play Store (Français — `fr-FR`)

### Titre de l'application (max 30 caractères)
`Muslim Coran : Coran & Prières` *(29 caractères)*

### Description courte (max 80 caractères)
`Coran hors ligne, horaires de prière précis, Adhan et Qibla. Sans publicité.` *(76 caractères)*

### Description complète (max 4 000 caractères)
```text
Muslim Coran est une application mobile légère, rapide et 100 % utilisable hors ligne pour lire le Saint Coran, connaître les horaires de prière, recevoir l'Adhan et trouver la direction de la Qibla.

Conçue spécialement pour fonctionner avec fluidité sur tous les smartphones Android (y compris les appareils d'entrée de gamme et les connexions limitées en Afrique de l'Ouest et dans le monde), Muslim Coran garantit une expérience sobre, apaisante et sans aucune publicité ni pistage.

📖 LECTURE DU SAINT CORAN (100 % HORS LIGNE)
• Texte arabe Uthmani complet (114 sourates, 6 236 versets) issu du projet officiel Tanzil.net, vérifié par somme de contrôle cryptographique (SHA-256).
• Traduction française intégrale (Prof. Muhammad Hamidullah) et translittération.
• Navigation rapide par Sourate, Juz' (30) et Page (604).
• 3 polices arabes sous licence libre (Amiri Quran, Scheherazade New, Lateef) et taille de texte réglable avec aperçu en direct.
• 3 thèmes adaptés à la lecture prolongée : Clair, Sombre et Sépia.
• Indicateurs de prosternation (Sajda), reprise automatique à la dernière position, signets et notes personnelles.

🔍 RECHERCHE INSTANTANÉE HORS LIGNE
• Recherche plein texte en arabe (avec ou sans voyelles grâce à la normalisation automatique des signes diacritiques) et en français.
• Mise en évidence des mots recherchés et historique local.

🕌 HORAIRES DE PRIÈRE & ADHAN FIABLE
• Calcul astronomique 100 % local (sans connexion Internet) par GPS ou via la base de villes intégrée (Ouagadougou, Bobo-Dioulasso, Abidjan, Dakar, Bamako, Niamey, Casablanca, Alger, Tunis, Paris, La Mecque, Médine…).
• Méthodes de calcul officielles : Ligue Islamique Mondiale (MWL), UOIF (Musulmans de France 12°/12°), Umm al-Qura, Égypte, ISNA.
• Choix de l'école juridique pour Asr et ajustement manuel des minutes (−30 à +30 min).
• Mode Ramadan avec affichage des horaires d'Imsak et d'Iftar.
• Alarmes exactes pour chaque prière, rappel avant l'heure et guide d'optimisation batterie pour Tecno, Infinix, Xiaomi et Samsung.

🧭 BOUSSOLE QIBLA
• Direction exacte et distance vers la Sainte Kaaba à La Mecque selon la formule du grand cercle.
• Indicateur de précision, détection des interférences magnétiques et mode de repli sans capteur.

🎧 RÉCITATIONS AUDIO
• Écoute en streaming ou téléchargement hors ligne sourate par sourate (Mishary Rashid Al-Afasy, Mahmoud Khalil Al-Husary).
• Lecture en arrière-plan, répétition, réglage de la vitesse et minuteur de sommeil.
• Téléchargements avec pause, reprise et option « Wi-Fi uniquement ».

🔒 ÉTHIQUE & CONFIDENTIALITÉ
• Zéro publicité, zéro traceur, zéro revente de données.
• Vos coordonnées GPS, signets et notes ne quittent jamais votre téléphone.
```

---

## 2. Déclarations Obligatoires dans la Google Play Console

### 2.1 Justification de `SCHEDULE_EXACT_ALARM` (Alarmes exactes)
> **Texte à coller dans Play Console > Contenu de l'application > Alarmes exactes :**
> *"L'application Muslim Coran a pour fonction principale de notifier aux utilisateurs musulmans les 5 horaires quotidiens de prière canonique (Adhan) ainsi que l'heure de rupture du jeûne (Iftar). Ces rappels religieux doivent impérativement se déclencher à la minute astronomique exacte calculée pour la position de l'utilisateur, y compris lorsque le téléphone est en veille (Doze mode)."*

### 2.2 Justification de `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
> **Texte à coller dans Play Console > Autorisations de service de premier plan :**
> *"Le service de premier plan de type mediaPlayback est utilisé exclusivement lorsque l'utilisateur lance l'écoute audio d'une sourate du Coran afin que la récitation se poursuive lorsque l'écran s'éteint, avec une notification système standard permettant de mettre en pause ou de changer de sourate."*

### 2.3 Section « Sécurité des données » (Data Safety)
- **L'application collecte-t-elle ou partage-t-elle des données utilisateur ?** → **NON** (toutes les données — y compris la localisation — sont traitées éphémèrement ou stockées uniquement en local sur l'appareil sans jamais être transmises à un serveur).

---

## 3. Procédure de Signature et Génération du Bundle (`.aab`)

1. Générez votre clé de signature personnelle (en dehors du dépôt Git) :
   ```bash
   keytool -genkey -v -keystore muslim_coran_release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias muslim_coran_release
   ```
2. Créez `android/key.properties` à partir de `android/key.properties.example`.
3. Compilez le bundle signé :
   ```bash
   flutter build appbundle --release
   ```
4. Téléversez `build/app/outputs/bundle/release/app-release.aab` dans la Google Play Console.
