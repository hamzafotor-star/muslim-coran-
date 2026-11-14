import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../audio/data/quran_audio_handler.dart';

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

/// Gestionnaire de téléchargements avec support des 12 récitateurs (dont Abdullah Al-Matrood),
/// reprise HTTP Range via `Dio` et stockage dans le dossier privé de l'application (§3 & E17).
class DownloadManagerNotifier
    extends StateNotifier<Map<String, SurahDownloadTask>> {
  DownloadManagerNotifier() : super(_buildInitialCatalog()) {
    _restoreDownloadedFilesFromDisk();
  }

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};

  static String taskKey(int reciterId, int surahId) => '${reciterId}_$surahId';

  static const List<MapEntry<int, String>> catalogSurahs =
      <MapEntry<int, String>>[
    MapEntry<int, String>(1, 'Al-Fâtiha'),
    MapEntry<int, String>(2, 'Al-Baqara'),
    MapEntry<int, String>(3, 'Âl-Imrân'),
    MapEntry<int, String>(4, 'An-Nisâ’'),
    MapEntry<int, String>(18, 'Al-Kahf'),
    MapEntry<int, String>(19, 'Maryam'),
    MapEntry<int, String>(36, 'Yâ-Sîn'),
    MapEntry<int, String>(55, 'Ar-Rahmân'),
    MapEntry<int, String>(56, 'Al-Wâqi\'a'),
    MapEntry<int, String>(67, 'Al-Mulk'),
    MapEntry<int, String>(78, 'An-Naba’'),
    MapEntry<int, String>(87, 'Al-A‘lâ'),
    MapEntry<int, String>(93, 'Ad-Duhâ'),
    MapEntry<int, String>(97, 'Al-Qadr'),
    MapEntry<int, String>(109, 'Al-Kâfirûn'),
    MapEntry<int, String>(112, 'Al-Ikhlâs'),
    MapEntry<int, String>(113, 'Al-Falaq'),
    MapEntry<int, String>(114, 'An-Nâs'),
  ];

  static const Map<int, int> _estimatedSizesMb = <int, int>{
    1: 1,
    2: 64,
    3: 38,
    4: 40,
    18: 24,
    19: 15,
    36: 12,
    55: 8,
    56: 7,
    67: 6,
    78: 4,
    87: 2,
    93: 1,
    97: 1,
    109: 1,
    112: 1,
    113: 1,
    114: 1,
  };

  static Map<String, SurahDownloadTask> _buildInitialCatalog() {
    final Map<String, SurahDownloadTask> map = <String, SurahDownloadTask>{};
    for (final ReciterOption reciter in AudioPlaybackState.availableReciters) {
      for (final MapEntry<int, String> s in catalogSurahs) {
        final int mb = _estimatedSizesMb[s.key] ?? 5;
        map[taskKey(reciter.id, s.key)] = SurahDownloadTask(
          surahId: s.key,
          surahName: s.value,
          reciterId: reciter.id,
          reciterName: reciter.name,
          url: reciter.surahAudioUrl(s.key),
          estimatedSizeBytes: mb * 1024 * 1024,
        );
      }
    }
    return map;
  }

  Future<void> _restoreDownloadedFilesFromDisk() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Map<String, SurahDownloadTask> updated =
          Map<String, SurahDownloadTask>.from(state);
      bool changed = false;

      for (final MapEntry<String, SurahDownloadTask> entry in state.entries) {
        final SurahDownloadTask t = entry.value;
        final String padded = t.surahId.toString().padLeft(3, '0');
        final Directory surahDir = Directory(
          p.join(appDir.path, 'audio', 'reciter_${t.reciterId}', padded),
        );
        final int totalAyahs = AudioPlaybackState.ayahCountForSurah(t.surahId);

        if (surahDir.existsSync()) {
          int downloadedAyahs = 0;
          for (int ayahNum = 1; ayahNum <= totalAyahs; ayahNum++) {
            final String paddedAyah = ayahNum.toString().padLeft(3, '0');
            final File ayahFile = File(
              p.join(surahDir.path, '$paddedAyah.mp3'),
            );
            if (ayahFile.existsSync() && ayahFile.lengthSync() > 100) {
              downloadedAyahs++;
            }
          }
          if (downloadedAyahs == totalAyahs) {
            updated[entry.key] = t.copyWith(
              status: DownloadItemStatus.done,
              progress: 1.0,
              localPath: surahDir.path,
            );
            changed = true;
            continue;
          } else if (downloadedAyahs > 0) {
            updated[entry.key] = t.copyWith(
              status: DownloadItemStatus.paused,
              progress: downloadedAyahs / totalAyahs,
            );
            changed = true;
            continue;
          }
        }

        final File legacyLocalFile = File(
          p.join(appDir.path, 'audio', 'reciter_${t.reciterId}', '$padded.mp3'),
        );
        if (legacyLocalFile.existsSync() &&
            legacyLocalFile.lengthSync() > 4096) {
          updated[entry.key] = t.copyWith(
            status: DownloadItemStatus.done,
            progress: 1.0,
            localPath: legacyLocalFile.path,
          );
          changed = true;
        }
      }

      if (changed && mounted) {
        state = updated;
      }
    } catch (_) {
      // Ignore en environnement de test unitaire sans path_provider natif.
    }
  }

  /// Garantit qu'une tâche existe pour n'importe quelle sourate (1..114) et récitateur,
  /// puis lance son téléchargement.
  Future<void> downloadSurahForReciter({
    required ReciterOption reciter,
    required int surahId,
    required String surahName,
  }) async {
    final String key = taskKey(reciter.id, surahId);
    if (!state.containsKey(key)) {
      final int mb = _estimatedSizesMb[surahId] ?? 8;
      state = <String, SurahDownloadTask>{
        ...state,
        key: SurahDownloadTask(
          surahId: surahId,
          surahName: surahName,
          reciterId: reciter.id,
          reciterName: reciter.name,
          url: reciter.surahAudioUrl(surahId),
          estimatedSizeBytes: mb * 1024 * 1024,
        ),
      };
    }
    await startOrResumeDownload(key);
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

  /// Lance ou reprend le téléchargement d'une sourate verset par verset
  /// (EveryAyah.com) avec pause/reprise au verset près.
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
      final String paddedSurah = current.surahId.toString().padLeft(3, '0');
      final Directory surahDir = Directory(
        p.join(
          appDir.path,
          'audio',
          'reciter_${current.reciterId}',
          paddedSurah,
        ),
      );
      await surahDir.create(recursive: true);

      final ReciterOption reciter =
          AudioPlaybackState.availableReciters.firstWhere(
        (ReciterOption r) => r.id == current.reciterId,
        orElse: () => AudioPlaybackState.defaultRecitersFirst,
      );
      final int totalAyahs =
          AudioPlaybackState.ayahCountForSurah(current.surahId);

      for (int ayahNum = 1; ayahNum <= totalAyahs; ayahNum++) {
        if (cancelToken.isCancelled) break;

        final String paddedAyah = ayahNum.toString().padLeft(3, '0');
        final File targetFile = File(
          p.join(surahDir.path, '$paddedAyah.mp3'),
        );

        if (targetFile.existsSync() && targetFile.lengthSync() > 100) {
          final SurahDownloadTask? latest = state[key];
          if (latest != null) {
            state = <String, SurahDownloadTask>{
              ...state,
              key: latest.copyWith(
                status: DownloadItemStatus.running,
                progress: ayahNum / totalAyahs,
              ),
            };
          }
          continue;
        }

        final File tempFile = File('${targetFile.path}.part');
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }

        await _dio.download(
          reciter.ayahAudioUrl(current.surahId, ayahNum),
          tempFile.path,
          cancelToken: cancelToken,
          deleteOnError: true,
          onReceiveProgress: (int received, int total) {
            if (total <= 0 || cancelToken.isCancelled) return;
            final double ayahFrac = (received / total).clamp(0.0, 1.0);
            final double prog = ((ayahNum - 1) + ayahFrac) / totalAyahs;
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

        if (cancelToken.isCancelled) {
          if (tempFile.existsSync()) {
            await tempFile.delete();
          }
          break;
        }

        if (targetFile.existsSync()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetFile.path);

        final SurahDownloadTask? latest = state[key];
        if (latest != null) {
          state = <String, SurahDownloadTask>{
            ...state,
            key: latest.copyWith(
              status: DownloadItemStatus.running,
              progress: ayahNum / totalAyahs,
            ),
          };
        }
      }

      final SurahDownloadTask? finished = state[key];
      if (finished != null) {
        if (cancelToken.isCancelled) {
          state = <String, SurahDownloadTask>{
            ...state,
            key: finished.copyWith(status: DownloadItemStatus.paused),
          };
        } else {
          state = <String, SurahDownloadTask>{
            ...state,
            key: finished.copyWith(
              status: DownloadItemStatus.done,
              progress: 1.0,
              localPath: surahDir.path,
            ),
          };
        }
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
