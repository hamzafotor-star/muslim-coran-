import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../prayer/presentation/prayer_times_screen.dart';
import '../domain/qibla_calculator.dart';

/// E13 — Boussole Qibla (M6 / RF-12 & RF-13) :
/// - Flèche en temps réel orientée vers la Sainte Kaaba (`21.4225° N, 39.8262° E`).
/// - Distance orthodromique en kilomètres et direction cardinale.
/// - Vibration haptique légère et couleur verte lorsque l'alignement est atteint (±5°).
/// - Avertissement d'interférence magnétique + dialogue de calibration en « 8 ».
/// - Mode de repli sans capteur si le magnétomètre est absent sur l'appareil.
class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _deviceHeading;
  double? _accuracy;
  bool _sensorAvailable = true;
  bool _wasAligned = false;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  void _initCompass() {
    final Stream<CompassEvent>? stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _sensorAvailable = false);
      return;
    }
    _compassSub = stream.listen(
      (CompassEvent event) {
        if (!mounted) return;
        setState(() {
          _deviceHeading = event.heading;
          _accuracy = event.accuracy;
          _sensorAvailable = event.heading != null;
        });
      },
      onError: (_) {
        if (mounted) {
          setState(() => _sensorAvailable = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  void _showCalibrationDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Calibrer le magnétomètre'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.all_inclusive,
                size: 56,
                color: AppColors.primaryDeepGreen,
              ),
              SizedBox(height: 12),
              Text(
                '1. Éloignez le téléphone des objets métalliques ou étuis aimantés.\n'
                '2. Effectuez 3 fois un mouvement ample en forme de « 8 » dans l’air.\n'
                '3. Posez ensuite le téléphone bien à plat pour lire la direction de la Qibla.',
                style: TextStyle(height: 1.45),
              ),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PrayerState prayerState = ref.watch(prayerControllerProvider);

    final double qiblaBearing = QiblaCalculator.calculateQiblaBearing(
      latitude: prayerState.city.latitude,
      longitude: prayerState.city.longitude,
    );
    final double distanceKm = QiblaCalculator.calculateDistanceToKaabaKm(
      latitude: prayerState.city.latitude,
      longitude: prayerState.city.longitude,
    );
    final String cardinal = QiblaCalculator.cardinalDirection(qiblaBearing);

    final double heading = _deviceHeading ?? 0.0;
    final bool isAligned = _sensorAvailable &&
        _deviceHeading != null &&
        QiblaCalculator.isAligned(
          deviceHeadingDegrees: heading,
          qiblaBearingDegrees: qiblaBearing,
        );

    if (isAligned && !_wasAligned) {
      _wasAligned = true;
      HapticFeedback.lightImpact();
    } else if (!isAligned) {
      _wasAligned = false;
    }

    final bool hasMagneticInterference =
        _accuracy != null && _accuracy! > 30.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tabQibla,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.chooseCity,
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () => context.push(AppRoutes.cityPicker),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: <Widget>[
                Text(
                  prayerState.city.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kaaba : ${qiblaBearing.round()}° $cardinal · Distance : ${distanceKm.round()} km',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryDeepGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasMagneticInterference) ...<Widget>[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Interférence magnétique détectée : calibrez le capteur en dessinant un « 8 ».',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Cadran Boussole
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAligned
                        ? AppColors.primaryDeepGreen
                        : AppColors.accentSoftGold,
                    width: isAligned ? 5 : 3,
                  ),
                  color: isAligned
                      ? AppColors.secondaryLightGreen.withValues(alpha: 0.35)
                      : Theme.of(context).cardTheme.color,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    const Positioned(
                      top: 12,
                      child: Text(
                        'N',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Positioned(
                      bottom: 12,
                      child: Text(
                        'S',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Positioned(
                      left: 14,
                      child: Text(
                        'O',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Positioned(
                      right: 14,
                      child: Text(
                        'E',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Transform.rotate(
                      angle:
                          ((qiblaBearing - heading) * (math.pi / 180.0)),
                      child: Icon(
                        Icons.navigation,
                        size: 96,
                        color: isAligned
                            ? AppColors.primaryDeepGreen
                            : AppColors.accentSoftGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Column(
              children: <Widget>[
                if (!_sensorAvailable)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mode de repli sans magnétomètre : orientez le haut de votre téléphone à ${qiblaBearing.round()}° ($cardinal) par rapport au Nord géographique.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primaryDeepGreen,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        isAligned
                            ? Icons.check_circle
                            : Icons.compass_calibration_outlined,
                        color: isAligned
                            ? AppColors.primaryDeepGreen
                            : AppColors.accentSoftGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAligned
                            ? l10n.alignQibla
                            : 'Cap actuel : ${heading.round()}° — Tournez vers ${qiblaBearing.round()}° $cardinal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAligned ? AppColors.primaryDeepGreen : null,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showCalibrationDialog,
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.calibrateSensor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
