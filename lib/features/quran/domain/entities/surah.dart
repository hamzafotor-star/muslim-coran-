import 'package:flutter/foundation.dart';

@immutable
class Surah {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameTranslit,
    required this.nameFr,
    required this.nameEn,
    required this.revelationType,
    required this.revelationOrder,
    required this.ayahCount,
    required this.hasBismillah,
  });

  final int id;
  final String nameAr;
  final String nameTranslit;
  final String nameFr;
  final String nameEn;
  final String revelationType; // 'meccan' | 'medinan'
  final int revelationOrder;
  final int ayahCount;
  final bool hasBismillah;

  bool get isMeccan => revelationType == 'meccan';

  factory Surah.fromMap(Map<String, Object?> map) {
    return Surah(
      id: (map['id'] as num).toInt(),
      nameAr: (map['name_ar'] as String?) ?? '',
      nameTranslit: (map['name_translit'] as String?) ?? '',
      nameFr: (map['name_fr'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
      revelationType: (map['revelation_type'] as String?) ?? 'meccan',
      revelationOrder: (map['revelation_order'] as num?)?.toInt() ?? 0,
      ayahCount: (map['ayah_count'] as num).toInt(),
      hasBismillah: ((map['has_bismillah'] as num?)?.toInt() ?? 1) == 1,
    );
  }
}
