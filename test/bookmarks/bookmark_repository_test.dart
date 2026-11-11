import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/features/quran/domain/entities/ayah.dart';

void main() {
  group('Phase 1 — Formatage et partage de verset (RF-05 / E08)', () {
    test('Inclut toujours le nom de la sourate, le numéro du verset et la source Tanzil', () {
      const Ayah kursi = Ayah(
        id: 262,
        surahId: 2,
        ayahNumber: 255,
        textUthmani: 'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
        textSimple: 'الله لا اله الا هو الحي القيوم',
        juz: 3,
        hizbQuarter: 19,
        manzil: 1,
        page15: 42,
        translationText: 'Allah! Point de divinité à part Lui, le Vivant, Celui qui subsiste par lui-même.',
        surahNameTranslit: 'Al-Baqara',
      );

      final String shared = kursi.formatForShare(surahTitle: 'Al-Baqara');
      expect(shared, contains('Al-Baqara (2:255)'));
      expect(shared, contains('Tanzil.net'));
      expect(shared, contains('ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ'));
    });
  });
}
