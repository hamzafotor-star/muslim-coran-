import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

/// État immuable des préférences globales d'affichage, de Tajweed et de langue (E16).
@immutable
class AppPreferencesState {
  const AppPreferencesState({
    this.locale = const Locale('fr'),
    this.themeMode = AppThemeMode.light,
    this.arabicFont = ArabicFontFamily.amiriQuran,
    this.arabicFontSize = 26.0,
    this.showTranslation = true,
    this.defaultTranslationId = 1,
    this.defaultReciterId = 1,
    this.wifiOnlyDownloads = true,
    this.onboardingCompleted = false,
    this.tajweedColorsEnabled = true,
    this.isMushafPageMode = false,
  });

  final Locale locale;
  final AppThemeMode themeMode;
  final ArabicFontFamily arabicFont;
  final double arabicFontSize;
  final bool showTranslation;
  final int defaultTranslationId;
  final int defaultReciterId;
  final bool wifiOnlyDownloads;
  final bool onboardingCompleted;
  final bool tajweedColorsEnabled;
  final bool isMushafPageMode;

  AppPreferencesState copyWith({
    Locale? locale,
    AppThemeMode? themeMode,
    ArabicFontFamily? arabicFont,
    double? arabicFontSize,
    bool? showTranslation,
    int? defaultTranslationId,
    int? defaultReciterId,
    bool? wifiOnlyDownloads,
    bool? onboardingCompleted,
    bool? tajweedColorsEnabled,
    bool? isMushafPageMode,
  }) {
    return AppPreferencesState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      arabicFont: arabicFont ?? this.arabicFont,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      defaultTranslationId: defaultTranslationId ?? this.defaultTranslationId,
      defaultReciterId: defaultReciterId ?? this.defaultReciterId,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      tajweedColorsEnabled: tajweedColorsEnabled ?? this.tajweedColorsEnabled,
      isMushafPageMode: isMushafPageMode ?? this.isMushafPageMode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'locale': locale.languageCode,
        'themeMode': themeMode.name,
        'arabicFont': arabicFont.name,
        'arabicFontSize': arabicFontSize,
        'showTranslation': showTranslation,
        'defaultTranslationId': defaultTranslationId,
        'defaultReciterId': defaultReciterId,
        'wifiOnlyDownloads': wifiOnlyDownloads,
        'onboardingCompleted': onboardingCompleted,
        'tajweedColorsEnabled': tajweedColorsEnabled,
        'isMushafPageMode': isMushafPageMode,
      };

  factory AppPreferencesState.fromJson(Map<String, dynamic> json) {
    final String localeCode = (json['locale'] as String?) ?? 'fr';
    final String themeName = (json['themeMode'] as String?) ?? 'light';
    final String fontName = (json['arabicFont'] as String?) ?? 'amiriQuran';

    final AppThemeMode mode = AppThemeMode.values.firstWhere(
      (AppThemeMode m) => m.name == themeName,
      orElse: () => AppThemeMode.light,
    );
    final ArabicFontFamily font = ArabicFontFamily.values.firstWhere(
      (ArabicFontFamily f) => f.name == fontName,
      orElse: () => ArabicFontFamily.amiriQuran,
    );

    return AppPreferencesState(
      locale: Locale(localeCode),
      themeMode: mode,
      arabicFont: font,
      arabicFontSize:
          ((json['arabicFontSize'] as num?)?.toDouble() ?? 26.0).clamp(18.0, 44.0),
      showTranslation: (json['showTranslation'] as bool?) ?? true,
      defaultTranslationId: (json['defaultTranslationId'] as int?) ?? 1,
      defaultReciterId: (json['defaultReciterId'] as int?) ?? 1,
      wifiOnlyDownloads: (json['wifiOnlyDownloads'] as bool?) ?? true,
      onboardingCompleted: (json['onboardingCompleted'] as bool?) ?? false,
      tajweedColorsEnabled: (json['tajweedColorsEnabled'] as bool?) ?? true,
      isMushafPageMode: (json['isMushafPageMode'] as bool?) ?? false,
    );
  }
}

class AppPreferencesNotifier extends StateNotifier<AppPreferencesState> {
  AppPreferencesNotifier() : super(const AppPreferencesState()) {
    loadFromStorage();
  }

  bool _loaded = false;

  /// Charge les préférences persistées sur le téléphone (appelé au démarrage et dans E01 Splash).
  Future<void> loadFromStorage() async {
    if (_loaded) return;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dir.path, 'app_preferences.json'));
      if (file.existsSync()) {
        final String content = await file.readAsString();
        final Map<String, dynamic> decoded =
            jsonDecode(content) as Map<String, dynamic>;
        if (mounted) {
          state = AppPreferencesState.fromJson(decoded);
        }
      }
      _loaded = true;
    } catch (_) {
      // En environnement de test unitaire sans path_provider natif, on conserve l'état en mémoire.
    }
  }

  Future<void> _persist() async {
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dir.path, 'app_preferences.json'));
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // Ignore en environnement de test unitaire.
    }
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    _persist();
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void setArabicFont(ArabicFontFamily font) {
    state = state.copyWith(
      arabicFont: font,
      tajweedColorsEnabled:
          font == ArabicFontFamily.mushafTajweed ? true : state.tajweedColorsEnabled,
    );
    _persist();
  }

  void setArabicFontSize(double size) {
    state = state.copyWith(arabicFontSize: size.clamp(18.0, 44.0));
    _persist();
  }

  void setShowTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
    _persist();
  }

  void setDefaultTranslationId(int id) {
    state = state.copyWith(defaultTranslationId: id);
    _persist();
  }

  void setDefaultReciterId(int id) {
    state = state.copyWith(defaultReciterId: id);
    _persist();
  }

  void setWifiOnlyDownloads(bool wifiOnly) {
    state = state.copyWith(wifiOnlyDownloads: wifiOnly);
    _persist();
  }

  void setTajweedColorsEnabled(bool enabled) {
    state = state.copyWith(tajweedColorsEnabled: enabled);
    _persist();
  }

  void setMushafPageMode(bool enabled) {
    state = state.copyWith(isMushafPageMode: enabled);
    _persist();
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
    _persist();
  }
}

final StateNotifierProvider<AppPreferencesNotifier, AppPreferencesState>
    appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
  (Ref ref) => AppPreferencesNotifier(),
);
