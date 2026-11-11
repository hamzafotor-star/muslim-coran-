import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fonts/font_download_service.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../audio/data/quran_audio_handler.dart';
import '../../quran/domain/utils/arabic_normalizer.dart';

/// E16 — Réglages généraux :
/// - Langue de l'interface (`Français`, `العربية`, `English` avec RTL automatique).
/// - Thème `[Clair | Sombre | Sépia]`.
/// - Texte arabe : 3 polices OFL embarquées + 6 polices OFL téléchargeables à la demande + Taille avec **aperçu en direct**.
/// - Traduction principale (`Hamidullah FR` / `Transliteration EN`) + interrupteur « Afficher la traduction ».
/// - Récitateur par défaut (choix parmi 12 récitateurs, dont Abdullah Al-Matrood).
/// - Compte & sauvegarde (V1.x) et Confidentialité.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppPreferencesState prefs = ref.watch(appPreferencesProvider);
    final AppPreferencesNotifier notifier =
        ref.read(appPreferencesProvider.notifier);
    final Map<ArabicFontFamily, FontDownloadItemState> fontStates =
        ref.watch(fontDownloadProvider);

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

          // 3. Texte arabe (Police embarquée ou téléchargeable + Taille + Aperçu en direct)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Texte arabe (Polices embarquées & téléchargeables)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Touchez une police avec ⬇ pour la télécharger gratuitement hors ligne.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ArabicFontFamily.values.map((ArabicFontFamily f) {
                      final FontDownloadItemState? fState = fontStates[f];
                      final bool isReady = f.isBuiltIn || (fState?.isReady ?? false);
                      final bool isDownloading =
                          fState?.status == FontInstallStatus.downloading;

                      return ChoiceChip(
                        avatar: isDownloading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : (!isReady
                                ? const Icon(Icons.download_outlined, size: 16)
                                : null),
                        label: Text(f.displayName),
                        selected: prefs.arabicFont == f,
                        onSelected: (_) async {
                          if (isReady) {
                            notifier.setArabicFont(f);
                          } else {
                            final bool ok = await ref
                                .read(fontDownloadProvider.notifier)
                                .downloadAndLoadFont(f);
                            if (ok) {
                              notifier.setArabicFont(f);
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Impossible de télécharger ${f.displayName}. Vérifiez votre connexion Internet.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
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

          // 5. Récitateur par défaut (12 récitateurs dont Abdullah Al-Matrood)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.record_voice_over_outlined,
                color: AppColors.primaryDeepGreen,
              ),
              title: const Text('Récitateur par défaut (12 lecteurs)'),
              subtitle: Text(
                AudioPlaybackState.availableReciters
                    .firstWhere(
                      (ReciterOption r) => r.id == prefs.defaultReciterId,
                      orElse: () => AudioPlaybackState.defaultRecitersFirst,
                    )
                    .name,
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _showReciterPickerSheet(context, ref, prefs, notifier),
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

  void _showReciterPickerSheet(
    BuildContext context,
    WidgetRef ref,
    AppPreferencesState prefs,
    AppPreferencesNotifier notifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return SafeArea(
              child: Column(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Choisir votre récitateur (12 lecteurs)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: AudioPlaybackState.availableReciters.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ReciterOption r =
                            AudioPlaybackState.availableReciters[index];
                        return RadioListTile<int>(
                          value: r.id,
                          groupValue: prefs.defaultReciterId,
                          activeColor: AppColors.primaryDeepGreen,
                          title: Text(
                            r.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(r.style),
                          onChanged: (_) {
                            notifier.setDefaultReciterId(r.id);
                            ref
                                .read(audioControllerProvider.notifier)
                                .setReciter(r);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
