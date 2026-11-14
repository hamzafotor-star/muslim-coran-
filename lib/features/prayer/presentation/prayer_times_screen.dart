import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic_ornaments.dart';
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

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: buildRoyalAppBar(
        title: l10n.tabPrayers,
        subtitle: '${state.city.name} (${state.city.timezone})',
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          // Barre de ville & Mode Ramadan
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => context.push(AppRoutes.cityPicker),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.place,
                              size: 20,
                              color: AppColors.accentSoftGold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${state.city.name} (${state.city.timezone})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ramadan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: state.isRamadanMode,
                    onChanged: controller.setRamadanMode,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Sélecteur de date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                tooltip: 'Jour précédent',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => controller.changeSelectedDateByDays(-1),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentSoftGold.withOpacity(0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppColors.accentSoftGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      schedule.formattedDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Jour suivant',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => controller.changeSelectedDateByDays(1),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Carte Prochaine Prière royale
          RoyalPatternBackground(
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const CustomPaint(
                        size: Size.square(14),
                        painter: IslamicStarPainter(strokeWidth: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.nextPrayer} : ${schedule.nextPrayerName.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.secondaryLightGreen,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        schedule.nextPrayerFormattedTime,
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.goldLight.withOpacity(0.55),
                          ),
                        ),
                        child: Text(
                          '(${l10n.inTime(schedule.countdownText)})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isNext
                      ? AppColors.accentSoftGold
                      : AppColors.accentSoftGold.withOpacity(0.22),
                  width: isNext ? 2 : 0.8,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isNext ? AppColors.goldGradient : null,
                    color: isNext
                        ? null
                        : AppColors.accentSoftGold.withOpacity(0.12),
                  ),
                  child: Icon(
                    _iconForPrayer(row.key),
                    size: 19,
                    color: isNext
                        ? AppColors.emeraldNight
                        : (isDark
                            ? AppColors.goldLight
                            : AppColors.primaryDeepGreen),
                  ),
                ),
                title: Text(
                  row.label,
                  style: TextStyle(
                    fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      DailyPrayerSchedule.formatHm(row.time),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isNext
                            ? (isDark
                                ? AppColors.goldLight
                                : AppColors.primaryDeepGreen)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
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

          const SizedBox(height: 14),
          const OrnamentDivider(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Méthode : ${state.method.code} · Asr : ${state.asrSchool.code} · Mode Ramadan : ${state.isRamadanMode ? "Activé (Imsak/Iftar)" : "Désactivé"}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForPrayer(String key) {
    switch (key) {
      case 'imsak':
      case 'fajr':
        return Icons.wb_twilight_rounded;
      case 'sunrise':
        return Icons.wb_sunny_outlined;
      case 'dhuhr':
        return Icons.light_mode_rounded;
      case 'asr':
        return Icons.wb_cloudy_outlined;
      case 'maghrib':
        return Icons.nights_stay_outlined;
      case 'isha':
        return Icons.bedtime_rounded;
      default:
        return Icons.schedule_rounded;
    }
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
