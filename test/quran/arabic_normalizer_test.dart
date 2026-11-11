import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/features/quran/domain/utils/arabic_normalizer.dart';

void main() {
  group('Phase 1 — Normalisation Arabe & Gestion de la Basmala (§6 & §7)', () {
    test('Supprime tous les harakat, shadda, sukun, maddah, tatweel et waqf', () {
      const String uthmani =
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ';
      final String normalized = ArabicNormalizer.normalizeForSearch(uthmani);
      expect(
        normalized,
        'بسم الله الرحمن الرحيم الحمد لله رب العالمين',
      );
    });

    test('Unifie les variantes d’Alef (أ, إ, آ, ٱ), Ta marbuta (ة) et Alef maqsura (ى)', () {
      const String sample = 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ هُدًى لِّلْمُتَّقِينَ الصَّلَاةَ';
      final String normalized = ArabicNormalizer.normalizeForSearch(sample);
      expect(normalized, 'اياك نعبد واياك نستعين هدي للمتقين الصلاه');
    });

    test('Sépare correctement la Basmala pour les sourates 2..114 hors sourate 9', () {
      // Sourate 1 (Al-Fatiha) : la Basmala EST le verset 1 -> conservée
      const String fatiha1 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      expect(
        ArabicNormalizer.stripLeadingBasmalaIfApplicable(
          surahId: 1,
          ayahNumber: 1,
          textUthmani: fatiha1,
        ),
        fatiha1,
      );
      expect(ArabicNormalizer.shouldShowBasmalaHeader(1), isFalse);

      // Sourate 9 (At-Tawba) : pas de Basmala -> bandeau absent
      expect(ArabicNormalizer.shouldShowBasmalaHeader(9), isFalse);

      // Sourate 2 (Al-Baqara v.1) : préfixe Basmala retiré pour éviter le doublon sous le bandeau
      const String baqara1 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ الٓمٓ';
      expect(ArabicNormalizer.shouldShowBasmalaHeader(2), isTrue);
      expect(
        ArabicNormalizer.stripLeadingBasmalaIfApplicable(
          surahId: 2,
          ayahNumber: 1,
          textUthmani: baqara1,
        ),
        'الٓمٓ',
      );
    });

    test('Convertit les numéros de versets en chiffres arabes orientaux', () {
      expect(ArabicNormalizer.toEasternArabicDigits(1), '١');
      expect(ArabicNormalizer.toEasternArabicDigits(255), '٢٥٥');
      expect(ArabicNormalizer.toEasternArabicDigits(286), '٢٨٦');
    });
  });
}
