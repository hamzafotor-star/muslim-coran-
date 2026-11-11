import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

enum FontInstallStatus {
  builtIn,
  notInstalled,
  downloading,
  installed,
  error,
}

@immutable
class FontDownloadItemState {
  const FontDownloadItemState({
    required this.font,
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
  });

  final ArabicFontFamily font;
  final FontInstallStatus status;
  final double progress;
  final String? errorMessage;

  bool get isReady =>
      status == FontInstallStatus.builtIn ||
      status == FontInstallStatus.installed;

  FontDownloadItemState copyWith({
    FontInstallStatus? status,
    double? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FontDownloadItemState(
      font: font,
      status: status ?? this.status,
      progress: (progress ?? this.progress).clamp(0.0, 1.0),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Service de téléchargement et d'enregistrement dynamique des polices arabes OFL
/// via `FontLoader` (`package:flutter/services.dart`).
class FontDownloadNotifier
    extends StateNotifier<Map<ArabicFontFamily, FontDownloadItemState>> {
  FontDownloadNotifier() : super(_buildInitialStates()) {
    _restoreDownloadedFonts();
  }

  final Dio _dio = Dio();

  static Map<ArabicFontFamily, FontDownloadItemState> _buildInitialStates() {
    final Map<ArabicFontFamily, FontDownloadItemState> map =
        <ArabicFontFamily, FontDownloadItemState>{};
    for (final ArabicFontFamily f in ArabicFontFamily.values) {
      map[f] = FontDownloadItemState(
        font: f,
        status: f.isBuiltIn
            ? FontInstallStatus.builtIn
            : FontInstallStatus.notInstalled,
        progress: f.isBuiltIn ? 1.0 : 0.0,
      );
    }
    return map;
  }

  /// Charge au démarrage toutes les polices déjà téléchargées hors ligne dans `app_flutter/fonts/`.
  Future<void> _restoreDownloadedFonts() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory fontsDir = Directory(p.join(appDir.path, 'fonts'));
      if (!fontsDir.existsSync()) return;

      for (final ArabicFontFamily f in ArabicFontFamily.values) {
        if (f.isBuiltIn) continue;
        final File ttfFile = File(p.join(fontsDir.path, '${f.fontFamily}.ttf'));
        if (ttfFile.existsSync() && ttfFile.lengthSync() > 1024) {
          await _registerFontBytes(f.fontFamily, await ttfFile.readAsBytes());
          if (mounted) {
            state = <ArabicFontFamily, FontDownloadItemState>{
              ...state,
              f: FontDownloadItemState(
                font: f,
                status: FontInstallStatus.installed,
                progress: 1.0,
              ),
            };
          }
        }
      }
    } catch (_) {
      // Ignore en environnement de test sans path_provider natif.
    }
  }

  Future<void> _registerFontBytes(String fontFamily, Uint8List bytes) async {
    final FontLoader loader = FontLoader(fontFamily);
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  /// Télécharge une police OFL depuis son URL officielle, l'enregistre sur disque
  /// et l'active immédiatement via `FontLoader`.
  Future<bool> downloadAndLoadFont(ArabicFontFamily font) async {
    if (font.isBuiltIn) return true;
    final FontDownloadItemState? current = state[font];
    if (current != null && current.isReady) return true;
    if (current?.status == FontInstallStatus.downloading) return false;

    final String? url = font.downloadUrl;
    if (url == null) return false;

    state = <ArabicFontFamily, FontDownloadItemState>{
      ...state,
      font: FontDownloadItemState(
        font: font,
        status: FontInstallStatus.downloading,
        progress: 0.05,
      ),
    };

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File targetFile = File(
        p.join(appDir.path, 'fonts', '${font.fontFamily}.ttf'),
      );
      await targetFile.parent.create(recursive: true);

      await _dio.download(
        url,
        targetFile.path,
        onReceiveProgress: (int received, int total) {
          if (!mounted || total <= 0) return;
          state = <ArabicFontFamily, FontDownloadItemState>{
            ...state,
            font: FontDownloadItemState(
              font: font,
              status: FontInstallStatus.downloading,
              progress: (received / total).clamp(0.05, 0.99),
            ),
          };
        },
      );

      final Uint8List bytes = await targetFile.readAsBytes();
      await _registerFontBytes(font.fontFamily, bytes);

      if (mounted) {
        state = <ArabicFontFamily, FontDownloadItemState>{
          ...state,
          font: FontDownloadItemState(
            font: font,
            status: FontInstallStatus.installed,
            progress: 1.0,
          ),
        };
      }
      return true;
    } catch (_) {
      if (mounted) {
        state = <ArabicFontFamily, FontDownloadItemState>{
          ...state,
          font: FontDownloadItemState(
            font: font,
            status: FontInstallStatus.error,
            errorMessage:
                'Échec du téléchargement de la police — vérifiez votre connexion Internet.',
          ),
        };
      }
      return false;
    }
  }
}

final StateNotifierProvider<FontDownloadNotifier,
        Map<ArabicFontFamily, FontDownloadItemState>> fontDownloadProvider =
    StateNotifierProvider<FontDownloadNotifier,
        Map<ArabicFontFamily, FontDownloadItemState>>(
  (Ref ref) => FontDownloadNotifier(),
);
