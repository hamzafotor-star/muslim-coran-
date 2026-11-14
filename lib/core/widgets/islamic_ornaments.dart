import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ornements géométriques islamiques partagés par l'interface « Qurana » :
/// étoile à 8 branches (Rub el-Hizb), motif géométrique de fond,
/// médaillon doré du logo, cadre de style Mushaf et séparateur orné.
/// Aucune représentation figurative : uniquement de la géométrie.

/// Construit le chemin d'une étoile à 8 branches (deux carrés superposés).
Path buildEightPointStarPath(Offset center, double outerRadius) {
  // Rayon intérieur exact pour deux carrés superposés à 45°.
  final double innerRadius =
      outerRadius * math.cos(math.pi / 4) / math.cos(math.pi / 8);
  final Path path = Path();
  for (int i = 0; i < 16; i++) {
    final double angle = -math.pi / 2 + i * math.pi / 8;
    final double radius = i.isEven ? outerRadius : innerRadius;
    final Offset p = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

/// Peint une étoile islamique à 8 branches remplie d'un dégradé avec filet.
class IslamicStarPainter extends CustomPainter {
  const IslamicStarPainter({
    this.fillGradient = AppColors.goldGradient,
    this.fillColor,
    this.strokeColor = AppColors.goldDeep,
    this.strokeWidth = 1.2,
    this.innerRingColor,
  });

  final Gradient? fillGradient;
  final Color? fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final Color? innerRingColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final Path star = buildEightPointStarPath(center, radius);
    final Rect bounds = Rect.fromCircle(center: center, radius: radius);

    final Paint fill = Paint()..style = PaintingStyle.fill;
    if (fillColor != null) {
      fill.color = fillColor!;
    } else if (fillGradient != null) {
      fill.shader = fillGradient!.createShader(bounds);
    }
    canvas.drawPath(star, fill);

    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.miter
        ..color = strokeColor,
    );

    if (innerRingColor != null) {
      canvas.drawCircle(
        center,
        radius * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.8
          ..color = innerRingColor!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IslamicStarPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.fillGradient != fillGradient ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.innerRingColor != innerRingColor;
  }
}

/// Médaillon en étoile à 8 branches affichant un numéro (sourate, Juz', page).
class IslamicStarBadge extends StatelessWidget {
  const IslamicStarBadge({
    super.key,
    required this.label,
    this.size = 46,
    this.highlighted = false,
  });

  final String label;
  final double size;

  /// `true` : étoile pleine dorée (ex. sourate en cours de lecture).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = highlighted
        ? AppColors.emeraldNight
        : (isDark ? AppColors.goldLight : AppColors.primaryDeepGreen);
    final double fontSize = label.length >= 3 ? size * 0.27 : size * 0.32;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: IslamicStarPainter(
          fillGradient: highlighted ? AppColors.goldGradient : null,
          fillColor: highlighted
              ? null
              : (isDark
                  ? AppColors.emeraldNight
                  : AppColors.secondaryLightGreen.withOpacity(0.55)),
          strokeColor: highlighted
              ? AppColors.goldDeep
              : AppColors.accentSoftGold.withOpacity(0.9),
          strokeWidth: 1.3,
          innerRingColor: AppColors.accentSoftGold.withOpacity(0.45),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Motif géométrique islamique répétitif (étoiles à 8 branches + losanges)
/// destiné aux fonds des en-têtes et des cartes.
class GeometricPatternPainter extends CustomPainter {
  const GeometricPatternPainter({
    this.color = Colors.white,
    this.opacity = 0.07,
    this.tileSize = 46,
    this.strokeWidth = 0.9,
  });

  final Color color;
  final double opacity;
  final double tileSize;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withOpacity(opacity);

    final double half = tileSize / 2;
    for (double y = 0; y < size.height + tileSize; y += tileSize) {
      for (double x = 0; x < size.width + tileSize; x += tileSize) {
        final Offset c = Offset(x, y);
        canvas.drawPath(buildEightPointStarPath(c, half * 0.62), paint);
        canvas.drawCircle(c, half * 0.22, paint);
        // Losange de liaison au coin de la tuile.
        final Offset d = Offset(x + half, y + half);
        final double r = half * 0.28;
        final Path diamond = Path()
          ..moveTo(d.dx, d.dy - r)
          ..lineTo(d.dx + r, d.dy)
          ..lineTo(d.dx, d.dy + r)
          ..lineTo(d.dx - r, d.dy)
          ..close();
        canvas.drawPath(diamond, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GeometricPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.tileSize != tileSize ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Fond royal émeraude orné du motif géométrique (en-têtes, héros, AppBar).
class RoyalPatternBackground extends StatelessWidget {
  const RoyalPatternBackground({
    super.key,
    this.child,
    this.borderRadius,
    this.patternOpacity = 0.07,
    this.showGoldEdge = true,
  });

  final Widget? child;
  final BorderRadius? borderRadius;
  final double patternOpacity;
  final bool showGoldEdge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.royalEmeraldGradient,
        borderRadius: borderRadius,
        boxShadow: AppColors.softShadow(opacity: 0.22),
        border: showGoldEdge
            ? Border.all(
                color: AppColors.accentSoftGold.withOpacity(0.45),
                width: 0.8,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CustomPaint(
          painter: GeometricPatternPainter(
            color: AppColors.goldLight,
            opacity: patternOpacity,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Fond d'AppBar royal : à utiliser dans `AppBar.flexibleSpace`.
class RoyalAppBarBackground extends StatelessWidget {
  const RoyalAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.royalEmeraldGradient,
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentSoftGold.withOpacity(0.7),
            width: 1.2,
          ),
        ),
      ),
      child: const CustomPaint(
        painter: GeometricPatternPainter(
          color: AppColors.goldLight,
          opacity: 0.08,
          tileSize: 40,
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

/// Construit une AppBar royale émeraude & or homogène pour les écrans principaux.
PreferredSizeWidget buildRoyalAppBar({
  required String title,
  String? subtitle,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  Widget? leading,
  bool automaticallyImplyLeading = true,
}) {
  return AppBar(
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: leading,
    backgroundColor: AppColors.primaryDeepGreen,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    iconTheme: const IconThemeData(color: AppColors.goldLight),
    actionsIconTheme: const IconThemeData(color: AppColors.goldLight),
    elevation: 0,
    scrolledUnderElevation: 0,
    flexibleSpace: const RoyalAppBarBackground(),
    toolbarHeight: subtitle != null ? 66 : kToolbarHeight,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 21,
            letterSpacing: 0.3,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.goldLight.withOpacity(0.95),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    ),
    actions: actions,
    bottom: bottom,
  );
}

/// TabBar adaptée aux AppBars royales (texte blanc / or, indicateur doré).
TabBar buildRoyalTabBar({
  required TabController controller,
  required List<Widget> tabs,
}) {
  return TabBar(
    controller: controller,
    labelColor: AppColors.goldLight,
    unselectedLabelColor: Colors.white70,
    indicatorColor: AppColors.goldLight,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: Colors.transparent,
    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    unselectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.goldLight, width: 3),
      borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
    ),
    tabs: tabs,
  );
}

/// Médaillon doré circulaire entourant le logo officiel `app_logo.png`.
class GoldLogoMedallion extends StatelessWidget {
  const GoldLogoMedallion({
    super.key,
    this.size = 140,
    this.glow = true,
  });

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final double ring = size * 0.05;
    return SizedBox(
      width: size * 1.18,
      height: size * 1.18,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Étoile dorée en filigrane derrière le médaillon.
          CustomPaint(
            size: Size.square(size * 1.18),
            painter: IslamicStarPainter(
              fillColor: AppColors.accentSoftGold.withOpacity(0.10),
              strokeColor: AppColors.goldLight.withOpacity(0.55),
              strokeWidth: 1.0,
            ),
          ),
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(ring),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: <Color>[
                  AppColors.goldLight,
                  AppColors.accentSoftGold,
                  AppColors.goldDeep,
                  AppColors.accentSoftGold,
                  AppColors.goldLight,
                ],
              ),
              boxShadow: <BoxShadow>[
                if (glow) ...AppColors.goldGlow(opacity: 0.35),
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(ring * 0.6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emeraldNight,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.menu_book,
                    size: size * 0.45,
                    color: AppColors.goldLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Séparateur orné : filet doré — étoile — filet doré.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({
    super.key,
    this.color = AppColors.accentSoftGold,
    this.starSize = 12,
    this.width,
  });

  final Color color;
  final double starSize;
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget line(bool reversed) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: reversed
                    ? <Color>[color, color.withOpacity(0)]
                    : <Color>[color.withOpacity(0), color],
              ),
            ),
          ),
        );

    return SizedBox(
      width: width,
      child: Row(
        children: <Widget>[
          line(false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomPaint(
              size: Size.square(starSize),
              painter: IslamicStarPainter(
                fillColor: color,
                strokeColor: color,
                strokeWidth: 0.6,
              ),
            ),
          ),
          line(true),
        ],
      ),
    );
  }
}

/// Cadre de style Mushaf : double filet doré, coins ornés d'étoiles.
class MushafFrame extends StatelessWidget {
  const MushafFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 18),
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = backgroundColor ??
        (isDark ? const Color(0xFF17201B) : AppColors.parchment);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentSoftGold, width: 1.6),
        boxShadow: AppColors.softShadow(opacity: isDark ? 0.4 : 0.10),
      ),
      padding: const EdgeInsets.all(5),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.accentSoftGold.withOpacity(0.55),
                  width: 0.8,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricPatternPainter(
                color: AppColors.accentSoftGold,
                opacity: isDark ? 0.05 : 0.06,
                tileSize: 54,
              ),
            ),
          ),
          for (final Alignment corner in const <Alignment>[
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Positioned.fill(
              child: Align(
                alignment: corner,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CustomPaint(
                    size: const Size.square(14),
                    painter: IslamicStarPainter(
                      fillGradient: AppColors.goldGradient,
                      strokeColor: AppColors.goldDeep.withOpacity(0.8),
                      strokeWidth: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Titre de section élégant avec petite étoile dorée.
class OrnateSectionTitle extends StatelessWidget {
  const OrnateSectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: <Widget>[
          const CustomPaint(
            size: Size.square(14),
            painter: IslamicStarPainter(strokeWidth: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: isDark ? AppColors.goldLight : AppColors.primaryDeepGreen,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
