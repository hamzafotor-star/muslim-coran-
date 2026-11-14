import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Coquille de navigation principale à 5 onglets (§0 du Cahier de maquettes) :
/// `Coran · Prières · Qibla · Signets · Plus`
/// Aucune icône figurative (uniquement symboles géométriques/linéaires sobres).
///
/// Barre inférieure « Qurana » : élévation douce, filet doré supérieur,
/// indicateur émeraude/or raffiné et `SafeArea` pour ne jamais chevaucher
/// les boutons système Android (Retour / Accueil / gestes).
class AppBottomNavShell extends StatelessWidget {
  const AppBottomNavShell({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
    this.miniPlayer,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget child;
  final Widget? miniPlayer;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color barColor =
        theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final Color selectedColor =
        isDark ? AppColors.goldLight : AppColors.primaryDeepGreen;
    final Color unselectedColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: child),
          if (miniPlayer != null) miniPlayer!,
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: barColor,
          border: Border(
            top: BorderSide(
              color: AppColors.accentSoftGold.withOpacity(isDark ? 0.45 : 0.35),
              width: 0.9,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.emeraldNight.withOpacity(isDark ? 0.55 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: theme.navigationBarTheme.copyWith(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 66,
              indicatorColor: isDark
                  ? AppColors.accentSoftGold.withOpacity(0.20)
                  : AppColors.secondaryLightGreen,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.accentSoftGold.withOpacity(0.65),
                  width: 1,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (Set<WidgetState> states) {
                  final bool selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: selected ? 25 : 23,
                    color: selected ? selectedColor : unselectedColor,
                  );
                },
              ),
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (Set<WidgetState> states) {
                  final bool selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0.3,
                    color: selected ? selectedColor : unselectedColor,
                  );
                },
              ),
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: NavigationBar(
                selectedIndex: currentIndex.clamp(0, 4),
                onDestinationSelected: onTabSelected,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                animationDuration: const Duration(milliseconds: 420),
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                destinations: <NavigationDestination>[
                  NavigationDestination(
                    icon: const Icon(Icons.menu_book_outlined),
                    selectedIcon: const Icon(Icons.menu_book),
                    label: l10n.tabQuran,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.schedule_outlined),
                    selectedIcon: const Icon(Icons.schedule),
                    label: l10n.tabPrayers,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore),
                    label: l10n.tabQibla,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.bookmark_border),
                    selectedIcon: const Icon(Icons.bookmark),
                    label: l10n.tabBookmarks,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.more_horiz_outlined),
                    selectedIcon: const Icon(Icons.more_horiz),
                    label: l10n.tabMore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
