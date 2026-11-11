import 'package:flutter/material.dart';

/// Palette officielle de la charte graphique « Muslim Coran » (§0 du Cahier de maquettes).
class AppColors {
  const AppColors._();

  /// Couleur principale : Vert profond `#0F5132`
  static const Color primaryDeepGreen = Color(0xFF0F5132);

  /// Couleur secondaire : Vert clair `#D1E7DD`
  static const Color secondaryLightGreen = Color(0xFFD1E7DD);

  /// Accent : Or doux `#C9A227`
  static const Color accentSoftGold = Color(0xFFC9A227);

  /// Fonds des 3 thèmes : Clair `#FFFFFF`, Sombre `#121614`, Sépia `#F4ECD8`
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121614);
  static const Color backgroundSepia = Color(0xFFF4ECD8);

  /// Surfaces de cartes
  static const Color cardLight = Color(0xFFF8FAF9);
  static const Color cardDark = Color(0xFF1B211E);
  static const Color cardSepia = Color(0xFFFAF3E3);

  /// Textes principaux : `#1B1F1D` (clair/sépia), `#E8ECEA` (sombre)
  static const Color textPrimaryLight = Color(0xFF1B1F1D);
  static const Color textPrimaryDark = Color(0xFFE8ECEA);
  static const Color textSecondaryLight = Color(0xFF525E58);
  static const Color textSecondaryDark = Color(0xFFA7B4AE);
}
