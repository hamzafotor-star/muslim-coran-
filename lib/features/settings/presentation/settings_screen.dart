import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../audio/data/quran_audio_handler.dart';
import '../../quran/domain/utils/arabic_normalizer.dart';

/// E16 — Réglages généraux :
/// - Langue de l'interface (`Français`, `العربية`, `English` avec RTL automatique).
/// - Thème `[Clair | Sombre | Sépia]`.
/// - Texte arabe : Police (3 polices OFL) + Taille avec **aperçu en direct**.
/// - Traduction principale (`Hamidullah FR` / `Transliteration EN`) + interrupteur « Afficher la traduction ».
/// - Récitateur par défaut.
/// - Compte & sauvegarde (V1.x) et Confidentialité.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
    final AppPreferencesNotifier notifier =
        ref.read(appPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // 1. Langue de l'interface
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Langue de l’interface',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'fr',
                        label: Text('Français'),
                      ),
                      ButtonSegment<String>(
                        value: 'ar',
                        label: Text('العربية'),
                      ),
                      ButtonSegment<String>(
                        value: 'en',
                        label: Text('English'),
                      ),
                    ],
                    selected: <String>{prefs.locale.languageCode},
                    onSelectionChanged: (Set<String> s) {
                      notifier.setLocale(Locale(s.first));
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. Thème Clair / Sombre / Sépia
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Thème',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<AppThemeMode>(
                    segments: <ButtonSegment<AppThemeMode>>[
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.dark,
                        label: Text(l10n.themeDark),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.sepia,
                        label: Text(l10n.themeSepia),
                      ),
                    ],
                    selected: <AppThemeMode>{prefs.themeMode},
                    onSelectionChanged: (Set<AppThemeMode> s) {
                      notifier.setThemeMode(s.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Texte arabe (Police + Taille + Aperçu en direct)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Texte arabe (Polices sous licence OFL)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ArabicFontFamily.values.map((ArabicFontFamily f) {
                      return ChoiceChip(
                        label: Text(f.displayName),
                        selected: prefs.arabicFont == f,
                        onSelected: (_) => notifier.setArabicFont(f),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      const Text('Taille :'),
                      Expanded(
                        child: Slider(
                          min: 20,
                          max: 42,
                          divisions: 11,
                          value: prefs.arabicFontSize,
                          label: '${prefs.arabicFontSize.round()} pt',
                          onChanged: notifier.setArabicFontSize,
                        ),
                      ),
                      Text('${prefs.arabicFontSize.round()} pt'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLightGreen.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ArabicNormalizer.basmalaUthmani,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: prefs.arabicFont.fontFamily,
                        fontSize: prefs.arabicFontSize,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Traduction principale & affichage
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: const Text('Traduction principale'),
                  subtitle: Text(
                    prefs.defaultTranslationId == 1
                        ? 'Français — Muhammad Hamidullah'
                        : 'Anglais / Translittération phonétique',
                  ),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () {
                    notifier.setDefaultTranslationId(
                      prefs.defaultTranslationId == 1 ? 2 : 1,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Afficher la traduction'),
                  value: prefs.showTranslation,
                  onChanged: notifier.setShowTranslation,
                ),
              ],
            ),
          ),

          // 5. Récitateur par défaut
          Card(
            child: ListTile(
              title: const Text('Récitateur par défaut'),
              subtitle: Text(
                AudioPlaybackState.availableReciters
                    .firstWhere(
                      (ReciterOption r) => r.id == prefs.defaultReciterId,
                      orElse: () => AudioPlaybackState.defaultRecitersFirst,
                    )
                    .name,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final int nextId = prefs.defaultReciterId == 1 ? 2 : 1;
                notifier.setDefaultReciterId(nextId);
                final ReciterOption chosen = AudioPlaybackState.availableReciters
                    .firstWhere((ReciterOption r) => r.id == nextId);
                ref.read(audioControllerProvider.notifier).setReciter(chosen);
              },
            ),
          ),

          // 6. Compte & Sauvegarde + Confidentialité
          const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('Compte & sauvegarde'),
              subtitle: Text(
                'Mode 100 % hors ligne actif sans compte. Synchronisation cloud optionnelle prévue en V1.x.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.primaryDeepGreen,
              ),
              title: const Text('Confidentialité & Éthique'),
              subtitle: const Text(
                'Aucun traceur, aucune publicité, localisation traitée exclusivement sur votre appareil.',
              ),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Politique de Confidentialité'),
                    content: const Text(
                      '1. Aucune collecte de données personnelles : vos signets, notes et positions de lecture restent stockés localement dans user.db.\n'
                      '2. Localisation : les coordonnées GPS ou la ville choisie servent uniquement au calcul mathématique local des prières et de la Qibla.\n'
                      '3. Zéro publicité, zéro SDK d’analyse ou de pistage.',
                      style: TextStyle(height: 1.45),
                    ),
                    actions: <Widget>[
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Fermer'),
                      ),
                    ],
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
