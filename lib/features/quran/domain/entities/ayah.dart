import 'package:flutter/foundation.dart';
import '../utils/arabic_normalizer.dart';

@immutable
class Ayah {
  const Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.textUthmani,
    required this.textSimple,
    required this.juz,
    required this.hizbQuarter,
    required this.manzil,
    required this.page15,
    this.sajdaType,
    this.translationText,
    this.surahNameTranslit,
    this.surahNameAr,
  });

  final int id;
  final int surahId;
  final int ayahNumber;
  final String textUthmani;
  final String textSimple;
  final int juz;
  final int hizbQuarter;
  final int manzil;
  final int page15;
  final String? sajdaType; // 'recommended' | 'obligatory' | null
  final String? translationText;
  final String? surahNameTranslit;
  final String? surahNameAr;

  bool get hasSajda => sajdaType != null && sajdaType!.isNotEmpty;
  bool get isObligatorySajda => sajdaType == 'obligatory';

  /// Texte arabe pour l'écran E06 (sans la Basmala en doublon sur le verset 1).
  String get displayArabicText =>
      ArabicNormalizer.stripLeadingBasmalaIfApplicable(
        surahId: surahId,
        ayahNumber: ayahNumber,
        textUthmani: textUthmani,
      );

  /// Texte complet prêt à être partagé avec sourate, numéro et source obligatoire (E08 / RF-05).
  String formatForShare({required String surahTitle}) {
    final StringBuffer buffer = StringBuffer()
      ..writeln(displayArabicText)
      ..writeln();
    if (translationText != null && translationText!.isNotEmpty) {
      buffer
        ..writeln('« $translationText »')
        ..writeln();
    }
    buffer.write(
      '— Sourate $surahTitle ($surahId:$ayahNumber) · Source : Tanzil.net / Muslim Coran',
    );
    return buffer.toString();
  }

  factory Ayah.fromMap(Map<String, Object?> map) {
    return Ayah(
      id: (map['id'] as num).toInt(),
      surahId: (map['surah_id'] as num).toInt(),
      ayahNumber: (map['ayah_number'] as num).toInt(),
      textUthmani: (map['text_uthmani'] as String?) ?? '',
      textSimple: (map['text_simple'] as String?) ?? '',
      juz: (map['juz'] as num?)?.toInt() ?? 1,
      hizbQuarter: (map['hizb_quarter'] as num?)?.toInt() ?? 1,
      manzil: (map['manzil'] as num?)?.toInt() ?? 1,
      page15: (map['page_15'] as num?)?.toInt() ?? 1,
      sajdaType: map['sajda_type'] as String?,
      translationText: map['translation_text'] as String?,
      surahNameTranslit: map['surah_name_translit'] as String?,
      surahNameAr: map['surah_name_ar'] as String?,
    );
  }
}
