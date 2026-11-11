import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Coquille de navigation principale à 5 onglets (§0 du Cahier de maquettes) :
/// `Coran · Prières · Qibla · Signets · Plus`
/// Aucune icône figurative (uniquement symboles géométriques/linéaires sobres).
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

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: child),
          if (miniPlayer != null) miniPlayer!,
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.clamp(0, 4),
        onDestinationSelected: onTabSelected,
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
    );
  }
}
