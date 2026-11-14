import 'package:flutter/material.dart';

/// Palette officielle de la charte graphique « Qurana » (§0 du Cahier de maquettes).
///
/// Les constantes historiques (`primaryDeepGreen`, `secondaryLightGreen`,
/// `accentSoftGold`, fonds, cartes et textes) sont conservées à l'identique ;
/// la palette « royale » émeraude & or vient les enrichir.
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

  // ---------------------------------------------------------------------------
  // Palette royale « Qurana » — émeraude & or
  // ---------------------------------------------------------------------------

  /// Émeraude nuit `#0A3D28` (départ des dégradés royaux).
  static const Color emeraldNight = Color(0xFF0A3D28);

  /// Émeraude royal `#176B43` (arrivée des dégradés royaux).
  static const Color emeraldRoyal = Color(0xFF176B43);

  /// Émeraude lumineux pour les accents sur fonds sombres.
  static const Color emeraldGlow = Color(0xFF47A778);

  /// Or clair `#E5C158` (reflets, filets dorés, textes lumineux).
  static const Color goldLight = Color(0xFFE5C158);

  /// Or profond pour les ombres des médaillons.
  static const Color goldDeep = Color(0xFF9C7A12);

  /// Ivoire « parchemin » pour les cadres de style Mushaf.
  static const Color parchment = Color(0xFFFBF6E9);

  /// Dégradé royal émeraude `#0A3D28` → `#0F5132` → `#176B43`.
  static const LinearGradient royalEmeraldGradient = LinearGradient(
    colors: <Color>[emeraldNight, primaryDeepGreen, emeraldRoyal],
    stops: <double>[0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé or `#C9A227` → `#E5C158` → `#C9A227`.
  static const LinearGradient goldGradient = LinearGradient(
    colors: <Color>[accentSoftGold, goldLight, accentSoftGold],
    stops: <double>[0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ombre douce standard des cartes élégantes.
  static List<BoxShadow> softShadow({double opacity = 0.08}) => <BoxShadow>[
        BoxShadow(
          color: emeraldNight.withOpacity(opacity),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Halo doré utilisé autour des médaillons et du compte à rebours.
  static List<BoxShadow> goldGlow({double opacity = 0.35}) => <BoxShadow>[
        BoxShadow(
          color: goldLight.withOpacity(opacity),
          blurRadius: 22,
          spreadRadius: 1,
        ),
      ];
}
