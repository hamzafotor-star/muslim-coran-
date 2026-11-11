/// Outils de normalisation du texte arabe pour la recherche (M7),
/// la séparation de la Basmala en en-tête de sourate (RF-01 / E06)
/// et le formatage des numéros de versets en chiffres arabes orientaux.
class ArabicNormalizer {
  const ArabicNormalizer._();

  /// Basmala Uthmani exacte présente en tête du verset 1 dans `quran-uthmani.txt`.
  static const String basmalaUthmani = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

  /// Expression régulière supprimant les voyelles brèves (harakat), shadda,
  /// sukun, maddah, dagger alif, tatweel (`ـ`) et signes coraniques de pause (waqf).
  static final RegExp _diacriticsAndMarksRegex = RegExp(
    r'[\u0610-\u061A\u0640\u064B-\u065F\u0670\u06D6-\u06ED\u08D4-\u08FF]',
  );

  /// Normalise une chaîne arabe pour la recherche insensible aux voyelles :
  /// - Supprime tous les signes diacritiques (harakat, shadda, sukun, maddah, waqf) et le tatweel (`ـ`).
  /// - Unifie les variantes d'Alef (`أ`, `إ`, `آ`, `ٱ`) en `ا`.
  /// - Unifie l'Alef maqsura (`ى`) en `ي`, le Ta marbuta (`ة`) en `ه`, et les hamzas sur support (`ؤ` -> `و`, `ئ` -> `ي`).
  /// - Normalise les espaces multiples.
  static String normalizeForSearch(String input) {
    if (input.isEmpty) return '';
    String out = input.replaceAll(_diacriticsAndMarksRegex, '');
    out = out
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Sépare le préfixe Basmala du premier verset des sourates 2 à 114 (hors sourate 9 At-Tawba)
  /// afin qu'elle ne soit pas affichée en double sous le bandeau Basmala de l'écran E06,
  /// tout en gardant la Basmala intégrée comme verset 1:1 pour Al-Fâtiha (§6).
  static String stripLeadingBasmalaIfApplicable({
    required int surahId,
    required int ayahNumber,
    required String textUthmani,
  }) {
    if (surahId == 1 || surahId == 9 || ayahNumber != 1) {
      return textUthmani;
    }
    if (textUthmani.startsWith('$basmalaUthmani ')) {
      return textUthmani.substring(basmalaUthmani.length + 1).trim();
    }
    if (textUthmani.startsWith(basmalaUthmani)) {
      final String rem = textUthmani.substring(basmalaUthmani.length).trim();
      return rem.isEmpty ? textUthmani : rem;
    }
    return textUthmani;
  }

  /// Indique si le bandeau Basmala doit être affiché en tête de la sourate dans E06.
  /// - Absente pour At-Tawba (sourate 9)
  /// - Intégrée comme verset 1 pour Al-Fâtiha (sourate 1) -> pas de bandeau séparé
  /// - Bandeau affiché pour les sourates 2..8 et 10..114.
  static bool shouldShowBasmalaHeader(int surahId) {
    return surahId != 1 && surahId != 9;
  }

  /// Convertit un entier occidental (`123`) en chiffres arabes orientaux (`١٢٣`) pour E06.
  static String toEasternArabicDigits(int number) {
    const List<String> digits = <String>[
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];
    return number
        .toString()
        .split('')
        .map((String ch) {
          final int? idx = int.tryParse(ch);
          return idx != null ? digits[idx] : ch;
        })
        .join();
  }
}
