import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/features/prayer/domain/prayer_calculator_service.dart';

void main() {
  group(
    'Phase 2 — Calcul des horaires de prière sur 3 villes de référence (§7)',
    () {
      const PrayerCalculatorService service = PrayerCalculatorService();
      final DateTime testDate = DateTime(2026, 11, 11);

      test(
        '1. Ouagadougou (12.3714° N, -1.5197° O, UTC+0, méthode MWL) le 11/11/2026',
        () {
          // Valeurs de référence attendues (MWL, Shafi, UTC+0, 11 novembre 2026) :
          // Fajr ≈ 04:49, Sunrise ≈ 06:02, Dhuhr ≈ 11:50, Asr ≈ 15:09, Maghrib ≈ 17:38, Isha ≈ 18:47
          final DailyPrayerSchedule schedule = service.computeSchedule(
            locationName: 'Ouagadougou',
            latitude: 12.3714,
            longitude: -1.5197,
            utcOffsetHours: 0.0,
            date: testDate,
            method: PrayerCalcMethod.mwl,
          );

          expect(schedule.fajr.hour, 4);
          expect(schedule.fajr.minute, inInclusiveRange(45, 53));
          expect(schedule.sunrise.hour, 6);
          expect(schedule.dhuhr.hour, 11);
          expect(schedule.dhuhr.minute, inInclusiveRange(46, 54));
          expect(schedule.asr.hour, 15);
          expect(schedule.maghrib.hour, 17);
          expect(schedule.isha.hour, 18);
        },
      );

      test(
        '2. La Mecque (21.4225° N, 39.8262° E, UTC+3, méthode Umm al-Qura) le 11/11/2026',
        () {
          // Valeurs de référence attendues (UmmAlQura, Shafi, UTC+3, 11 novembre 2026) :
          // Fajr ≈ 05:06, Sunrise ≈ 06:24, Dhuhr ≈ 12:05, Asr ≈ 15:18, Maghrib ≈ 17:43, Isha = Maghrib + 90 min ≈ 19:13
          final DailyPrayerSchedule schedule = service.computeSchedule(
            locationName: 'La Mecque',
            latitude: 21.4225,
            longitude: 39.8262,
            utcOffsetHours: 3.0,
            date: testDate,
            method: PrayerCalcMethod.ummAlQura,
          );

          expect(schedule.fajr.hour, 5);
          expect(schedule.dhuhr.hour, 12);
          expect(schedule.asr.hour, 15);
          expect(schedule.maghrib.hour, 17);
          expect(
            schedule.isha.difference(schedule.maghrib).inMinutes,
            90,
          );
        },
      );

      test(
        '3. Paris (48.8566° N, 2.3522° E, UTC+1, méthode UOIF 12°/12°) le 11/11/2026',
        () {
          // Valeurs de référence attendues (UOIF 12°/12°, Shafi, UTC+1, 11 novembre 2026) :
          // Fajr ≈ 06:28, Sunrise ≈ 07:53, Dhuhr ≈ 12:35, Asr ≈ 14:49, Maghrib ≈ 17:16, Isha ≈ 18:40
          final DailyPrayerSchedule schedule = service.computeSchedule(
            locationName: 'Paris',
            latitude: 48.8566,
            longitude: 2.3522,
            utcOffsetHours: 1.0,
            date: testDate,
            method: PrayerCalcMethod.uoif,
          );

          expect(schedule.fajr.hour, 6);
          expect(schedule.sunrise.hour, 7);
          expect(schedule.dhuhr.hour, 12);
          expect(schedule.asr.hour, 14);
          expect(schedule.maghrib.hour, 17);
          expect(schedule.isha.hour, 18);
        },
      );

      test(
        'Applique correctement les ajustements manuels (−30 à +30 min) et calcule Imsak/Iftar',
        () {
          final DailyPrayerSchedule base = service.computeSchedule(
            locationName: 'Ouagadougou',
            latitude: 12.3714,
            longitude: -1.5197,
            utcOffsetHours: 0.0,
            date: testDate,
          );
          final DailyPrayerSchedule adjusted = service.computeSchedule(
            locationName: 'Ouagadougou',
            latitude: 12.3714,
            longitude: -1.5197,
            utcOffsetHours: 0.0,
            date: testDate,
            adjustments: const PrayerAdjustmentsConfig(fajr: 5, maghrib: -3),
            isRamadanMode: true,
          );

          expect(adjusted.fajr.difference(base.fajr).inMinutes, 5);
          expect(adjusted.maghrib.difference(base.maghrib).inMinutes, -3);
          expect(adjusted.fajr.difference(adjusted.imsak).inMinutes, 10);
          expect(adjusted.iftar, adjusted.maghrib);
        },
      );
    },
  );
}
