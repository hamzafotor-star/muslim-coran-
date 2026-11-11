import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/features/prayer/data/prayer_alarm_scheduler.dart';
import 'package:muslim_coran/features/prayer/domain/prayer_calculator_service.dart';

void main() {
  group('Phase 2 — Replanification des alarmes d’Adhan et rappels (§7)', () {
    test(
      'Ne planifie que les prières futures activées et ajoute les rappels pré-prière',
      () {
        const PrayerCalculatorService calc = PrayerCalculatorService();
        final DateTime day = DateTime(2026, 11, 11);
        final DailyPrayerSchedule schedule = calc.computeSchedule(
          locationName: 'Ouagadougou',
          latitude: 12.3714,
          longitude: -1.5197,
          utcOffsetHours: 0.0,
          date: day,
        );

        // Supposons qu'il est 13h00 : Fajr, Chourouk et Dhuhr sont passés ;
        // seuls Asr, Maghrib et Isha doivent être planifiés.
        final DateTime nowAt13h = DateTime(
          schedule.dhuhr.year,
          schedule.dhuhr.month,
          schedule.dhuhr.day,
          13,
          0,
        );

        const Map<String, PrayerAlarmConfig> configs =
            <String, PrayerAlarmConfig>{
          'fajr': PrayerAlarmConfig(
            prayerKey: 'fajr',
            displayName: 'Fajr',
            enabled: true,
            reminderMinutes: 10,
          ),
          'sunrise': PrayerAlarmConfig(
            prayerKey: 'sunrise',
            displayName: 'Chourouk',
            enabled: false,
          ),
          'dhuhr': PrayerAlarmConfig(
            prayerKey: 'dhuhr',
            displayName: 'Dhuhr',
            enabled: true,
            reminderMinutes: 10,
          ),
          'asr': PrayerAlarmConfig(
            prayerKey: 'asr',
            displayName: 'Asr',
            enabled: true,
            reminderMinutes: 15,
          ),
          'maghrib': PrayerAlarmConfig(
            prayerKey: 'maghrib',
            displayName: 'Maghrib',
            enabled: true,
            reminderMinutes: 0,
          ),
          'isha': PrayerAlarmConfig(
            prayerKey: 'isha',
            displayName: 'Isha',
            enabled: false,
          ),
        };

        final List<ScheduledAlarmEntry> scheduled =
            PrayerAlarmScheduler.buildScheduledEntriesForDay(
          schedule: schedule,
          configs: configs,
          referenceNow: nowAt13h,
        );

        // Asr (alarme + rappel 15 min) + Maghrib (alarme seule) = 3 entrées
        expect(scheduled.length, 3);
        expect(
          scheduled.where((ScheduledAlarmEntry e) => e.prayerKey == 'asr').length,
          2,
        );
        expect(
          scheduled.where((ScheduledAlarmEntry e) => e.prayerKey == 'maghrib').length,
          1,
        );
        expect(
          scheduled.where((ScheduledAlarmEntry e) => e.prayerKey == 'isha'),
          isEmpty,
        );
      },
    );
  });
}
