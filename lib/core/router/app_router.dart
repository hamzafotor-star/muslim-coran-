import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio/presentation/full_audio_player_screen.dart';
import '../../features/audio/presentation/widgets/mini_audio_player.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/downloads/presentation/downloads_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/more/presentation/more_menu_screen.dart';
import '../../features/onboarding/presentation/permissions_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/prayer/presentation/city_picker_screen.dart';
import '../../features/prayer/presentation/prayer_settings_screen.dart';
import '../../features/prayer/presentation/prayer_times_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/quran/presentation/ayah_reader_screen.dart';
import '../../features/quran/presentation/surah_list_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/app_bottom_nav_shell.dart';
import 'app_routes.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (BuildContext context, GoRouterState state) =>
            const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (BuildContext context, GoRouterState state) =>
            const PermissionsScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          final String loc = state.uri.path;
          int index = 0;
          if (loc.startsWith(AppRoutes.prayers)) {
            index = 1;
          } else if (loc.startsWith(AppRoutes.qibla)) {
            index = 2;
          } else if (loc.startsWith(AppRoutes.bookmarks)) {
            index = 3;
          } else if (loc.startsWith(AppRoutes.more)) {
            index = 4;
          }
          return AppBottomNavShell(
            currentIndex: index,
            miniPlayer: const MiniAudioPlayer(),
            onTabSelected: (int newIndex) {
              switch (newIndex) {
                case 0:
                  context.go(AppRoutes.quranList);
                case 1:
                  context.go(AppRoutes.prayers);
                case 2:
                  context.go(AppRoutes.qibla);
                case 3:
                  context.go(AppRoutes.bookmarks);
                case 4:
                  context.go(AppRoutes.more);
              }
            },
            child: child,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            builder: (BuildContext context, GoRouterState state) =>
                const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.quranList,
            builder: (BuildContext context, GoRouterState state) =>
                const SurahListScreen(),
          ),
          GoRoute(
            path: AppRoutes.prayers,
            builder: (BuildContext context, GoRouterState state) =>
                const PrayerTimesScreen(),
          ),
          GoRoute(
            path: AppRoutes.qibla,
            builder: (BuildContext context, GoRouterState state) =>
                const QiblaScreen(),
          ),
          GoRoute(
            path: AppRoutes.bookmarks,
            builder: (BuildContext context, GoRouterState state) =>
                const BookmarksScreen(),
          ),
          GoRoute(
            path: AppRoutes.more,
            builder: (BuildContext context, GoRouterState state) =>
                const MoreMenuScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ayahReader,
        builder: (BuildContext context, GoRouterState state) {
          final int surahId =
              int.tryParse(state.pathParameters['surahId'] ?? '1') ?? 1;
          final int? initialAyah =
              int.tryParse(state.uri.queryParameters['ayah'] ?? '');
          return AyahReaderScreen(
            surahId: surahId.clamp(1, 114),
            initialAyahNumber: initialAyah,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.fullAudioPlayer,
        builder: (BuildContext context, GoRouterState state) =>
            const FullAudioPlayerScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (BuildContext context, GoRouterState state) =>
            const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.prayerSettings,
        builder: (BuildContext context, GoRouterState state) =>
            const PrayerSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.downloads,
        builder: (BuildContext context, GoRouterState state) =>
            const DownloadsScreen(),
      ),
      GoRoute(
        path: AppRoutes.cityPicker,
        builder: (BuildContext context, GoRouterState state) =>
            const CityPickerScreen(),
      ),
    ],
  );
});
