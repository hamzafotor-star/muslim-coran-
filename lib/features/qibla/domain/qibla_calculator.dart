import 'dart:math' as math;

/// Calculateur trigonométrique de la direction et de la distance de la Qibla
/// vers la Sainte Kaaba (`21.4225° N, 39.8262° E`) selon la formule du grand cercle (§3 & §6).
class QiblaCalculator {
  const QiblaCalculator._();

  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;
  static const double _earthRadiusKm = 6371.0;

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);

  /// Calcule l'azimut initial (0° = Nord, 90° = Est, 180° = Sud, 270° = Ouest)
  /// depuis `(latitude, longitude)` vers la Kaaba selon la formule du grand cercle :
  /// `θ = atan2(sin(Δλ), cos(φ1)·tan(φ2) − sin(φ1)·cos(Δλ))`
  static double calculateQiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    final double distanceKm = calculateDistanceToKaabaKm(
      latitude: latitude,
      longitude: longitude,
    );
    if (distanceKm < 0.05) {
      return 0.0;
    }

    final double phi1 = _degToRad(latitude);
    final double phi2 = _degToRad(kaabaLatitude);
    final double deltaLambda = _degToRad(kaabaLongitude - longitude);

    final double y = math.sin(deltaLambda);
    final double x = math.cos(phi1) * math.tan(phi2) -
        math.sin(phi1) * math.cos(deltaLambda);

    final double thetaRad = math.atan2(y, x);
    final double bearing = (_radToDeg(thetaRad) + 360.0) % 360.0;
    return bearing;
  }

  /// Calcule la distance orthodromique (Haversine) en kilomètres jusqu'à la Kaaba.
  static double calculateDistanceToKaabaKm({
    required double latitude,
    required double longitude,
  }) {
    final double dLat = _degToRad(kaabaLatitude - latitude);
    final double dLon = _degToRad(kaabaLongitude - longitude);
    final double lat1 = _degToRad(latitude);
    final double lat2 = _degToRad(kaabaLatitude);

    final double a = math.pow(math.sin(dLat / 2), 2).toDouble() +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(dLon / 2), 2).toDouble();
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Retourne le point cardinal abrégé (ex. `NE`, `ENE`, `ESE`) correspondant à l'angle.
  static String cardinalDirection(double bearingDegrees) {
    const List<String> directions = <String>[
      'N',
      'NE',
      'E',
      'SE',
      'S',
      'SO',
      'O',
      'NO',
    ];
    final int idx = (((bearingDegrees + 22.5) % 360.0) ~/ 45.0) % 8;
    return directions[idx];
  }

  /// Indique si le cap magnétique du téléphone est aligné avec la Qibla (tolérance ±5°).
  static bool isAligned({
    required double deviceHeadingDegrees,
    required double qiblaBearingDegrees,
    double toleranceDegrees = 5.0,
  }) {
    final double diff =
        ((qiblaBearingDegrees - deviceHeadingDegrees + 540.0) % 360.0) - 180.0;
    return diff.abs() <= toleranceDegrees;
  }
}
