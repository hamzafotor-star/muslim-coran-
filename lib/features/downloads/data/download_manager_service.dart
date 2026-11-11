import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum DownloadItemStatus {
  queued,
  running,
  paused,
  done,
  error,
}

@immutable
class SurahDownloadTask {
  const SurahDownloadTask({
    required this.surahId,
    required this.surahName,
    required this.reciterId,
    required this.reciterName,
    required this.url,
    required this.estimatedSizeBytes,
    this.status = DownloadItemStatus.queued,
    this.progress = 0.0,
    this.localPath,
    this.errorMessage,
  });

  final int surahId;
  final String surahName;
  final int reciterId;
  final String reciterName;
  final String url;
  final int estimatedSizeBytes;
  final DownloadItemStatus status;
  final double progress;
  final String? localPath;
  final String? errorMessage;

  String get formattedSizeMb =>
      '${(estimatedSizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mo';

  SurahDownloadTask copyWith({
    DownloadItemStatus? status,
    double? progress,
    String? localPath,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SurahDownloadTask(
      surahId: surahId,
      surahName: surahName,
      reciterId: reciterId,
      reciterName: reciterName,
      url: url,
      estimatedSizeBytes: estimatedSizeBytes,
      status: status ?? this.status,
      progress: (progress ?? this.progress).clamp(0.0, 1.0),
      localPath: localPath ?? this.localPath,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Gestionnaire de téléchargements avec support de reprise HTTP Range via `Dio`
/// et stockage dans le dossier privé de l'application (§3 & E17).
class DownloadManagerNotifier
    extends StateNotifier<Map<String, SurahDownloadTask>> {
  DownloadManagerNotifier() : super(_buildInitialCatalog());

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};

  static String taskKey(int reciterId, int surahId) => '${reciterId}_$surahId';

  static Map<String, SurahDownloadTask> _buildInitialCatalog() {
    const List<MapEntry<int, String>> sampleSurahs = <MapEntry<int, String>>[
      MapEntry<int, String>(1, 'Al-Fâtiha'),
      MapEntry<int, String>(2, 'Al-Baqara'),
      MapEntry<int, String>(18, 'Al-Kahf'),
      MapEntry<int, String>(36, 'Yâ-Sîn'),
      MapEntry<int, String>(55, 'Ar-Rahmân'),
      MapEntry<int, String>(56, 'Al-Wâqi\'a'),
      MapEntry<int, String>(67, 'Al-Mulk'),
      MapEntry<int, String>(112, 'Al-Ikhlâs'),
      MapEntry<int, String>(113, 'Al-Falaq'),
      MapEntry<int, String>(114, 'An-Nâs'),
    ];
    const Map<int, int> estimatedSizesMb = <int, int>{
      1: 1,
      2: 64,
      18: 24,
      36: 12,
      55: 8,
      56: 7,
      67: 6,
      112: 1,
      113: 1,
      114: 1,
    };

    final Map<String, SurahDownloadTask> map = <String, SurahDownloadTask>{};
    for (final MapEntry<int, String> s in sampleSurahs) {
      final String padded = s.key.toString().padLeft(3, '0');
      final int mb = estimatedSizesMb[s.key] ?? 5;
      map[taskKey(1, s.key)] = SurahDownloadTask(
        surahId: s.key,
        surahName: s.value,
        reciterId: 1,
        reciterName: 'Mishary Rashid Al-Afasy',
        url:
            'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/$padded.mp3',
        estimatedSizeBytes: mb * 1024 * 1024,
      );
    }
    return map;
  }

  int get totalDownloadedBytes {
    int sum = 0;
    for (final SurahDownloadTask task in state.values) {
      if (task.status == DownloadItemStatus.done) {
        sum += task.estimatedSizeBytes;
      }
    }
    return sum;
  }

  /// Lance ou reprend le téléchargement d'une sourate avec support de reprise (`Range: bytes=...`).
  Future<void> startOrResumeDownload(String key) async {
    final SurahDownloadTask? current = state[key];
    if (current == null || current.status == DownloadItemStatus.running) {
      return;
    }

    final CancelToken cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;

    state = <String, SurahDownloadTask>{
      ...state,
      key: current.copyWith(
        status: DownloadItemStatus.running,
        clearError: true,
      ),
    };

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String padded = current.surahId.toString().padLeft(3, '0');
      final File targetFile = File(
        p.join(
          appDir.path,
          'audio',
          'reciter_${current.reciterId}',
          '$padded.mp3',
        ),
      );
      await targetFile.parent.create(recursive: true);

      final int existingBytes =
          targetFile.existsSync() ? targetFile.lengthSync() : 0;

      await _dio.download(
        current.url,
        targetFile.path,
        cancelToken: cancelToken,
        deleteOnError: false,
        options: Options(
          headers: existingBytes > 0
              ? <String, dynamic>{'Range': 'bytes=$existingBytes-'}
              : null,
        ),
        onReceiveProgress: (int received, int total) {
          if (total <= 0) return;
          final double prog =
              (existingBytes + received) / (existingBytes + total);
          final SurahDownloadTask? latest = state[key];
          if (latest != null) {
            state = <String, SurahDownloadTask>{
              ...state,
              key: latest.copyWith(
                status: DownloadItemStatus.running,
                progress: prog,
              ),
            };
          }
        },
      );

      final SurahDownloadTask? finished = state[key];
      if (finished != null) {
        state = <String, SurahDownloadTask>{
          ...state,
          key: finished.copyWith(
            status: DownloadItemStatus.done,
            progress: 1.0,
            localPath: targetFile.path,
          ),
        };
      }
    } on DioException catch (e) {
      final SurahDownloadTask? latest = state[key];
      if (latest == null) return;
      if (CancelToken.isCancel(e)) {
        state = <String, SurahDownloadTask>{
          ...state,
          key: latest.copyWith(status: DownloadItemStatus.paused),
        };
      } else {
        state = <String, SurahDownloadTask>{
          ...state,
          key: latest.copyWith(
            status: DownloadItemStatus.error,
            errorMessage: 'Erreur réseau — vérifiez votre connexion Internet.',
          ),
        };
      }
    } catch (e) {
      final SurahDownloadTask? latest = state[key];
      if (latest != null) {
        state = <String, SurahDownloadTask>{
          ...state,
          key: latest.copyWith(
            status: DownloadItemStatus.error,
            errorMessage: e.toString(),
          ),
        };
      }
    } finally {
      _cancelTokens.remove(key);
    }
  }

  void pauseDownload(String key) {
    _cancelTokens[key]?.cancel('Paused by user');
    final SurahDownloadTask? current = state[key];
    if (current != null) {
      state = <String, SurahDownloadTask>{
        ...state,
        key: current.copyWith(status: DownloadItemStatus.paused),
      };
    }
  }

  void markCompletedForTest(String key) {
    final SurahDownloadTask? current = state[key];
    if (current != null) {
      state = <String, SurahDownloadTask>{
        ...state,
        key: current.copyWith(
          status: DownloadItemStatus.done,
          progress: 1.0,
        ),
      };
    }
  }
}

final StateNotifierProvider<DownloadManagerNotifier,
        Map<String, SurahDownloadTask>> downloadManagerProvider =
    StateNotifierProvider<DownloadManagerNotifier,
        Map<String, SurahDownloadTask>>(
  (Ref ref) => DownloadManagerNotifier(),
);
