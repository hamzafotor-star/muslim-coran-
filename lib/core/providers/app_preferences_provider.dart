import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

/// État immuable des préférences globales d'affichage et de langue (E16).
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
    );
  }
}

class AppPreferencesNotifier extends StateNotifier<AppPreferencesState> {
  AppPreferencesNotifier() : super(const AppPreferencesState());

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setArabicFont(ArabicFontFamily font) {
    state = state.copyWith(arabicFont: font);
  }

  void setArabicFontSize(double size) {
    state = state.copyWith(arabicFontSize: size.clamp(18.0, 44.0));
  }

  void setShowTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
  }

  void setDefaultTranslationId(int id) {
    state = state.copyWith(defaultTranslationId: id);
  }

  void setDefaultReciterId(int id) {
    state = state.copyWith(defaultReciterId: id);
  }

  void setWifiOnlyDownloads(bool wifiOnly) {
    state = state.copyWith(wifiOnlyDownloads: wifiOnly);
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }
}

final StateNotifierProvider<AppPreferencesNotifier, AppPreferencesState>
    appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
  (Ref ref) => AppPreferencesNotifier(),
);
