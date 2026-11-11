/// Définition centralisée des routes de l'application (E01 à E18).
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash'; // E01
  static const String welcome = '/welcome'; // E02
  static const String permissions = '/permissions'; // E03
  static const String home = '/home'; // E04
  static const String quranList = '/quran'; // E05
  static const String ayahReader = '/quran/surah/:surahId'; // E06
  static const String fullAudioPlayer = '/audio-player'; // E09 Plein écran
  static const String search = '/search'; // E10
  static const String prayers = '/prayers'; // E11
  static const String prayerSettings = '/prayers/settings'; // E12
  static const String qibla = '/qibla'; // E13
  static const String bookmarks = '/bookmarks'; // E14
  static const String more = '/more'; // E15
  static const String settings = '/settings'; // E16
  static const String downloads = '/downloads'; // E17
  static const String cityPicker = '/cities'; // E18

  static String ayahReaderPath(int surahId, {int? initialAyah}) {
    if (initialAyah != null && initialAyah > 1) {
      return '/quran/surah/$surahId?ayah=$initialAyah';
    }
    return '/quran/surah/$surahId';
  }
}
