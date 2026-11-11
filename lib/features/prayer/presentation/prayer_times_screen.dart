import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/location_repository.dart';
import '../data/prayer_alarm_scheduler.dart';
import '../domain/prayer_calculator_service.dart';

@immutable
class PrayerState {
  const PrayerState({
    this.city = LocationRepository.defaultOuagadougou,
    this.method = PrayerCalcMethod.mwl,
    this.asrSchool = AsrJuristicSchool.shafi,
    this.adjustments = const PrayerAdjustmentsConfig(),
    this.isRamadanMode = false,
    this.reminderMinutes = 10,
    this.vibrate = true,
    this.selectedAdhan = 'default',
    required this.selectedDate,
    required this.alarms,
  });

  final CityEntity city;
  final PrayerCalcMethod method;
  final AsrJuristicSchool asrSchool;
  final PrayerAdjustmentsConfig adjustments;
  final bool isRamadanMode;
  final int reminderMinutes;
  final bool vibrate;
  final String selectedAdhan;
  final DateTime selectedDate;
  final Map<String, PrayerAlarmConfig> alarms;

  PrayerState copyWith({
    CityEntity? city,
    PrayerCalcMethod? method,
    AsrJuristicSchool? asrSchool,
    PrayerAdjustmentsConfig? adjustments,
    bool? isRamadanMode,
    int? reminderMinutes,
    bool? vibrate,
    String? selectedAdhan,
    DateTime? selectedDate,
    Map<String, PrayerAlarmConfig>? alarms,
  }) {
    return PrayerState(
      city: city ?? this.city,
      method: method ?? this.method,
      asrSchool: asrSchool ?? this.asrSchool,
      adjustments: adjustments ?? this.adjustments,
      isRamadanMode: isRamadanMode ?? this.isRamadanMode,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      vibrate: vibrate ?? this.vibrate,
      selectedAdhan: selectedAdhan ?? this.selectedAdhan,
      selectedDate: selectedDate ?? this.selectedDate,
      alarms: alarms ?? this.alarms,
    );
  }
}

class PrayerController extends StateNotifier<PrayerState> {
  PrayerController(this._scheduler)
      : super(
          PrayerState(
            selectedDate: DateTime.now(),
            alarms: const <String, PrayerAlarmConfig>{
              'fajr': PrayerAlarmConfig(prayerKey: 'fajr', displayName: 'Fajr', enabled: true),
              'sunrise': PrayerAlarmConfig(
                prayerKey: 'sunrise',
                displayName: 'Chourouk',
                enabled: false,
              ),
              'dhuhr': PrayerAlarmConfig(prayerKey: 'dhuhr', displayName: 'Dhuhr', enabled: true),
              'asr': PrayerAlarmConfig(prayerKey: 'asr', displayName: 'Asr', enabled: true),
              'maghrib': PrayerAlarmConfig(
                prayerKey: 'maghrib',
                displayName: 'Maghrib',
                enabled: true,
              ),
              'isha': PrayerAlarmConfig(prayerKey: 'isha', displayName: 'Isha', enabled: true),
            },
          ),
        );

  final PrayerAlarmScheduler _scheduler;
  final PrayerCalculatorService _calc = const PrayerCalculatorService();

  DailyPrayerSchedule buildScheduleForDate(DateTime date) {
    return _calc.computeSchedule(
      locationName: state.city.name,
      latitude: state.city.latitude,
      longitude: state.city.longitude,
      utcOffsetHours: state.city.estimatedUtcOffsetHours,
      date: date,
      method: state.method,
      asrSchool: state.asrSchool,
      adjustments: state.adjustments,
      isRamadanMode: state.isRamadanMode,
    );
  }

  Future<void> _rescheduleAlarms() async {
    final DateTime now = DateTime.now();
    final DailyPrayerSchedule today = buildScheduleForDate(now);
    final DailyPrayerSchedule tomorrow =
        buildScheduleForDate(now.add(const Duration(days: 1)));
    await _scheduler.rescheduleAll(
      todaySchedule: today,
      tomorrowSchedule: tomorrow,
      configs: state.alarms,
    );
  }

  void setCity(CityEntity city) {
    state = state.copyWith(city: city);
    _rescheduleAlarms();
  }

  void setMethod(PrayerCalcMethod method) {
    state = state.copyWith(method: method);
    _rescheduleAlarms();
  }

  void setAsrSchool(AsrJuristicSchool school) {
    state = state.copyWith(asrSchool: school);
    _rescheduleAlarms();
  }

  void setAdjustments(PrayerAdjustmentsConfig adjustments) {
    state = state.copyWith(adjustments: adjustments);
    _rescheduleAlarms();
  }

  void setRamadanMode(bool enabled) {
    state = state.copyWith(isRamadanMode: enabled);
  }

  void setReminderMinutes(int minutes) {
    final Map<String, PrayerAlarmConfig> updated = <String, PrayerAlarmConfig>{
      for (final MapEntry<String, PrayerAlarmConfig> e in state.alarms.entries)
        e.key: e.value.copyWith(reminderMinutes: minutes),
    };
    state = state.copyWith(reminderMinutes: minutes, alarms: updated);
    _rescheduleAlarms();
  }

  void setVibrate(bool vibrate) {
    state = state.copyWith(vibrate: vibrate);
  }

  void setSelectedAdhan(String adhanId) {
    state = state.copyWith(selectedAdhan: adhanId);
  }

  void togglePrayerAlarm(String prayerKey) {
    final PrayerAlarmConfig? current = state.alarms[prayerKey];
    if (current == null) return;
    final Map<String, PrayerAlarmConfig> next =
        Map<String, PrayerAlarmConfig>.from(state.alarms);
    next[prayerKey] = current.copyWith(enabled: !current.enabled);
    state = state.copyWith(alarms: next);
    _rescheduleAlarms();
  }

  void changeSelectedDateByDays(int deltaDays) {
    state = state.copyWith(
      selectedDate: state.selectedDate.add(Duration(days: deltaDays)),
    );
  }
}

final StateNotifierProvider<PrayerController, PrayerState>
    prayerControllerProvider =
    StateNotifierProvider<PrayerController, PrayerState>(
  (Ref ref) => PrayerController(ref.watch(prayerAlarmSchedulerProvider)),
);

final Provider<DailyPrayerSchedule> currentPrayerScheduleProvider =
    Provider<DailyPrayerSchedule>((Ref ref) {
  final PrayerState state = ref.watch(prayerControllerProvider);
  return ref
      .read(prayerControllerProvider.notifier)
      .buildScheduleForDate(state.selectedDate);
});

/// E11 — Écran des horaires de prière :
/// - Ville active + accès direct à E18 (📍) et E12 (⚙).
/// - Navigation jour précédent / suivant (`◀ Mer. 11 nov. ▶`).
/// - Carte « Prochaine prière » en surbrillance avec décompte.
/// - 6 moments (`Fajr`, `Chourouk`, `Dhuhr`, `Asr`, `Maghrib`, `Isha`) avec cloche individuelle 🔔/🔕.
/// - Lignes `Imsak` et `Iftar` affichées lorsque le mode Ramadan est actif.
class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrayerState state = ref.watch(prayerControllerProvider);
    final PrayerController controller =
        ref.read(prayerControllerProvider.notifier);
    final DailyPrayerSchedule schedule = ref.watch(currentPrayerScheduleProvider);

    final List<_PrayerRowItem> rows = <_PrayerRowItem>[
      if (schedule.isRamadanMode)
        _PrayerRowItem(
          key: 'imsak',
          label: 'Imsak (Jeûne)',
          time: schedule.imsak,
          alarmEnabled: false,
          canToggle: false,
        ),
      _PrayerRowItem(
        key: 'fajr',
        label: 'Fajr',
        time: schedule.fajr,
        alarmEnabled: state.alarms['fajr']?.enabled ?? true,
      ),
      _PrayerRowItem(
        key: 'sunrise',
        label: 'Chourouk',
        time: schedule.sunrise,
        alarmEnabled: state.alarms['sunrise']?.enabled ?? false,
      ),
      _PrayerRowItem(
        key: 'dhuhr',
        label: 'Dhuhr',
        time: schedule.dhuhr,
        alarmEnabled: state.alarms['dhuhr']?.enabled ?? true,
      ),
      _PrayerRowItem(
        key: 'asr',
        label: 'Asr',
        time: schedule.asr,
        alarmEnabled: state.alarms['asr']?.enabled ?? true,
      ),
      _PrayerRowItem(
        key: 'maghrib',
        label: schedule.isRamadanMode ? 'Maghrib (Iftar)' : 'Maghrib',
        time: schedule.maghrib,
        alarmEnabled: state.alarms['maghrib']?.enabled ?? true,
      ),
      _PrayerRowItem(
        key: 'isha',
        label: 'Isha',
        time: schedule.isha,
        alarmEnabled: state.alarms['isha']?.enabled ?? true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tabPrayers,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.chooseCity,
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () => context.push(AppRoutes.cityPicker),
          ),
          IconButton(
            tooltip: 'Réglages des prières (E12)',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.prayerSettings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.push(AppRoutes.cityPicker),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.place,
                      size: 18,
                      color: AppColors.primaryDeepGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.city.name} (${state.city.timezone})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isRamadanMode,
                onChanged: controller.setRamadanMode,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                tooltip: 'Jour précédent',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => controller.changeSelectedDateByDays(-1),
              ),
              Text(
                schedule.formattedDate,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                tooltip: 'Jour suivant',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => controller.changeSelectedDateByDays(1),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Carte Prochaine Prière
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryDeepGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${l10n.nextPrayer} : ${schedule.nextPrayerName.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.secondaryLightGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      schedule.nextPrayerFormattedTime,
                      style: const TextStyle(
                        color: AppColors.accentSoftGold,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '(${l10n.inTime(schedule.countdownText)})',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Liste des horaires
          ...rows.map((_PrayerRowItem row) {
            final bool isNext = row.label
                .toLowerCase()
                .startsWith(schedule.nextPrayerName.toLowerCase());
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isNext
                    ? const BorderSide(
                        color: AppColors.accentSoftGold,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: ListTile(
                title: Text(
                  row.label,
                  style: TextStyle(
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      DailyPrayerSchedule.formatHm(row.time),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isNext ? AppColors.primaryDeepGreen : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (row.canToggle)
                      IconButton(
                        tooltip: row.alarmEnabled
                            ? 'Désactiver l’Adhan pour ${row.label}'
                            : 'Activer l’Adhan pour ${row.label}',
                        icon: Icon(
                          row.alarmEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          color: row.alarmEnabled
                              ? AppColors.accentSoftGold
                              : Colors.grey,
                        ),
                        onPressed: () => controller.togglePrayerAlarm(row.key),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Méthode : ${state.method.code} · Asr : ${state.asrSchool.code} · Mode Ramadan : ${state.isRamadanMode ? "Activé (Imsak/Iftar)" : "Désactivé"}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerRowItem {
  const _PrayerRowItem({
    required this.key,
    required this.label,
    required this.time,
    required this.alarmEnabled,
    this.canToggle = true,
  });

  final String key;
  final String label;
  final DateTime time;
  final bool alarmEnabled;
  final bool canToggle;
}
