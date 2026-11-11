import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/core/fonts/font_download_service.dart';
import 'package:muslim_coran/core/theme/app_theme.dart';
import 'package:muslim_coran/features/audio/data/quran_audio_handler.dart';
import 'package:muslim_coran/features/downloads/data/download_manager_service.dart';

void main() {
  group('Phase 3 — Gestionnaire de téléchargements et calcul d’espace (E17)', () {
    test('Initialise le catalogue (12 récitateurs dont Abdullah Al-Matrood) et suit queued -> paused -> done', () {
      expect(AudioPlaybackState.availableReciters.length, 12);
      expect(
        AudioPlaybackState.availableReciters
            .any((ReciterOption r) => r.name.contains('Abdullah Al-Matrood')),
        isTrue,
      );

      final DownloadManagerNotifier manager = DownloadManagerNotifier();
      final String fatihaKey = DownloadManagerNotifier.taskKey(1, 1);
      final String matroodFatihaKey = DownloadManagerNotifier.taskKey(2, 1);

      expect(manager.state.containsKey(fatihaKey), isTrue);
      expect(manager.state.containsKey(matroodFatihaKey), isTrue);
      expect(
        manager.state[matroodFatihaKey]!.url,
        'https://download.quranicaudio.com/quran/abdullah_matroud/001.mp3',
      );
      expect(manager.state[fatihaKey]!.status, DownloadItemStatus.queued);
      expect(manager.totalDownloadedBytes, 0);

      manager.pauseDownload(fatihaKey);
      expect(manager.state[fatihaKey]!.status, DownloadItemStatus.paused);

      manager.markCompletedForTest(fatihaKey);
      expect(manager.state[fatihaKey]!.status, DownloadItemStatus.done);
      expect(manager.state[fatihaKey]!.progress, 1.0);
      expect(manager.totalDownloadedBytes, greaterThan(0));
    });

    test('Initialise les 3 polices embarquées et les 6 polices OFL téléchargeables', () {
      final FontDownloadNotifier fontManager = FontDownloadNotifier();
      expect(fontManager.state.length, 9);
      expect(fontManager.state[ArabicFontFamily.amiriQuran]!.isReady, isTrue);
      expect(fontManager.state[ArabicFontFamily.harmattan]!.isReady, isFalse);
      expect(
        fontManager.state[ArabicFontFamily.harmattan]!.status,
        FontInstallStatus.notInstalled,
      );
    });
  });
}
