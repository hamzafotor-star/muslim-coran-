import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/features/qibla/domain/qibla_calculator.dart';

void main() {
  group('Phase 2 — Calculateur d’angle et de distance de la Qibla (§7)', () {
    test('À La Mecque (21.4225° N, 39.8262° E), la distance est ≈ 0 km', () {
      final double distKm = QiblaCalculator.calculateDistanceToKaabaKm(
        latitude: 21.4225,
        longitude: 39.8262,
      );
      expect(distKm, closeTo(0.0, 0.01));
    });

    test(
      'Depuis Ouagadougou (12.3714° N, -1.5197° O), l’azimut du grand cercle est ≈ 71.39° ENE (et distance ≈ 4 438 km)',
      () {
        // Note documentée (§7) : la maquette E13 illustre "62° NE / 4 450 km" à titre d'exemple visuel ;
        // la formule trigonométrique exacte du grand cercle depuis Ouagadougou (12.3714, -1.5197)
        // vers la Kaaba (21.4225, 39.8262) donne θ = 71.39° (ENE) et d ≈ 4 438 km.
        final double bearing = QiblaCalculator.calculateQiblaBearing(
          latitude: 12.3714,
          longitude: -1.5197,
        );
        final double distKm = QiblaCalculator.calculateDistanceToKaabaKm(
          latitude: 12.3714,
          longitude: -1.5197,
        );

        expect(bearing, closeTo(71.39, 0.2));
        expect(QiblaCalculator.cardinalDirection(bearing), 'E');
        expect(distKm, closeTo(4438.0, 25.0));
      },
    );

    test('Depuis Paris (48.8566° N, 2.3522° E), l’azimut est ≈ 119.2° SE', () {
      final double bearing = QiblaCalculator.calculateQiblaBearing(
        latitude: 48.8566,
        longitude: 2.3522,
      );
      expect(bearing, closeTo(119.16, 0.5));
    });

    test('Détecte correctement l’alignement du magnétomètre (±5°)', () {
      expect(
        QiblaCalculator.isAligned(
          deviceHeadingDegrees: 65.0,
          qiblaBearingDegrees: 67.1,
        ),
        isTrue,
      );
      expect(
        QiblaCalculator.isAligned(
          deviceHeadingDegrees: 80.0,
          qiblaBearingDegrees: 67.1,
        ),
        isFalse,
      );
    });
  });
}
