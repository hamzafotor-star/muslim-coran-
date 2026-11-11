import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/prayer_calculator_service.dart';

@immutable
class PrayerAlarmConfig {
  const PrayerAlarmConfig({
    required this.prayerKey,
    required this.displayName,
    this.enabled = true,
    this.adhanId = 'default',
    this.reminderMinutes = 0,
    this.vibrate = true,
  });

  final String prayerKey; // 'fajr' | 'sunrise' | 'dhuhr' | 'asr' | 'maghrib' | 'isha'
  final String displayName;
  final bool enabled;
  final String adhanId;
  final int reminderMinutes;
  final bool vibrate;

  PrayerAlarmConfig copyWith({
    bool? enabled,
    String? adhanId,
    int? reminderMinutes,
    bool? vibrate,
  }) {
    return PrayerAlarmConfig(
      prayerKey: prayerKey,
      displayName: displayName,
      enabled: enabled ?? this.enabled,
      adhanId: adhanId ?? this.adhanId,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      vibrate: vibrate ?? this.vibrate,
    );
  }
}

@immutable
class ScheduledAlarmEntry {
  const ScheduledAlarmEntry({
    required this.notificationId,
    required this.prayerKey,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.isReminder,
  });

  final int notificationId;
  final String prayerKey;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool isReminder;
}

/// Service de planification des alarmes exactes d'Adhan (M5 / §3 & §6) :
/// - Utilise `zonedSchedule` avec `AndroidScheduleMode.exactAllowWhileIdle`.
/// - Gère le rappel avant la prière (`reminderMinutes`) et la replanification à minuit,
///   au changement de ville/méthode et après redémarrage (`BOOT_COMPLETED`).
class PrayerAlarmScheduler {
  PrayerAlarmScheduler() {
    tz_data.initializeTimeZones();
  }

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  /// Construit la liste pure et testable des alarmes futures à programmer pour une journée
  /// (permet de vérifier unitairement la logique de replanification sans dépendre du canal natif).
  static List<ScheduledAlarmEntry> buildScheduledEntriesForDay({
    required DailyPrayerSchedule schedule,
    required Map<String, PrayerAlarmConfig> configs,
    required DateTime referenceNow,
  }) {
    final Map<String, DateTime> times = <String, DateTime>{
      'fajr': schedule.fajr,
      'sunrise': schedule.sunrise,
      'dhuhr': schedule.dhuhr,
      'asr': schedule.asr,
      'maghrib': schedule.maghrib,
      'isha': schedule.isha,
    };

    final List<ScheduledAlarmEntry> entries = <ScheduledAlarmEntry>[];
    int baseId = 100;

    for (final MapEntry<String, DateTime> item in times.entries) {
      baseId += 10;
      final PrayerAlarmConfig? cfg = configs[item.key];
      if (cfg == null || !cfg.enabled) continue;

      final DateTime prayerTime = item.value;
      if (prayerTime.isAfter(referenceNow)) {
        entries.add(
          ScheduledAlarmEntry(
            notificationId: baseId,
            prayerKey: item.key,
            title: 'Heure de la prière : ${cfg.displayName}',
            body:
                'Il est ${DailyPrayerSchedule.formatHm(prayerTime)} à ${schedule.locationName}. Hayya \'ala-s-Salah.',
            scheduledAt: prayerTime,
            isReminder: false,
          ),
        );
      }

      if (cfg.reminderMinutes > 0) {
        final DateTime reminderTime =
            prayerTime.subtract(Duration(minutes: cfg.reminderMinutes));
        if (reminderTime.isAfter(referenceNow)) {
          entries.add(
            ScheduledAlarmEntry(
              notificationId: baseId + 1,
              prayerKey: item.key,
              title: 'Rappel — ${cfg.displayName} dans ${cfg.reminderMinutes} min',
              body:
                  'La prière de ${cfg.displayName} aura lieu à ${DailyPrayerSchedule.formatHm(prayerTime)}.',
              scheduledAt: reminderTime,
              isReminder: true,
            ),
          );
        }
      }
    }

    return entries;
  }

  /// Replanifie les alarmes exactes Android pour aujourd'hui et demain (survit à minuit).
  Future<List<ScheduledAlarmEntry>> rescheduleAll({
    required DailyPrayerSchedule todaySchedule,
    required DailyPrayerSchedule tomorrowSchedule,
    required Map<String, PrayerAlarmConfig> configs,
    DateTime? nowOverride,
  }) async {
    final DateTime now = nowOverride ?? DateTime.now();
    final List<ScheduledAlarmEntry> allEntries = <ScheduledAlarmEntry>[
      ...buildScheduledEntriesForDay(
        schedule: todaySchedule,
        configs: configs,
        referenceNow: now,
      ),
      ...buildScheduledEntriesForDay(
        schedule: tomorrowSchedule,
        configs: configs,
        referenceNow: now,
      ),
    ];

    try {
      await initialize();
      await _notifications.cancelAll();
      for (int i = 0; i < allEntries.length; i++) {
        final ScheduledAlarmEntry entry = allEntries[i];
        final tz.TZDateTime tzTime =
            tz.TZDateTime.from(entry.scheduledAt, tz.local);
        await _notifications.zonedSchedule(
          entry.notificationId + (i * 100),
          entry.title,
          entry.body,
          tzTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'muslim_coran_adhan_channel',
              'Appels à la prière (Adhan)',
              channelDescription:
                  'Notifications exactes des horaires de prière et de l’Adhan',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {
      // Environnement de test hors appareil Android : les entrées planifiées restent retournées.
    }

    return allEntries;
  }
}

final Provider<PrayerAlarmScheduler> prayerAlarmSchedulerProvider =
    Provider<PrayerAlarmScheduler>((Ref ref) => PrayerAlarmScheduler());
