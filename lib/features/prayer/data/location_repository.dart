import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_service.dart';

@immutable
class CityEntity {
  const CityEntity({
    required this.id,
    required this.name,
    required this.nameAscii,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.admin1,
    this.population = 0,
  });

  final int id;
  final String name;
  final String nameAscii;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final String timezone;
  final int population;

  /// Décalage UTC approximatif basé sur le fuseau IANA stocké dans `city`.
  double get estimatedUtcOffsetHours {
    if (timezone == 'Asia/Riyadh') return 3.0;
    if (timezone == 'Africa/Cairo') return 2.0;
    if (timezone == 'Europe/Istanbul') return 3.0;
    if (timezone.startsWith('Europe/Paris') ||
        timezone.startsWith('Europe/Brussels') ||
        timezone == 'Africa/Algiers' ||
        timezone == 'Africa/Tunis' ||
        timezone == 'Africa/Casablanca' ||
        timezone == 'Africa/Lagos' ||
        timezone == 'Africa/Niamey' ||
        timezone == 'Africa/Ndjamena' ||
        timezone == 'Africa/Douala' ||
        timezone == 'Africa/Porto-Novo') {
      return 1.0;
    }
    if (timezone == 'America/Toronto' || timezone == 'America/New_York') {
      return -5.0;
    }
    // Afrique de l'Ouest UEMOA (Ouagadougou, Abidjan, Dakar, Bamako, Conakry, Lomé, Accra, Nouakchott) = UTC+0
    return 0.0;
  }

  factory CityEntity.fromMap(Map<String, Object?> map) {
    return CityEntity(
      id: (map['id'] as num).toInt(),
      name: (map['name'] as String?) ?? '',
      nameAscii: (map['name_ascii'] as String?) ?? '',
      country: (map['country'] as String?) ?? '',
      admin1: map['admin1'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timezone: (map['timezone'] as String?) ?? 'Africa/Ouagadougou',
      population: (map['population'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Dépôt de localisation (M4 / E18) :
/// - Recherche hors ligne dans `quran.db.city`
/// - Acquisition GPS optionnelle via `geolocator`
/// - Persistance du profil actif dans `user.db.location_profile`.
class LocationRepository {
  const LocationRepository(this._dbService);

  final DatabaseService _dbService;

  static const CityEntity defaultOuagadougou = CityEntity(
    id: 2357048,
    name: 'Ouagadougou',
    nameAscii: 'Ouagadougou',
    country: 'BF',
    admin1: 'Centre',
    latitude: 12.3714,
    longitude: -1.5197,
    timezone: 'Africa/Ouagadougou',
    population: 2453496,
  );

  Future<List<CityEntity>> searchCities(String query) async {
    final Database db = await _dbService.quranDb;
    final String q = query.trim();
    if (q.isEmpty) {
      final List<Map<String, Object?>> rows = await db.query(
        'city',
        orderBy: 'population DESC',
        limit: 40,
      );
      return rows.map(CityEntity.fromMap).toList(growable: false);
    }

    final List<Map<String, Object?>> rows = await db.query(
      'city',
      where: 'name LIKE ? OR name_ascii LIKE ? OR country LIKE ?',
      whereArgs: <Object?>['%$q%', '%$q%', '%$q%'],
      orderBy: 'population DESC',
      limit: 40,
    );
    return rows.map(CityEntity.fromMap).toList(growable: false);
  }

  Future<CityEntity> getActiveLocation() async {
    try {
      final Database db = await _dbService.userDb;
      final List<Map<String, Object?>> rows = await db.query(
        'location_profile',
        where: 'is_active = 1',
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) {
        return defaultOuagadougou;
      }
      final Map<String, Object?> r = rows.first;
      return CityEntity(
        id: (r['city_id'] as num?)?.toInt() ?? 0,
        name: (r['name'] as String?) ?? 'Ouagadougou',
        nameAscii: (r['name'] as String?) ?? 'Ouagadougou',
        country: '',
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        timezone: (r['timezone'] as String?) ?? 'Africa/Ouagadougou',
      );
    } catch (_) {
      return defaultOuagadougou;
    }
  }

  Future<void> setActiveCity(CityEntity city, {String source = 'city'}) async {
    final Database db = await _dbService.userDb;
    await db.update('location_profile', <String, Object?>{'is_active': 0});
    await db.insert('location_profile', <String, Object?>{
      'name': city.country.isNotEmpty
          ? '${city.name}, ${city.country}'
          : city.name,
      'latitude': city.latitude,
      'longitude': city.longitude,
      'timezone': city.timezone,
      'source': source,
      'city_id': city.id,
      'is_active': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  /// Demande la position GPS actuelle si l'utilisateur l'autorise (E03 / E18).
  Future<CityEntity?> acquireGpsLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final Position pos = await Geolocator.getCurrentPosition();
    final CityEntity gpsCity = CityEntity(
      id: 0,
      name:
          'Position GPS (${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)})',
      nameAscii: 'GPS',
      country: '',
      latitude: pos.latitude,
      longitude: pos.longitude,
      timezone: 'UTC',
    );
    await setActiveCity(gpsCity, source: 'gps');
    return gpsCity;
  }
}

final Provider<LocationRepository> locationRepositoryProvider =
    Provider<LocationRepository>(
  (Ref ref) => LocationRepository(ref.watch(databaseServiceProvider)),
);
