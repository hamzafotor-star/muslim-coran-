# Cahier de maquettes — Application « Muslim Coran »

Version 1.0 — Novembre 2026
Complément du cahier des charges. Format de référence : smartphone 360 × 800 dp (Android), orientation portrait.

---

## 0. Charte graphique

| Élément | Valeur |
|---|---|
| Couleur principale | Vert profond `#0F5132` |
| Couleur secondaire | Vert clair `#D1E7DD` |
| Accent | Or doux `#C9A227` |
| Fond clair / sombre / sépia | `#FFFFFF` / `#121614` / `#F4ECD8` |
| Texte | `#1B1F1D` (clair), `#E8ECEA` (sombre) |
| Police interface | Inter ou Poppins |
| Police arabe Coran | Amiri Quran (OFL) ou police KFGQPC |
| Rayon des cartes | 16 dp, ombre légère |
| Icônes | Style linéaire, aucune figure humaine ou animale |
| Marges | 16 dp, grille de 8 dp |

**Navigation principale (barre du bas, 5 onglets) :**
`Coran · Prières · Qibla · Signets · Plus`

**Règle RTL :** l'arabe s'affiche de droite à gauche. L'interface bascule en miroir quand la langue arabe est choisie.

---

## Liste des écrans

| N° | Écran | Module |
|---|---|---|
| E01 | Écran de démarrage (splash) | Général |
| E02 | Accueil / bienvenue (première ouverture) | Général |
| E03 | Permissions (localisation, notifications) | Général |
| E04 | Accueil (tableau de bord) | Général |
| E05 | Liste des sourates / juz' | Coran |
| E06 | Lecteur — mode verset | Coran |
| E07 | Lecteur — mode mushaf (page) | Coran |
| E08 | Menu d'un verset | Coran |
| E09 | Lecteur audio (mini et plein écran) | Audio |
| E10 | Recherche | Coran |
| E11 | Horaires de prière | Prières |
| E12 | Réglages des prières et de l'Adhan | Prières |
| E13 | Qibla | Qibla |
| E14 | Signets et notes | Coran |
| E15 | Plus (menu) | Général |
| E16 | Réglages | Général |
| E17 | Téléchargements | Audio |
| E18 | Choix de la ville | Prières |

---

## E01 — Écran de démarrage

```
┌────────────────────────┐
│                        │
│                        │
│          ☪            │
│     MUSLIM CORAN       │
│                        │
│   ‹ logo + nom ›       │
│                        │
│                        │
│  Chargement…  ▓▓▓░░    │
└────────────────────────┘
```
- Fond vert profond, logo blanc/or centré.
- Durée : 1 à 2 s maximum, le temps d'ouvrir la base locale.

---

## E02 — Bienvenue (première ouverture)

```
┌────────────────────────┐
│  Passer                │
│                        │
│     [ illustration ]   │
│   (calligraphie sobre) │
│                        │
│  Lisez le Coran,       │
│  partout, sans internet│
│                        │
│        ● ○ ○           │
│                        │
│  [      Suivant      ] │
└────────────────────────┘
```
- 3 pages : **Lecture hors ligne**, **Horaires et Adhan**, **Qibla et suivi**.
- Choix de la langue (français, arabe, anglais) sur la dernière page.
- Bouton « Passer » en haut à gauche.

---

## E03 — Permissions

```
┌────────────────────────┐
│  Pour les prières      │
│                        │
│  📍 Localisation       │
│  Pour calculer les     │
│  horaires et la Qibla  │
│  [ Autoriser ]         │
│  [ Choisir une ville ] │
│                        │
│  🔔 Notifications      │
│  Pour l'Adhan          │
│  [ Autoriser ]         │
│                        │
│  [      Continuer    ] │
└────────────────────────┘
```
- Chaque permission est expliquée avant la demande système.
- L'application reste utilisable si l'utilisateur refuse (ville manuelle).

---

## E04 — Accueil (tableau de bord)

```
┌────────────────────────┐
│ Assalamu alaykum   ⚙   │
│ Mer. 11 nov · 22 Rabî' │
├────────────────────────┤
│ ┌────────────────────┐ │
│ │ Prochaine prière   │ │
│ │ ASR      15:32     │ │
│ │ dans 02 h 14 min   │ │
│ └────────────────────┘ │
│ ┌────────────────────┐ │
│ │ Reprendre la lecture│ │
│ │ Al-Baqara · v.255  │ │
│ │ [ Continuer ▶ ]    │ │
│ └────────────────────┘ │
│ ┌────────────────────┐ │
│ │ Verset du jour     │ │
│ │ ‹ texte arabe ›    │ │
│ │ traduction · ↗ ♡   │ │
│ └────────────────────┘ │
│ [Qibla] [Dhikr] [Audio]│
├────────────────────────┤
│Coran Prières Qibla ★ … │
└────────────────────────┘
```
- Carte « Prochaine prière » avec décompte en direct.
- Carte « Reprendre la lecture » : dernière position.
- Carte « Verset du jour » : partage et ajout aux signets.
- Raccourcis : Qibla, Dhikr (V1.x), dernier audio.

---

## E05 — Liste des sourates

```
┌────────────────────────┐
│ Coran              🔍  │
│ [Sourates][Juz'][Pages]│
├────────────────────────┤
│ 1  Al-Fâtiha    الفاتحة │
│    Mecquoise · 7 v.    │
│ 2  Al-Baqara    البقرة  │
│    Médinoise · 286 v.  │
│ 3  Âl-'Imrân    آل عمران│
│    Médinoise · 200 v.  │
│ …                      │
├────────────────────────┤
│Coran Prières Qibla ★ … │
└────────────────────────┘
```
- Trois onglets : **Sourates**, **Juz'** (30), **Pages** (604).
- Chaque ligne : numéro, nom translittéré, nom arabe, lieu de révélation, nombre de versets.
- Une pastille indique la sourate en cours de lecture.
- Défilement rapide par lettre ou numéro.

---

## E06 — Lecteur, mode verset

```
┌────────────────────────┐
│ ←  Al-Baqara    Aa  ⋮  │
├────────────────────────┤
│  بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ    │
│       ٱلرَّحِيمِ        │
│                        │
│ ┌────────────────────┐ │
│ │ ‹ texte arabe v.1 ›│ │
│ │  ١                 │ │
│ │ Alif, Lâm, Mîm.    │ │
│ └────────────────────┘ │
│ ┌────────────────────┐ │
│ │ ‹ texte arabe v.2 ›│ │
│ │  ٢                 │ │
│ │ Voici le Livre…    │ │
│ └────────────────────┘ │
├────────────────────────┤
│ ◀  ▶ 1:1   ▮▮▮▮▯▯  ⏵  │
└────────────────────────┘
```
- En-tête : retour, nom de sourate, bouton réglages de texte (**Aa**), menu (⋮).
- Chaque verset : texte arabe, numéro, traduction (option masquable).
- Verset en cours surligné pendant l'audio.
- Barre audio réduite en bas (E09).
- Appui long sur un verset : menu (E08).

---

## E07 — Lecteur, mode mushaf

```
┌────────────────────────┐
│ ←  Page 2 · Juz' 1  ⋮  │
├────────────────────────┤
│                        │
│   ‹ page de mushaf ›   │
│   15 lignes, cadre     │
│   décoratif sobre      │
│                        │
│                        │
│                        │
├────────────────────────┤
│        ‹  2 / 604  ›   │
└────────────────────────┘
```
- Mise en page de page (15 lignes ou 16 lignes selon la source choisie).
- Balayage horizontal pour tourner les pages (sens de lecture RTL).
- Toucher un verset : menu (E08).
- Disponible seulement si une source de mise en page sous licence est retenue.

---

## E08 — Menu d'un verset (feuille du bas)

```
┌────────────────────────┐
│ Al-Baqara · verset 255 │
│ ────────────────────── │
│ ▶  Écouter ce verset   │
│ ♡  Ajouter aux signets │
│ ✎  Ajouter une note    │
│ ⧉  Copier              │
│ ↗  Partager (texte)    │
│ 🖼  Partager (image)    │
│ 📖  Tafsir (V1.x)       │
└────────────────────────┘
```
- Le partage inclut toujours le nom de la sourate, le numéro du verset et la source.
- Le partage en image génère une carte avec le thème choisi.

---

## E09 — Lecteur audio

**Mini-lecteur (barre du bas) :**
```
┌────────────────────────┐
│ Al-Baqara · Al-Afasy   │
│ ▓▓▓▓░░░░░   ⏮ ⏯ ⏭   │
└────────────────────────┘
```

**Plein écran :**
```
┌────────────────────────┐
│ ⌄   En lecture    ⋮    │
│                        │
│    Sourate Al-Baqara   │
│    Mishary Al-Afasy    │
│                        │
│  ‹ verset en cours ›   │
│                        │
│  ▓▓▓▓▓▓░░░░  12:04    │
│  ⏮   ⏪  ⏯  ⏩   ⏭  │
│  🔁 Répéter   ⏲ Minuteur│
│  Vitesse 1.0×          │
└────────────────────────┘
```
- Lecture en arrière-plan avec notification de contrôle.
- Options : récitateur, répétition d'un verset ou d'une plage, vitesse, minuteur de sommeil.
- Si l'audio n'est pas téléchargé : lecture en streaming ou invitation à télécharger.

---

## E10 — Recherche

```
┌────────────────────────┐
│ ← [ Rechercher…      ] │
│ [Arabe][Français]      │
├────────────────────────┤
│ Résultats (24)         │
│ Al-Baqara 2:153        │
│ « …patience… »         │
│ Âl-'Imrân 3:200        │
│ « …patientez… »        │
│ …                      │
└────────────────────────┘
```
- Recherche en arabe (avec ou sans voyelles) ou dans la traduction.
- Mot recherché mis en évidence.
- Historique des dernières recherches quand le champ est vide.
- Toucher un résultat : ouverture du verset dans le lecteur.

---

## E11 — Horaires de prière

```
┌────────────────────────┐
│ Prières          📍 ⚙  │
│ Ouagadougou            │
│ ◀  Mer. 11 nov.  ▶     │
├────────────────────────┤
│ ┌────────────────────┐ │
│ │ Prochaine : ASR    │ │
│ │ 15:32  (dans 2h14) │ │
│ └────────────────────┘ │
│  Fajr      04:58   🔔  │
│  Chourouk  06:08   🔕  │
│  Dhuhr     12:02   🔔  │
│  Asr       15:32   🔔  │
│  Maghrib   17:56   🔔  │
│  Isha      19:06   🔔  │
├────────────────────────┤
│ Méthode : MWL          │
└────────────────────────┘
```
*(les heures sont des exemples de maquette)*
- La prière à venir est mise en surbrillance.
- Chaque ligne a une cloche (activer/désactiver l'Adhan).
- Navigation jour précédent / suivant, vue mensuelle en option.
- Pendant le Ramadan : ajout des lignes **Imsak** et **Iftar**.

---

## E12 — Réglages des prières

```
┌────────────────────────┐
│ ← Réglages des prières │
├────────────────────────┤
│ Méthode de calcul   ▸  │
│ École (Asr)         ▸  │
│ Ajustement (minutes) ▸ │
│ Adhan               ▸  │
│ Rappel avant la prière │
│   [ 10 min ]           │
│ Vibration           ⬤  │
│ Optimisation batterie  │
│   → guide d'exclusion  │
└────────────────────────┘
```
- Choix de l'Adhan avec écoute d'un extrait.
- Ajustement des minutes par prière (−30 à +30).
- Lien vers un guide pour désactiver l'optimisation batterie (Xiaomi, Tecno, Infinix, Samsung).

---

## E13 — Qibla

```
┌────────────────────────┐
│ ← Qibla                │
│                        │
│        N               │
│     ╭──────╮           │
│  W  │  ➤   │  E        │
│     ╰──────╯           │
│        S               │
│   Kaaba : 62° NE       │
│   Distance : 4 450 km  │
│                        │
│ ✅ Aligné — précision haute│
│ [ Calibrer le capteur ]│
└────────────────────────┘
```
- La flèche pointe vers la Kaaba, le téléphone doit rester à plat.
- Vibration légère et couleur verte quand l'alignement est atteint.
- Message si interférences magnétiques, avec animation en « 8 » pour calibrer.
- Option de repli : carte avec la direction si le capteur est absent.

---

## E14 — Signets et notes

```
┌────────────────────────┐
│ Signets            🔍  │
│ [Signets][Notes][Historique]│
├────────────────────────┤
│ ♡ Al-Baqara 2:255      │
│   Ayat al-Kursî        │
│ ♡ Al-Kahf 18:10        │
│   Note : « à réviser » │
│ …                      │
├────────────────────────┤
│Coran Prières Qibla ★ … │
└────────────────────────┘
```
- Glisser vers la gauche pour supprimer, vers la droite pour modifier la note.
- Onglet « Historique » : dernières positions de lecture.
- État vide : message et bouton « Ouvrir le Coran ».

---

## E15 — Plus (menu)

```
┌────────────────────────┐
│ Plus                   │
├────────────────────────┤
│ 📿 Dhikr / Tasbih      │
│ 🧠 Mémorisation        │
│ 🎯 Objectifs (Khatma)  │
│ 🗓 Calendrier hégirien  │
│ 🔤 Apprendre (Qaida)   │
│ ⬇ Téléchargements      │
│ ⚙ Réglages             │
│ ❤ Soutenir l'application│
│ ℹ À propos             │
└────────────────────────┘
```
- Les modules de la V1.x apparaissent avec la mention « Bientôt » tant qu'ils ne sont pas livrés.

---

## E16 — Réglages

```
┌────────────────────────┐
│ ← Réglages             │
├────────────────────────┤
│ Langue de l'interface ▸│
│ Thème  [Clair|Sombre|Sépia]│
│ Texte arabe            │
│   Police            ▸  │
│   Taille   ──●──────   │
│ Traduction principale ▸│
│ Afficher la traduction ⬤│
│ Récitateur par défaut ▸│
│ Compte & sauvegarde  ▸ │
│ Confidentialité      ▸ │
└────────────────────────┘
```
- Aperçu en direct du texte arabe lors du changement de taille ou de police.

---

## E17 — Téléchargements

```
┌────────────────────────┐
│ ← Téléchargements      │
│ [Audio][Traductions]   │
├────────────────────────┤
│ Mishary Al-Afasy       │
│ Coran complet · 1,2 Go │
│ [ Télécharger ]        │
│ Al-Baqara   ▓▓▓▓░ 80%  │
│ Al-Kahf     ✓ 24 Mo    │
├────────────────────────┤
│ Espace utilisé : 340 Mo│
└────────────────────────┘
```
- Téléchargement par sourate ou en lot, avec pause et reprise.
- Option « Wi-Fi uniquement » pour économiser les données mobiles.
- Affichage clair de la taille avant téléchargement.

---

## E18 — Choix de la ville

```
┌────────────────────────┐
│ ← Choisir une ville    │
│ [ Rechercher…        ] │
│ 📍 Utiliser ma position│
├────────────────────────┤
│ Ouagadougou, BF        │
│ Bobo-Dioulasso, BF     │
│ Abidjan, CI            │
│ …                      │
└────────────────────────┘
```
- Base de villes GeoNames (hors ligne).
- Possibilité de saisir latitude et longitude à la main.

---

## Parcours utilisateur principaux

1. **Première ouverture :** E01 → E02 → E03 → E04.
2. **Lire et écouter :** E04 → E05 → E06 → E08 → E09.
3. **Régler l'Adhan :** E11 → E12 → retour E11.
4. **Trouver la Qibla :** onglet Qibla → E13 (calibration si besoin).
5. **Retrouver un verset :** E10 → E06 → E08 (signet).

---

## États particuliers à maquetter

| État | Écrans concernés |
|---|---|
| Aucune connexion | E09, E17 (message et lecture hors ligne) |
| Permission refusée | E11, E13 (bouton « Choisir une ville ») |
| Liste vide | E14 |
| Chargement | E05, E10, E17 (squelettes animés) |
| Erreur de téléchargement | E17 (réessayer) |
| Mode sombre et sépia | Tous |
| Arabe RTL | Tous |
| Grande taille de texte | E06, E16 |

---

## Prochaines étapes

1. Reproduire ces wireframes dans Figma (grille 8 dp, composants réutilisables).
2. Valider les écrans E04, E06, E11 et E13 avec 5 à 10 utilisateurs.
3. Définir le kit de composants (carte, ligne de liste, barre audio, feuille du bas).
4. Passer à la maquette haute fidélité, puis au développement.
