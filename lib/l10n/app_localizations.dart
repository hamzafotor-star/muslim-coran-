import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Classe d'internationalisation (FR par défaut, AR avec RTL, EN)
/// correspondant aux fichiers ARB `lib/l10n/app_{fr,ar,en}.arb`.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('fr'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('ar'),
    Locale('en'),
  ];

  bool get isRtl => locale.languageCode == 'ar';

  static const Map<String, Map<String, String>> _localizedValues =
      <String, Map<String, String>>{
    'fr': <String, String>{
      'appTitle': 'Qurana',
      'greeting': 'Assalamu alaykum',
      'tabQuran': 'Coran',
      'tabPrayers': 'Prières',
      'tabQibla': 'Qibla',
      'tabBookmarks': 'Signets',
      'tabMore': 'Plus',
      'nextPrayer': 'Prochaine prière',
      'resumeReading': 'Reprendre la lecture',
      'continueBtn': 'Continuer',
      'verseOfTheDay': 'Verset du jour',
      'surahs': 'Sourates',
      'juz': "Juz'",
      'pages': 'Pages',
      'meccan': 'Mecquoise',
      'medinan': 'Médinoise',
      'searchHint': 'Rechercher un verset ou un mot…',
      'arabic': 'Arabe',
      'french': 'Français',
      'english': 'Anglais',
      'bookmarks': 'Signets',
      'notes': 'Notes',
      'history': 'Historique',
      'emptyBookmarks': 'Aucun signet enregistré pour le moment.',
      'openQuran': 'Ouvrir le Coran',
      'settings': 'Réglages',
      'downloads': 'Téléchargements',
      'themeLight': 'Clair',
      'themeDark': 'Sombre',
      'themeSepia': 'Sépia',
      'comingSoon': 'Bientôt',
      'chooseCity': 'Choisir une ville',
      'useMyLocation': 'Utiliser ma position',
      'batteryOptimization': 'Optimisation batterie',
      'alignQibla': 'Aligné — précision haute',
      'calibrateSensor': 'Calibrer le capteur',
      'appTagline': 'Votre compagnon du Coran, 100 % hors ligne',
      'quickAccess': 'Accès rapide',
      'todayPrayers': 'Prières du jour',
    },
    'ar': <String, String>{
      'appTitle': 'قرآنا',
      'greeting': 'السلام عليكم',
      'tabQuran': 'القرآن',
      'tabPrayers': 'الصلوات',
      'tabQibla': 'القبلة',
      'tabBookmarks': 'العلامات',
      'tabMore': 'المزيد',
      'nextPrayer': 'الصلاة القادمة',
      'resumeReading': 'متابعة القراءة',
      'continueBtn': 'متابعة',
      'verseOfTheDay': 'آية اليوم',
      'surahs': 'السور',
      'juz': 'الأجزاء',
      'pages': 'الصفحات',
      'meccan': 'مكية',
      'medinan': 'مدنية',
      'searchHint': 'ابحث عن آية أو كلمة…',
      'arabic': 'العربية',
      'french': 'الفرنسية',
      'english': 'الإنجليزية',
      'bookmarks': 'العلامات',
      'notes': 'الملاحظات',
      'history': 'السجل',
      'emptyBookmarks': 'لا توجد علامات محفوظة حالياً.',
      'openQuran': 'فتح المصحف',
      'settings': 'الإعدادات',
      'downloads': 'التنزيلات',
      'themeLight': 'فاتح',
      'themeDark': 'داكن',
      'themeSepia': 'ورقي (سيبيا)',
      'comingSoon': 'قريباً',
      'chooseCity': 'اختر مدينة',
      'useMyLocation': 'استخدام موقعي الحالي',
      'batteryOptimization': 'تحسين البطارية',
      'alignQibla': 'محاذاة دقيقة باتجاه القبلة',
      'calibrateSensor': 'معايرة البوصلة',
      'appTagline': 'رفيقك مع القرآن، بدون إنترنت',
      'quickAccess': 'وصول سريع',
      'todayPrayers': 'صلوات اليوم',
    },
    'en': <String, String>{
      'appTitle': 'Qurana',
      'greeting': 'Assalamu alaykum',
      'tabQuran': 'Quran',
      'tabPrayers': 'Prayers',
      'tabQibla': 'Qibla',
      'tabBookmarks': 'Bookmarks',
      'tabMore': 'More',
      'nextPrayer': 'Next prayer',
      'resumeReading': 'Resume reading',
      'continueBtn': 'Continue',
      'verseOfTheDay': 'Verse of the day',
      'surahs': 'Surahs',
      'juz': "Juz'",
      'pages': 'Pages',
      'meccan': 'Meccan',
      'medinan': 'Medinan',
      'searchHint': 'Search a verse or word…',
      'arabic': 'Arabic',
      'french': 'French',
      'english': 'English',
      'bookmarks': 'Bookmarks',
      'notes': 'Notes',
      'history': 'History',
      'emptyBookmarks': 'No bookmarks saved yet.',
      'openQuran': 'Open Quran',
      'settings': 'Settings',
      'downloads': 'Downloads',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'themeSepia': 'Sepia',
      'comingSoon': 'Coming soon',
      'chooseCity': 'Choose a city',
      'useMyLocation': 'Use my location',
      'batteryOptimization': 'Battery optimization',
      'alignQibla': 'Aligned — high accuracy',
      'calibrateSensor': 'Calibrate sensor',
      'appTagline': 'Your Quran companion, 100% offline',
      'quickAccess': 'Quick access',
      'todayPrayers': "Today's prayers",
    },
  };

  String _t(String key) {
    final String code = _localizedValues.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'fr';
    return _localizedValues[code]![key] ?? _localizedValues['fr']![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get greeting => _t('greeting');
  String get tabQuran => _t('tabQuran');
  String get tabPrayers => _t('tabPrayers');
  String get tabQibla => _t('tabQibla');
  String get tabBookmarks => _t('tabBookmarks');
  String get tabMore => _t('tabMore');
  String get nextPrayer => _t('nextPrayer');
  String get resumeReading => _t('resumeReading');
  String get continueBtn => _t('continueBtn');
  String get verseOfTheDay => _t('verseOfTheDay');
  String get surahs => _t('surahs');
  String get juz => _t('juz');
  String get pages => _t('pages');
  String get meccan => _t('meccan');
  String get medinan => _t('medinan');
  String get searchHint => _t('searchHint');
  String get arabic => _t('arabic');
  String get french => _t('french');
  String get english => _t('english');
  String get bookmarks => _t('bookmarks');
  String get notes => _t('notes');
  String get history => _t('history');
  String get emptyBookmarks => _t('emptyBookmarks');
  String get openQuran => _t('openQuran');
  String get settings => _t('settings');
  String get downloads => _t('downloads');
  String get themeLight => _t('themeLight');
  String get themeDark => _t('themeDark');
  String get themeSepia => _t('themeSepia');
  String get comingSoon => _t('comingSoon');
  String get chooseCity => _t('chooseCity');
  String get useMyLocation => _t('useMyLocation');
  String get batteryOptimization => _t('batteryOptimization');
  String get alignQibla => _t('alignQibla');
  String get calibrateSensor => _t('calibrateSensor');
  String get appTagline => _t('appTagline');
  String get quickAccess => _t('quickAccess');
  String get todayPrayers => _t('todayPrayers');

  String inTime(String duration) {
    if (locale.languageCode == 'ar') return 'بعد $duration';
    if (locale.languageCode == 'en') return 'in $duration';
    return 'dans $duration';
  }

  String versesCount(int count) {
    if (locale.languageCode == 'ar') return '$count آية';
    return '$count v.';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['fr', 'ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
