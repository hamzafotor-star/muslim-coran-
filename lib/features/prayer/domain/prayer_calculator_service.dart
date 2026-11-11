import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Méthodes de calcul officielles supportées (M4 / §6).
enum PrayerCalcMethod {
  mwl('MWL', 'Ligue Islamique Mondiale (MWL) — Fajr 18°, Isha 17°'),
  uoif('UOIF', 'UOIF / Musulmans de France — Fajr 12°, Isha 12°'),
  ummAlQura('UmmAlQura', 'Umm al-Qura (La Mecque) — Fajr 18.5°, Isha 90 min'),
  egyptian('Egyptian', 'Autorité Générale Égyptienne — Fajr 19.5°, Isha 17.5°'),
  isna('ISNA', 'ISNA (Amérique du Nord) — Fajr 15°, Isha 15°');

  const PrayerCalcMethod(this.code, this.label);
  final String code;
  final String label;

  static PrayerCalcMethod fromCode(String code) {
    return PrayerCalcMethod.values.firstWhere(
      (PrayerCalcMethod m) => m.code.toLowerCase() == code.toLowerCase(),
      orElse: () => PrayerCalcMethod.mwl,
    );
  }
}

enum AsrJuristicSchool {
  shafi('shafi', 'Majoritaire (Chaféite, Malikite, Hanbalite)'),
  hanafi('hanafi', 'Hanafite');

  const AsrJuristicSchool(this.code, this.label);
  final String code;
  final String label;
}

@immutable
class PrayerAdjustmentsConfig {
  const PrayerAdjustmentsConfig({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  PrayerAdjustmentsConfig copyWith({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return PrayerAdjustmentsConfig(
      fajr: (fajr ?? this.fajr).clamp(-30, 30),
      sunrise: (sunrise ?? this.sunrise).clamp(-30, 30),
      dhuhr: (dhuhr ?? this.dhuhr).clamp(-30, 30),
      asr: (asr ?? this.asr).clamp(-30, 30),
      maghrib: (maghrib ?? this.maghrib).clamp(-30, 30),
      isha: (isha ?? this.isha).clamp(-30, 30),
    );
  }
}

@immutable
class DailyPrayerSchedule {
  const DailyPrayerSchedule({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.utcOffsetHours,
    required this.date,
    required this.method,
    required this.asrSchool,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.iftar,
    required this.isRamadanMode,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.countdownText,
  });

  final String locationName;
  final double latitude;
  final double longitude;
  final double utcOffsetHours;
  final DateTime date;
  final PrayerCalcMethod method;
  final AsrJuristicSchool asrSchool;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime imsak;
  final DateTime iftar;
  final bool isRamadanMode;
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final String countdownText;

  String get formattedDate =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String get nextPrayerFormattedTime => formatHm(nextPrayerTime);

  static String formatHm(DateTime dt) {
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Service de calcul 100 % local des horaires de prière via le package `adhan` (M4 / RF-07..RF-11).
class PrayerCalculatorService {
  const PrayerCalculatorService();

  CalculationParameters _buildParameters(
    PrayerCalcMethod method,
    AsrJuristicSchool school,
    PrayerAdjustmentsConfig adjustments,
  ) {
    late final CalculationParameters params;
    switch (method) {
      case PrayerCalcMethod.mwl:
        params = CalculationMethod.muslim_world_league.getParameters();
      case PrayerCalcMethod.uoif:
        params = CalculationParameters(fajrAngle: 12.0, ishaAngle: 12.0);
      case PrayerCalcMethod.ummAlQura:
        params = CalculationMethod.umm_al_qura.getParameters();
      case PrayerCalcMethod.egyptian:
        params = CalculationMethod.egyptian.getParameters();
      case PrayerCalcMethod.isna:
        params = CalculationMethod.north_america.getParameters();
    }

    params.madhab =
        school == AsrJuristicSchool.hanafi ? Madhab.hanafi : Madhab.shafi;
    params.adjustments = PrayerAdjustments(
      fajr: adjustments.fajr,
      sunrise: adjustments.sunrise,
      dhuhr: adjustments.dhuhr,
      asr: adjustments.asr,
      maghrib: adjustments.maghrib,
      isha: adjustments.isha,
    );
    return params;
  }

  /// Calcule les 6 moments + Imsak/Iftar dans le fuseau de la ville (`utcOffsetHours`).
  DailyPrayerSchedule computeSchedule({
    required String locationName,
    required double latitude,
    required double longitude,
    required double utcOffsetHours,
    required DateTime date,
    PrayerCalcMethod method = PrayerCalcMethod.mwl,
    AsrJuristicSchool asrSchool = AsrJuristicSchool.shafi,
    PrayerAdjustmentsConfig adjustments = const PrayerAdjustmentsConfig(),
    bool isRamadanMode = false,
    DateTime? nowOverride,
  }) {
    final Coordinates coordinates = Coordinates(latitude, longitude);
    final DateComponents dateComponents =
        DateComponents(date.year, date.month, date.day);
    final CalculationParameters params =
        _buildParameters(method, asrSchool, adjustments);

    final PrayerTimes prayerTimes = PrayerTimes(
      coordinates,
      dateComponents,
      params,
      utcOffset: Duration(minutes: (utcOffsetHours * 60).round()),
    );

    final DateTime fajr = prayerTimes.fajr;
    final DateTime sunrise = prayerTimes.sunrise;
    final DateTime dhuhr = prayerTimes.dhuhr;
    final DateTime asr = prayerTimes.asr;
    final DateTime maghrib = prayerTimes.maghrib;
    final DateTime isha = prayerTimes.isha;
    final DateTime imsak = fajr.subtract(const Duration(minutes: 10));
    final DateTime iftar = maghrib;

    final DateTime referenceNow = nowOverride ?? DateTime.now();
    final List<MapEntry<String, DateTime>> ordered =
        <MapEntry<String, DateTime>>[
      MapEntry<String, DateTime>('Fajr', fajr),
      MapEntry<String, DateTime>('Chourouk', sunrise),
      MapEntry<String, DateTime>('Dhuhr', dhuhr),
      MapEntry<String, DateTime>('Asr', asr),
      MapEntry<String, DateTime>('Maghrib', maghrib),
      MapEntry<String, DateTime>('Isha', isha),
    ];

    String nextName = 'Fajr';
    DateTime nextTime = fajr.add(const Duration(days: 1));
    for (final MapEntry<String, DateTime> entry in ordered) {
      if (entry.value.isAfter(referenceNow)) {
        nextName = entry.key;
        nextTime = entry.value;
        break;
      }
    }

    final Duration diff = nextTime.difference(referenceNow);
    final int hours = diff.inHours.clamp(0, 99);
    final int minutes = (diff.inMinutes % 60).clamp(0, 59);
    final String countdown =
        '${hours.toString().padLeft(2, '0')} h ${minutes.toString().padLeft(2, '0')} min';

    return DailyPrayerSchedule(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      utcOffsetHours: utcOffsetHours,
      date: date,
      method: method,
      asrSchool: asrSchool,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      imsak: imsak,
      iftar: iftar,
      isRamadanMode: isRamadanMode,
      nextPrayerName: nextName,
      nextPrayerTime: nextTime,
      countdownText: countdown,
    );
  }
}

final Provider<PrayerCalculatorService> prayerCalculatorServiceProvider =
    Provider<PrayerCalculatorService>(
  (Ref ref) => const PrayerCalculatorService(),
);
