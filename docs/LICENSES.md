# Registre des Licences — Muslim Coran (MVP)

Conformément à l'exigence §2.4 du cahier des charges, chaque source de texte sacré, traduction, récitateur audio, base géographique, police typographique et bibliothèque logicielle utilisée dans **Muslim Coran** est documentée ci-dessous avec sa licence.

> **Règle d'intégrité :** Aucun code, binaire, police ou base de données provenant de l'application *Quran Majeed* ou d'un APK tiers modifié n'est utilisé dans ce projet.

---

## 1. Texte Coranique (Arabe Uthmani & Simple)

| Ressource | Fichier Source | Éditeur / Auteur | Licence | Conditions d'utilisation |
| :--- | :--- | :--- | :--- | :--- |
| **Tanzil Quran Text (Uthmani v1.1)** | `tools/sources/quran-uthmani.txt` | **Tanzil Project** (`http://tanzil.net`) | **Creative Commons Attribution 3.0 (CC BY 3.0)** | Copie intégrale sans aucune modification du texte ; mention obligatoire de la source *Tanzil Project* avec lien vers `https://tanzil.net` ; conservation du bloc de copyright. |
| **Tanzil Quran Text (Simple / Clean v1.1)** | `tools/sources/quran-simple.txt`, `quran-simple-clean.txt` | **Tanzil Project** (`http://tanzil.net`) | **Creative Commons Attribution 3.0 (CC BY 3.0)** | Utilisé pour l'indexation de recherche sans voyelles (`ayah_fts`). Même licence CC BY 3.0. |
| **Métadonnées de pagination (Sourates, Juz', Hizb, Pages, Sajda)** | `tools/sources/quran_metadata.json` | **Tanzil Project** (`quran-data.xml`) | **Creative Commons Attribution 3.0 (CC BY 3.0)** | Découpage standard du Mushaf de Médine (604 pages, 30 Juz', 60 Hizb / 240 quarts, 15 prosternations). |

---

## 2. Traductions et Translittérations

| Langue | Nom / Identifiant | Traducteur / Auteur | Source | Licence |
| :--- | :--- | :--- | :--- | :--- |
| **Français (`fr`)** | `fr.hamidullah` — *Le Saint Coran* | **Prof. Muhammad Hamidullah** (1908–2002) | **Tanzil.net** (`tools/sources/fr.hamidullah.txt`) | **Domaine public / Distribution libre non altérée via Tanzil.net** (mention obligatoire du traducteur Muhammad Hamidullah et de la source Tanzil.net). |
| **Anglais / Translittération (`en`)** | `en.transliteration` (et support `en.sahih` — *Saheeh International*) | **Tanzil Project / Saheeh International (Abul-Qasim Publishing House)** | **Tanzil.net** (`tools/sources/en.transliteration.txt`) | **Usage gratuit non commercial / Attribution Tanzil.net** (sans modification du texte). |

---

## 3. Polices Typographiques Arabes et Interface

Toutes les polices arabes prévues et référencées dans l'application sont publiées sous **SIL Open Font License 1.1 (OFL-1.1)** :

| Police | Usage | Auteur / Fonderie | Licence | Lien officiel |
| :--- | :--- | :--- | :--- | :--- |
| **Amiri Quran** (`AmiriQuran`) | Police arabe coranique par défaut (embarquée) | **Khaled Hosny** (`Amiri Typeface Project`) | **SIL Open Font License 1.1 (OFL-1.1)** | `https://github.com/aliftype/amiri` |
| **Scheherazade New** (`ScheherazadeNew`) | Police arabe coranique alternative à haute lisibilité (embarquée) | **SIL International** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://software.sil.org/scheherazade/` |
| **Lateef** (`Lateef`) | Police arabe Naskh/Nastaliq adaptée à l'Afrique de l'Ouest (embarquée) | **SIL International** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://software.sil.org/lateef/` |
| **Noto Naskh Arabic** (`NotoNaskhArabic`) | Police Naskh téléchargeable à la demande via `FontLoader` | **Google Fonts / Monotype** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://github.com/google/fonts/tree/main/ofl/notonaskharabic` |
| **Harmattan** (`Harmattan`) | Calligraphie d'Afrique de l'Ouest / Warsh téléchargeable | **SIL International** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://github.com/google/fonts/tree/main/ofl/harmattan` |
| **Alkalami** (`Alkalami`) | Calligraphie Sudani / Kano téléchargeable | **SIL International** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://github.com/google/fonts/tree/main/ofl/alkalami` |
| **Reem Kufi** (`ReemKufi`) | Calligraphie coufique moderne téléchargeable | **Khaled Hosny** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://github.com/google/fonts/tree/main/ofl/reemkufi` |
| **Aref Ruqaa** (`ArefRuqaa`) | Calligraphie Ruq'ah classique téléchargeable | **Abdullah Aref** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://github.com/google/fonts/tree/main/ofl/arefruqaa` |
| **Mirza** (`Mirza`) | Calligraphie Naskh/Nastaliq téléchargeable | **KB Studio** | **SIL Open Font License 1.1 (OFL-1.1)** | `https://github.com/google/fonts/tree/main/ofl/mirza` |
| **Inter / Roboto** | Police de l'interface utilisateur (FR / EN) | **Rasmus Andersson / Google** | **SIL Open Font License 1.1 / Apache 2.0** | `https://rsms.me/inter/` |

---

## 4. Récitateurs Audio (12 Lecteurs) & Son d'Adhan

Les fichiers audio des sourates ne sont **pas embarqués** dans l'APK de base afin de maintenir un poids `< 60 Mo`. Seules les URLs publiques de streaming/téléchargement sont enregistrées dans `reciter` et `audio_file` :

| Récitateur / Audio | Style | Fournisseur / CDN | Licence & Conditions |
| :--- | :--- | :--- | :--- |
| **Mishary Rashid Al-Afasy** (`مشاري العفاسي`) | Murattal (Hafs 'an 'Asim) | **QuranicAudio.com** (`mishaari_raashid_al_3afaasee`) | Gratuit pour usage personnel et applications islamiques non commerciales avec mention de la source. |
| **Abdullah Al-Matrood** (`عبد الله المطرود`) | Murattal (Hafs 'an 'Asim) | **QuranicAudio.com / MP3Quran.net** (`abdullah_matroud`) | Gratuit pour usage personnel et applications islamiques non commerciales avec mention de la source. |
| **Abdul Basit Abdus Samad** (`عبد الباسط عبد الصمد`) | Murattal | **QuranicAudio.com** (`abdul_basit_murattal`) | Gratuit pour usage personnel et non commercial. |
| **Abdur-Rahman As-Sudais** (`عبد الرحمن السديس`) | Haramain (La Mecque) | **QuranicAudio.com** (`abdurrahmaan_as-sudays`) | Gratuit pour usage personnel et non commercial. |
| **Maher Al-Muaiqly** (`ماهر المعيقلي`) | Haramain (La Mecque) | **QuranicAudio.com** (`maher_256`) | Gratuit pour usage personnel et non commercial. |
| **Saad Al-Ghamdi** (`سعد الغامدي`) | Murattal | **QuranicAudio.com** (`sa3d_al-ghaamidi/complete`) | Gratuit pour usage personnel et non commercial. |
| **Mahmoud Khalil Al-Husary** (`محمود خليل الحصري`) | Murattal / Tajweed | **QuranicAudio.com** (`mahmood_khaleel_al-husaree`) | Gratuit pour usage personnel et éducatif. |
| **Mohamed Siddiq Al-Minshawi** (`محمد صديق المنشاوي`) | Murattal classique | **QuranicAudio.com** (`muhammad_siddeeq_al-minshaawee`) | Gratuit pour usage personnel et éducatif. |
| **Saud Ash-Shuraim** (`سعود الشريم`) | Haramain (La Mecque) | **QuranicAudio.com** (`sa3ood_al-shuraym`) | Gratuit pour usage personnel et non commercial. |
| **Yasser Ad-Dossari** (`ياسر الدوسري`) | Haramain (La Mecque) | **QuranicAudio.com** (`yasser_ad-dussary`) | Gratuit pour usage personnel et non commercial. |
| **Abu Bakr Ash-Shatri** (`أبو بكر الشاطري`) | Murattal | **QuranicAudio.com** (`abu_bakr_ash-shaatree`) | Gratuit pour usage personnel et non commercial. |
| **Fares Abbad** (`فارس عباد`) | Murattal | **QuranicAudio.com** (`fares`) | Gratuit pour usage personnel et non commercial. |
| **Son de notification Adhan par défaut** (`assets/audio/adhan_notification.wav`) | Signal sonore doux d'appel à la prière (synthèse acoustique générée localement par script) | **Projet Muslim Coran** | **CC0 1.0 Universal (Domaine Public)** — En attendant l'enregistrement ou l'acquisition d'un Adhan vocal complet sous licence explicite. |

---

## 5. Base Géographique des Villes (Horaires & Qibla hors ligne)

| Ressource | Source | Licence | Attribution requise |
| :--- | :--- | :--- | :--- |
| **Villes du monde & d'Afrique de l'Ouest (`city`)** | **GeoNames** (`https://www.geonames.org` — `cities15000.txt`) | **Creative Commons Attribution 4.0 International (CC BY 4.0)** | *"Geographical data sourced from GeoNames.org under CC BY 4.0."* |

---

## 6. Bibliothèques Open Source (Flutter / Dart)

| Package | Rôle dans Muslim Coran | Licence |
| :--- | :--- | :--- |
| `flutter` / `flutter_localizations` | Framework UI & Internationalisation | BSD-3-Clause |
| `flutter_riverpod` | Gestion d'état réactive | MIT |
| `go_router` | Navigation déclarative | BSD-3-Clause |
| `sqflite` / `sqflite_common_ffi` | Moteur SQLite local (`quran.db` + `user.db`) | BSD-2-Clause |
| `adhan` | Calcul astronomique hors ligne des horaires de prière et de la Qibla | MIT |
| `just_audio` & `audio_service` | Lecture audio et service de notification média en arrière-plan | MIT |
| `flutter_local_notifications` & `timezone` | Planification des alarmes exactes d'Adhan | BSD-3-Clause |
| `geolocator` | Acquisition GPS ponctuelle avec consentement | MIT |
| `flutter_compass` | Lecture du magnétomètre pour la boussole Qibla | MIT |
| `dio` | Téléchargements HTTP avec pause/reprise (`Range`) | MIT |
| `share_plus` | Partage de versets | BSD-3-Clause |
| `crypto` | Vérification d'intégrité SHA-256 du texte coranique | BSD-3-Clause |
