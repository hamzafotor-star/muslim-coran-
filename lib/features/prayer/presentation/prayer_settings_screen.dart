import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/prayer_calculator_service.dart';
import 'prayer_times_screen.dart';

/// E12 — Réglages des prières et de l'Adhan :
/// - Méthode de calcul (`MWL`, `UOIF`, `UmmAlQura`, `Egyptian`, `ISNA`)
/// - École juridique pour Asr (`Shafi` / `Hanafi`)
/// - Ajustement des minutes par prière (`−30` à `+30` min)
/// - Choix de l'Adhan avec aperçu
/// - Rappel avant la prière (`0`, `5`, `10`, `15`, `30` min)
/// - Vibration
/// - Guide « Optimisation batterie » dédié aux marques Xiaomi, Tecno, Infinix, Samsung (§6).
class PrayerSettingsScreen extends ConsumerWidget {
  const PrayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PrayerState state = ref.watch(prayerControllerProvider);
    final PrayerController controller =
        ref.read(prayerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages des prières'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              title: const Text('Méthode de calcul'),
              subtitle: Text(state.method.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMethodPicker(context, state.method, controller),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('École juridique (Asr)'),
              subtitle: Text(state.asrSchool.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  _showAsrSchoolPicker(context, state.asrSchool, controller),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Ajustement (minutes par prière)'),
              subtitle: Text(
                'Fajr ${state.adjustments.fajr}m · Dhuhr ${state.adjustments.dhuhr}m · '
                'Asr ${state.adjustments.asr}m · Maghrib ${state.adjustments.maghrib}m · Isha ${state.adjustments.isha}m',
              ),
              trailing: const Icon(Icons.tune),
              onTap: () =>
                  _showAdjustmentsDialog(context, state.adjustments, controller),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Son de l’Adhan'),
              subtitle: Text(
                state.selectedAdhan == 'default'
                    ? 'Adhan classique (Médine / Son libre de droits CC0)'
                    : 'Bip de notification discret',
              ),
              trailing: const Icon(Icons.volume_up_outlined),
              onTap: () => _showAdhanPicker(context, state, controller),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Rappel avant la prière',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <int>[0, 5, 10, 15, 30].map((int mins) {
                      return ChoiceChip(
                        label: Text(mins == 0 ? 'Aucun' : '$mins min'),
                        selected: state.reminderMinutes == mins,
                        onSelected: (_) => controller.setReminderMinutes(mins),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Vibration lors de l’Adhan'),
              value: state.vibrate,
              onChanged: controller.setVibrate,
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Mode Ramadan (Afficher Imsak & Iftar)'),
              subtitle: const Text(
                'Ajoute les horaires d’Imsak (−10 min avant Fajr) et d’Iftar sur l’écran E11',
              ),
              value: state.isRamadanMode,
              onChanged: controller.setRamadanMode,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.secondaryLightGreen.withValues(alpha: 0.45),
            child: ListTile(
              leading: const Icon(
                Icons.battery_saver_outlined,
                color: AppColors.primaryDeepGreen,
              ),
              title: const Text(
                'Optimisation batterie',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Guide d’exclusion pour Xiaomi, Tecno, Infinix et Samsung (garantit l’Adhan à l’heure exacte)',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => _showBatteryOptimizationGuide(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showMethodPicker(
    BuildContext context,
    PrayerCalcMethod current,
    PrayerController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: PrayerCalcMethod.values.map((PrayerCalcMethod m) {
              return RadioListTile<PrayerCalcMethod>(
                value: m,
                groupValue: current,
                title: Text(m.code),
                subtitle: Text(m.label),
                onChanged: (PrayerCalcMethod? val) {
                  if (val != null) {
                    controller.setMethod(val);
                  }
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAsrSchoolPicker(
    BuildContext context,
    AsrJuristicSchool current,
    PrayerController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AsrJuristicSchool.values.map((AsrJuristicSchool s) {
              return RadioListTile<AsrJuristicSchool>(
                value: s,
                groupValue: current,
                title: Text(s.label),
                onChanged: (AsrJuristicSchool? val) {
                  if (val != null) {
                    controller.setAsrSchool(val);
                  }
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAdjustmentsDialog(
    BuildContext context,
    PrayerAdjustmentsConfig current,
    PrayerController controller,
  ) {
    int fajr = current.fajr;
    int sunrise = current.sunrise;
    int dhuhr = current.dhuhr;
    int asr = current.asr;
    int maghrib = current.maghrib;
    int isha = current.isha;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Widget buildSlider(
              String label,
              int value,
              ValueChanged<int> onChanged,
            ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('$label : ${value >= 0 ? "+$value" : "$value"} min'),
                  Slider(
                    min: -30,
                    max: 30,
                    divisions: 60,
                    value: value.toDouble(),
                    onChanged: (double v) =>
                        setDialogState(() => onChanged(v.round())),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Ajustements (−30 à +30 min)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    buildSlider('Fajr', fajr, (int v) => fajr = v),
                    buildSlider('Chourouk', sunrise, (int v) => sunrise = v),
                    buildSlider('Dhuhr', dhuhr, (int v) => dhuhr = v),
                    buildSlider('Asr', asr, (int v) => asr = v),
                    buildSlider('Maghrib', maghrib, (int v) => maghrib = v),
                    buildSlider('Isha', isha, (int v) => isha = v),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    controller.setAdjustments(
                      PrayerAdjustmentsConfig(
                        fajr: fajr,
                        sunrise: sunrise,
                        dhuhr: dhuhr,
                        asr: asr,
                        maghrib: maghrib,
                        isha: isha,
                      ),
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdhanPicker(
    BuildContext context,
    PrayerState state,
    PrayerController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                value: 'default',
                groupValue: state.selectedAdhan,
                title: const Text('Adhan classique (Médine / CC0)'),
                subtitle: const Text('Appel complet à la prière'),
                onChanged: (String? val) {
                  if (val != null) controller.setSelectedAdhan(val);
                  Navigator.of(ctx).pop();
                },
              ),
              RadioListTile<String>(
                value: 'beep',
                groupValue: state.selectedAdhan,
                title: const Text('Notification discrète'),
                subtitle: const Text('Signal sonore court pour le bureau'),
                onChanged: (String? val) {
                  if (val != null) controller.setSelectedAdhan(val);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBatteryOptimizationGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (BuildContext context, ScrollController scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: const <Widget>[
                Text(
                  'Guide : Garantir l’Adhan en arrière-plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Certains constructeurs bloquent les alarmes exactes lorsque l’écran est éteint. '
                  'Suivez les étapes correspondant à votre téléphone :',
                ),
                SizedBox(height: 16),
                _BrandBatteryCard(
                  brand: 'Tecno (HiOS) & Infinix (XOS)',
                  steps:
                      '1. Ouvrez « Phone Master » > Gestion du démarrage automatique (Auto-start).\n'
                      '2. Activez « Muslim Coran ».\n'
                      '3. Dans Paramètres > Batterie > Optimisation de la batterie, sélectionnez « Ne pas optimiser » pour Muslim Coran.',
                ),
                _BrandBatteryCard(
                  brand: 'Xiaomi / Redmi / POCO (MIUI & HyperOS)',
                  steps:
                      '1. Paramètres > Applications > Gérer les applications > Muslim Coran.\n'
                      '2. Activez « Démarrage automatique » (Autostart).\n'
                      '3. Dans « Économiseur de batterie », choisissez « Aucune restriction ».',
                ),
                _BrandBatteryCard(
                  brand: 'Samsung (One UI)',
                  steps:
                      '1. Paramètres > Applications > Muslim Coran > Batterie.\n'
                      '2. Sélectionnez « Non restreinte ».\n'
                      '3. Vérifiez dans Maintenance de l’appareil > Batterie > Limites d’utilisation en arrière-plan que Muslim Coran n’est pas en veille profonde.',
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BrandBatteryCard extends StatelessWidget {
  const _BrandBatteryCard({
    required this.brand,
    required this.steps,
  });

  final String brand;
  final String steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              brand,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDeepGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(steps, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
