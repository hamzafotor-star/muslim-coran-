import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/location_repository.dart';
import 'prayer_times_screen.dart';

/// E18 — Choix de la ville (100 % hors ligne depuis `quran.db.city`) :
/// - Recherche instantanée (Ouagadougou, Bobo-Dioulasso, Abidjan, Dakar, Bamako, Niamey, La Mecque, Paris…).
/// - Bouton `📍 Utiliser ma position` (GPS via `geolocator`).
/// - Possibilité de saisir latitude et longitude à la main.
class CityPickerScreen extends ConsumerStatefulWidget {
  const CityPickerScreen({super.key});

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CityEntity> _cities = const <CityEntity>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final List<CityEntity> rows =
        await ref.read(locationRepositoryProvider).searchCities(query);
    if (mounted) {
      setState(() {
        _cities = rows;
        _loading = false;
      });
    }
  }

  Future<void> _selectCity(CityEntity city, {String source = 'city'}) async {
    await ref.read(locationRepositoryProvider).setActiveCity(city, source: source);
    ref.read(prayerControllerProvider.notifier).setCity(city);
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _useGpsLocation() async {
    final CityEntity? gpsCity =
        await ref.read(locationRepositoryProvider).acquireGpsLocation();
    if (gpsCity != null) {
      ref.read(prayerControllerProvider.notifier).setCity(gpsCity);
      if (mounted) {
        context.pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position GPS indisponible ou refusée. Vous pouvez choisir une ville dans la liste hors ligne.',
          ),
        ),
      );
    }
  }

  Future<void> _showManualCoordinatesDialog() async {
    final TextEditingController nameCtrl =
        TextEditingController(text: 'Position manuelle');
    final TextEditingController latCtrl = TextEditingController(text: '12.3714');
    final TextEditingController lonCtrl = TextEditingController(text: '-1.5197');

    final CityEntity? custom = await showDialog<CityEntity>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Saisir Latitude / Longitude'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom du lieu'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: latCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude (−90 à +90)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lonCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude (−180 à +180)',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final double? lat = double.tryParse(latCtrl.text.trim());
                final double? lon = double.tryParse(lonCtrl.text.trim());
                if (lat == null ||
                    lon == null ||
                    lat < -90 ||
                    lat > 90 ||
                    lon < -180 ||
                    lon > 180) {
                  return;
                }
                Navigator.of(ctx).pop(
                  CityEntity(
                    id: 0,
                    name: nameCtrl.text.trim().isEmpty
                        ? 'Lieu manuel'
                        : nameCtrl.text.trim(),
                    nameAscii: 'Manual',
                    country: '',
                    latitude: lat,
                    longitude: lon,
                    timezone: 'UTC',
                  ),
                );
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (custom != null) {
      await _selectCity(custom, source: 'manual');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chooseCity),
        actions: <Widget>[
          IconButton(
            tooltip: 'Saisir latitude et longitude à la main',
            icon: const Icon(Icons.edit_location_alt_outlined),
            onPressed: _showManualCoordinatesDialog,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher (ex. Ouagadougou, Abidjan, Dakar…)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _useGpsLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: AppColors.primaryDeepGreen,
                ),
                label: Text(l10n.useMyLocation),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cities.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CityEntity city = _cities[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.location_city,
                            color: AppColors.primaryDeepGreen,
                          ),
                          title: Text(
                            '${city.name}, ${city.country}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Lat ${city.latitude.toStringAsFixed(2)}° · Lon ${city.longitude.toStringAsFixed(2)}° · ${city.timezone}',
                          ),
                          onTap: () => _selectCity(city),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
