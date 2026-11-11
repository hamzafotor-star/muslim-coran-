import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_coran/features/downloads/data/download_manager_service.dart';

void main() {
  group('Phase 3 — Gestionnaire de téléchargements et calcul d’espace (E17)', () {
    test('Initialise le catalogue et suit les états queued -> paused -> done', () {
      final DownloadManagerNotifier manager = DownloadManagerNotifier();
      final String fatihaKey = DownloadManagerNotifier.taskKey(1, 1);

      expect(manager.state.containsKey(fatihaKey), isTrue);
      expect(manager.state[fatihaKey]!.status, DownloadItemStatus.queued);
      expect(manager.totalDownloadedBytes, 0);

      manager.pauseDownload(fatihaKey);
      expect(manager.state[fatihaKey]!.status, DownloadItemStatus.paused);

      manager.markCompletedForTest(fatihaKey);
      expect(manager.state[fatihaKey]!.status, DownloadItemStatus.done);
      expect(manager.state[fatihaKey]!.progress, 1.0);
      expect(manager.totalDownloadedBytes, greaterThan(0));
    });
  });
}
