import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Couleurs indicatives officielles du Mushaf Tajweed :
/// - Rouge (#C62828)  : Madd (Prolongation longue / Maddah / Alef suscrit)
/// - Vert (#168039)   : Ghunnah, Ikhfâ’ & Idghâm avec nasalisation (نّ, مّ, Tanween)
/// - Bleu (#1565C0)   : Qalqalah (Rebond sur ق ط ب ج د avec Sukun)
/// - Orange (#D84315) : Iqlâb (conversion en Meem) & Tafkhîm (lettres emphatiques)
class TajweedColors {
  const TajweedColors._();

  static const Color maddRed = Color(0xFFC62828);
  static const Color ghunnahGreen = Color(0xFF168039);
  static const Color qalqalahBlue = Color(0xFF1565C0);
  static const Color iqlabTafkhimOrange = Color(0xFFD84315);
}

/// Analyseur et moteur de rendu coloré du texte coranique Uthmani selon les règles de Tajweed.
class TajweedTextView extends StatelessWidget {
  const TajweedTextView({
    super.key,
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.enableTajweedColors,
    this.textAlign = TextAlign.right,
    this.baseColor,
    this.trailingSpan,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final bool enableTajweedColors;
  final TextAlign textAlign;
  final Color? baseColor;
  final InlineSpan? trailingSpan;

  static bool _isCombiningMark(int codeUnit) {
    return (codeUnit >= 0x0610 && codeUnit <= 0x061A) ||
        (codeUnit >= 0x064B && codeUnit <= 0x065F) ||
        codeUnit == 0x0670 ||
        (codeUnit >= 0x06D6 && codeUnit <= 0x06ED);
  }

  static const Set<String> _qalqalahLetters = <String>{
    'ق',
    'ط',
    'ب',
    'ج',
    'د',
  };

  static const Set<String> _tafkhimLetters = <String>{
    'خ',
    'ص',
    'ض',
    'غ',
    'ط',
    'ق',
    'ظ',
  };

  /// Découpe le texte Uthmani en grappes (lettre de base + ses signes diacritiques)
  /// et attribue la couleur de Tajweed correspondante.
  static List<TextSpan> buildTajweedSpans(
    String uthmaniText, {
    Color? defaultColor,
  }) {
    if (uthmaniText.isEmpty) return const <TextSpan>[];

    final List<String> clusters = <String>[];
    final StringBuffer current = StringBuffer();

    for (int i = 0; i < uthmaniText.length; i++) {
      final int cu = uthmaniText.codeUnitAt(i);
      if (_isCombiningMark(cu) && current.isNotEmpty) {
        current.writeCharCode(cu);
      } else {
        if (current.isNotEmpty) {
          clusters.add(current.toString());
          current.clear();
        }
        current.writeCharCode(cu);
      }
    }
    if (current.isNotEmpty) {
      clusters.add(current.toString());
    }

    final List<TextSpan> spans = <TextSpan>[];
    for (int i = 0; i < clusters.length; i++) {
      final String cluster = clusters[i];
      final Color? color = _classifyCluster(cluster, i, clusters);
      spans.add(
        TextSpan(
          text: cluster,
          style: color != null
              ? TextStyle(color: color)
              : (defaultColor != null ? TextStyle(color: defaultColor) : null),
        ),
      );
    }
    return spans;
  }

  static Color? _classifyCluster(
    String cluster,
    int index,
    List<String> allClusters,
  ) {
    if (cluster.isEmpty) return null;
    final String baseChar = cluster[0];

    // 1. Iqlâb : présence du petit Meem de conversion (\u06E2 ou \u06ED)
    if (cluster.contains('\u06E2') || cluster.contains('\u06ED')) {
      return TajweedColors.iqlabTafkhimOrange;
    }

    // 2. Madd (Prolongation) : signe Maddah (\u0653, \u06E4), Alef Maddah (آ), ou Alef suscrit (\u0670)
    if (baseChar == 'آ' ||
        cluster.contains('\u0653') ||
        cluster.contains('\u06E4') ||
        cluster.contains('\u0670')) {
      return TajweedColors.maddRed;
    }

    // 3. Qalqalah : lettre de Qalqalah (ق ط ب ج د) portant un Sukun (\u0652 ou \u06E1)
    if (_qalqalahLetters.contains(baseChar) &&
        (cluster.contains('\u0652') || cluster.contains('\u06E1'))) {
      return TajweedColors.qalqalahBlue;
    }

    // 4. Ghunnah / Ikhfâ’ / Idghâm :
    // - Noon ou Meem avec Shadda (\u0651)
    // - Noon avec Sukun ou voyelle Tanween (\u064B, \u064C, \u064D)
    final bool hasShadda = cluster.contains('\u0651');
    final bool hasTanween = cluster.contains('\u064B') ||
        cluster.contains('\u064C') ||
        cluster.contains('\u064D');
    final bool hasSukun =
        cluster.contains('\u0652') || cluster.contains('\u06E1');

    if ((baseChar == 'ن' || baseChar == 'م') && hasShadda) {
      return TajweedColors.ghunnahGreen;
    }
    if (hasTanween) {
      return TajweedColors.ghunnahGreen;
    }
    if (baseChar == 'ن' && (hasSukun || cluster.length == 1)) {
      return TajweedColors.ghunnahGreen;
    }

    // 5. Tafkhîm (Emphase sur خ ص ض غ ط ق ظ)
    if (_tafkhimLetters.contains(baseChar)) {
      return TajweedColors.iqlabTafkhimOrange;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveBaseColor =
        baseColor ?? Theme.of(context).colorScheme.onSurface;

    final List<InlineSpan> children = enableTajweedColors
        ? <InlineSpan>[
            ...buildTajweedSpans(text, defaultColor: effectiveBaseColor),
            if (trailingSpan != null) trailingSpan!,
          ]
        : <InlineSpan>[
            TextSpan(
              text: text,
              style: TextStyle(color: effectiveBaseColor),
            ),
            if (trailingSpan != null) trailingSpan!,
          ];

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      text: TextSpan(
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: 1.95,
          color: effectiveBaseColor,
        ),
        children: children,
      ),
    );
  }
}

/// Barre de légende des couleurs indicatives du Mushaf Tajweed (affichée en haut du lecteur E06/E07).
class TajweedLegendBanner extends StatelessWidget {
  const TajweedLegendBanner({
    super.key,
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryLightGreen.withOpacity(0.35),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryDeepGreen.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.palette_outlined,
                size: 18,
                color: AppColors.primaryDeepGreen,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Mushaf Tajweed — Couleurs indicatives',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryDeepGreen,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showTajweedGuideDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.help_outline,
                        size: 16,
                        color: AppColors.primaryDeepGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Guide',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDeepGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 26,
                child: Switch(
                  value: enabled,
                  activeColor: AppColors.primaryDeepGreen,
                  onChanged: onToggle,
                ),
              ),
            ],
          ),
          if (enabled) ...<Widget>[
            const SizedBox(height: 6),
            const Wrap(
              spacing: 12,
              runSpacing: 4,
              children: <Widget>[
                _LegendDot(
                  color: TajweedColors.maddRed,
                  label: 'Madd (Prolongation)',
                ),
                _LegendDot(
                  color: TajweedColors.ghunnahGreen,
                  label: 'Ghunnah / Ikhfâ’',
                ),
                _LegendDot(
                  color: TajweedColors.qalqalahBlue,
                  label: 'Qalqalah (Rebond)',
                ),
                _LegendDot(
                  color: TajweedColors.iqlabTafkhimOrange,
                  label: 'Iqlâb / Tafkhîm',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showTajweedGuideDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Guide des couleurs du Mushaf Tajweed'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _GuideRuleRow(
                color: TajweedColors.maddRed,
                title: 'Rouge — Madd (المد)',
                description:
                    'Indique une prolongation de la voyelle (2, 4 ou 6 temps) sur les signes de Maddah (آ) et l’Alef suscrit (ـٰ).',
              ),
              SizedBox(height: 12),
              _GuideRuleRow(
                color: TajweedColors.ghunnahGreen,
                title: 'Vert — Ghunnah & Ikhfâ’ (الغنة والإخفاء)',
                description:
                    'Indique la nasalisation (2 temps) sur نّ, مّ, le Tanween (ً ٍ ٌ) et le Noon Sâkinah.',
              ),
              SizedBox(height: 12),
              _GuideRuleRow(
                color: TajweedColors.qalqalahBlue,
                title: 'Bleu — Qalqalah (القلقلة)',
                description:
                    'Indique le rebond sonore sur les 5 lettres (ق ط ب ج د — قطب جد) lorsqu’elles portent un Sukun (ْ).',
              ),
              SizedBox(height: 12),
              _GuideRuleRow(
                color: TajweedColors.iqlabTafkhimOrange,
                title: 'Orange — Iqlâb & Tafkhîm (الإقلاب والتفخيم)',
                description:
                    'Indique la conversion en Meem (ۢ) ou la prononciation emphatique des lettres lourdes (خص ضغط قظ).',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GuideRuleRow extends StatelessWidget {
  const _GuideRuleRow({
    required this.color,
    required this.title,
    required this.description,
  });

  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
