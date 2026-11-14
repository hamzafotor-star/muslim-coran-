import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum RepeatPlaybackMode {
  off('Désactivé'),
  surah('Répéter la sourate'),
  ayah('Répéter le verset');

  const RepeatPlaybackMode(this.label);
  final String label;
}

@immutable
class ReciterOption {
  const ReciterOption({
    required this.id,
    required this.name,
    required this.style,
    required this.baseUrl,
  });

  final int id;
  final String name;
  final String style;
  final String baseUrl;

  String surahAudioUrl(int surahId) {
    final String padded = surahId.clamp(1, 114).toString().padLeft(3, '0');
    return '$baseUrl$padded.mp3';
  }
}

@immutable
class AudioPlaybackState {
  const AudioPlaybackState({
    this.isPlaying = false,
    this.isVisible = false,
    this.currentSurahId = 1,
    this.currentSurahName = 'Al-Fâtiha',
    this.currentAyahNumber = 1,
    this.totalAyahsInSurah = 7,
    this.reciter = defaultRecitersFirst,
    this.position = Duration.zero,
    this.duration = const Duration(minutes: 1, seconds: 15),
    this.speed = 1.0,
    this.repeatMode = RepeatPlaybackMode.off,
    this.sleepTimerMinutes,
    this.isOfflineFile = false,
    this.errorMessage,
  });

  /// Nombre canonique de versets pour chacune des 114 sourates du Coran.
  static const List<int> surahAyahCounts = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6,
  ];

  static int ayahCountForSurah(int surahId) {
    final int idx = surahId.clamp(1, 114) - 1;
    return surahAyahCounts[idx];
  }

  static const ReciterOption defaultRecitersFirst = ReciterOption(
    id: 1,
    name: 'Mishary Rashid Al-Afasy (مشاري العفاسي)',
    style: 'Murattal · 128 kbps',
    baseUrl:
        'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/',
  );

  static const List<ReciterOption> availableReciters = <ReciterOption>[
    defaultRecitersFirst,
    ReciterOption(
      id: 2,
      name: 'Abdullah Al-Matrood (عبد الله المطرود)',
      style: 'Murattal · 128 kbps',
      baseUrl: 'https://download.quranicaudio.com/quran/abdullah_matroud/',
    ),
    ReciterOption(
      id: 3,
      name: 'Abdul Basit Abdus Samad (عبد الباسط عبد الصمد)',
      style: 'Murattal · 192 kbps',
      baseUrl: 'https://download.quranicaudio.com/quran/abdul_basit_murattal/',
    ),
    ReciterOption(
      id: 4,
      name: 'Abdur-Rahman As-Sudais (عبد الرحمن السديس)',
      style: 'Haramain · La Mecque',
      baseUrl:
          'https://download.quranicaudio.com/quran/abdurrahmaan_as-sudays/',
    ),
    ReciterOption(
      id: 5,
      name: 'Maher Al-Muaiqly (ماهر المعيقلي)',
      style: 'Haramain · La Mecque',
      baseUrl: 'https://download.quranicaudio.com/quran/maher_256/',
    ),
    ReciterOption(
      id: 6,
      name: 'Saad Al-Ghamdi (سعد الغامدي)',
      style: 'Murattal · 128 kbps',
      baseUrl:
          'https://download.quranicaudio.com/quran/sa3d_al-ghaamidi/complete/',
    ),
    ReciterOption(
      id: 7,
      name: 'Mahmoud Khalil Al-Husary (محمود خليل الحصري)',
      style: 'Murattal / Tajweed',
      baseUrl:
          'https://download.quranicaudio.com/quran/mahmood_khaleel_al-husaree/',
    ),
    ReciterOption(
      id: 8,
      name: 'Mohamed Siddiq Al-Minshawi (محمد صديق المنشاوي)',
      style: 'Murattal classique',
      baseUrl:
          'https://download.quranicaudio.com/quran/muhammad_siddeeq_al-minshaawee/',
    ),
    ReciterOption(
      id: 9,
      name: 'Saud Ash-Shuraim (سعود الشريم)',
      style: 'Haramain · La Mecque',
      baseUrl: 'https://download.quranicaudio.com/quran/sa3ood_al-shuraym/',
    ),
    ReciterOption(
      id: 10,
      name: 'Yasser Ad-Dossari (ياسر الدوسري)',
      style: 'Haramain · La Mecque',
      baseUrl: 'https://download.quranicaudio.com/quran/yasser_ad-dussary/',
    ),
    ReciterOption(
      id: 11,
      name: 'Abu Bakr Ash-Shatri (أبو بكر الشاطري)',
      style: 'Murattal · 128 kbps',
      baseUrl: 'https://download.quranicaudio.com/quran/abu_bakr_ash-shaatree/',
    ),
    ReciterOption(
      id: 12,
      name: 'Fares Abbad (فارس عباد)',
      style: 'Murattal · 128 kbps',
      baseUrl: 'https://download.quranicaudio.com/quran/fares/',
    ),
  ];

  final bool isPlaying;
  final bool isVisible;
  final int currentSurahId;
  final String currentSurahName;
  final int currentAyahNumber;
  final int totalAyahsInSurah;
  final ReciterOption reciter;
  final Duration position;
  final Duration duration;
  final double speed;
  final RepeatPlaybackMode repeatMode;
  final int? sleepTimerMinutes;
  final bool isOfflineFile;
  final String? errorMessage;

  double get progressFraction {
    if (duration.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioPlaybackState copyWith({
    bool? isPlaying,
    bool? isVisible,
    int? currentSurahId,
    String? currentSurahName,
    int? currentAyahNumber,
    int? totalAyahsInSurah,
    ReciterOption? reciter,
    Duration? position,
    Duration? duration,
    double? speed,
    RepeatPlaybackMode? repeatMode,
    int? sleepTimerMinutes,
    bool clearSleepTimer = false,
    bool? isOfflineFile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AudioPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isVisible: isVisible ?? this.isVisible,
      currentSurahId: currentSurahId ?? this.currentSurahId,
      currentSurahName: currentSurahName ?? this.currentSurahName,
      currentAyahNumber: currentAyahNumber ?? this.currentAyahNumber,
      totalAyahsInSurah: totalAyahsInSurah ?? this.totalAyahsInSurah,
      reciter: reciter ?? this.reciter,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      sleepTimerMinutes: clearSleepTimer
          ? null
          : (sleepTimerMinutes ?? this.sleepTimerMinutes),
      isOfflineFile: isOfflineFile ?? this.isOfflineFile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Contrôleur de lecture audio du Coran (M3 / E09) :
/// - Supporte la lecture locale hors ligne (depuis le dossier privé de l'application)
///   ou le streaming HTTPS depuis QuranicAudio / EveryAyah.
/// - Gère la vitesse (`0.75×` à `1.5×`), la répétition, le minuteur de sommeil
///   et la synchronisation du verset actif.
class AudioController extends StateNotifier<AudioPlaybackState> {
  AudioController() : super(const AudioPlaybackState()) {
    _initPlayerStreams();
  }

  final AudioPlayer _player = AudioPlayer();
  Timer? _sleepTimer;
  bool _handlingCompletion = false;

  void _initPlayerStreams() {
    _player.positionStream.listen((Duration pos) {
      if (!mounted) return;
      if (state.isPlaying && state.duration.inMilliseconds > 0) {
        final int computedAyah =
            ((pos.inMilliseconds / state.duration.inMilliseconds) *
                        state.totalAyahsInSurah)
                    .floor() +
                1;
        state = state.copyWith(
          position: pos,
          currentAyahNumber: computedAyah.clamp(1, state.totalAyahsInSurah),
        );
      } else {
        state = state.copyWith(position: pos);
      }
    });
    _player.durationStream.listen((Duration? dur) {
      if (dur != null && mounted) {
        state = state.copyWith(duration: dur);
      }
    });
    _player.playerStateStream.listen((PlayerState ps) {
      if (!mounted) return;
      if (ps.processingState == ProcessingState.completed) {
        if (state.repeatMode == RepeatPlaybackMode.surah ||
            state.repeatMode == RepeatPlaybackMode.ayah) {
          _player.seek(Duration.zero);
          _player.play();
        } else if (state.currentSurahId < 114 && !_handlingCompletion) {
          _handlingCompletion = true;
          nextSurah().whenComplete(() {
            _handlingCompletion = false;
          });
        } else if (state.currentSurahId >= 114) {
          state = state.copyWith(isPlaying: false);
        }
      }
    });
  }

  int _targetMsForAyah(int ayahNumber, int totalAyahs, int durationMs) {
    if (ayahNumber <= 1 || durationMs <= 0 || totalAyahs <= 1) return 0;
    final int raw = (((ayahNumber - 1) / totalAyahs) * durationMs).ceil();
    if (raw >= durationMs) return durationMs;
    return (raw + 1).clamp(0, durationMs);
  }

  Future<void> playSurah({
    required int surahId,
    required String surahName,
    int activeAyahNumber = 1,
    int? totalAyahs,
  }) async {
    final int resolvedSurahId = surahId.clamp(1, 114);
    final int resolvedTotal = (totalAyahs != null && totalAyahs > 0)
        ? totalAyahs
        : AudioPlaybackState.ayahCountForSurah(resolvedSurahId);
    final int resolvedAyah = activeAyahNumber.clamp(1, resolvedTotal);

    state = state.copyWith(
      isVisible: true,
      isPlaying: true,
      currentSurahId: resolvedSurahId,
      currentSurahName: surahName,
      currentAyahNumber: resolvedAyah,
      totalAyahsInSurah: resolvedTotal,
      clearError: true,
    );

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String padded = resolvedSurahId.toString().padLeft(3, '0');
      final File localFile = File(
        p.join(appDir.path, 'audio', 'reciter_${state.reciter.id}', '$padded.mp3'),
      );

      Duration? loadedDuration;
      if (localFile.existsSync()) {
        state = state.copyWith(isOfflineFile: true);
        loadedDuration = await _player.setFilePath(localFile.path);
      } else {
        state = state.copyWith(isOfflineFile: false);
        loadedDuration =
            await _player.setUrl(state.reciter.surahAudioUrl(resolvedSurahId));
      }
      if (loadedDuration != null && loadedDuration.inMilliseconds > 0) {
        state = state.copyWith(duration: loadedDuration);
        if (resolvedAyah > 1) {
          final int targetMs = _targetMsForAyah(
            resolvedAyah,
            resolvedTotal,
            loadedDuration.inMilliseconds,
          );
          final Duration targetPos = Duration(milliseconds: targetMs);
          state = state.copyWith(position: targetPos);
          await _player.seek(targetPos);
        }
      }
      await _player.setSpeed(state.speed);
      await _player.play();
    } catch (_) {
      state = state.copyWith(
        isPlaying: false,
        errorMessage:
            'Aucune connexion Internet et fichier audio non téléchargé hors ligne.',
      );
    }
  }

  Future<void> togglePlayPause() async {
    if (!state.isVisible) {
      await playSurah(
        surahId: state.currentSurahId,
        surahName: state.currentSurahName,
        activeAyahNumber: state.currentAyahNumber,
        totalAyahs: state.totalAyahsInSurah,
      );
      return;
    }

    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
      try {
        await _player.pause();
      } catch (_) {}
    } else {
      state = state.copyWith(isPlaying: true, clearError: true);
      try {
        await _player.play();
      } catch (_) {}
    }
  }

  Future<void> closePlayer() async {
    state = state.copyWith(isPlaying: false, isVisible: false);
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> seekTo(Duration target) async {
    state = state.copyWith(position: target);
    try {
      await _player.seek(target);
    } catch (_) {}
  }

  Future<void> seekToAyah(int ayahNumber) async {
    final int targetAyah = ayahNumber.clamp(1, state.totalAyahsInSurah);
    final int durationMs = state.duration.inMilliseconds;
    if (durationMs > 0) {
      final int targetMs = _targetMsForAyah(
        targetAyah,
        state.totalAyahsInSurah,
        durationMs,
      );
      final Duration targetPos = Duration(milliseconds: targetMs);
      state = state.copyWith(
        currentAyahNumber: targetAyah,
        position: targetPos,
      );
      try {
        await _player.seek(targetPos);
      } catch (_) {}
    } else {
      state = state.copyWith(currentAyahNumber: targetAyah);
    }
  }

  Future<void> nextAyah() async {
    final int target =
        (state.currentAyahNumber + 1).clamp(1, state.totalAyahsInSurah);
    await seekToAyah(target);
  }

  Future<void> previousAyah() async {
    final int target =
        (state.currentAyahNumber - 1).clamp(1, state.totalAyahsInSurah);
    await seekToAyah(target);
  }

  Future<void> skipBySeconds(int deltaSeconds) async {
    final int nextMs = (state.position.inMilliseconds + (deltaSeconds * 1000))
        .clamp(0, state.duration.inMilliseconds);
    await seekTo(Duration(milliseconds: nextMs));
  }

  Future<void> previousSurah() async {
    final int prev = (state.currentSurahId - 1).clamp(1, 114);
    await playSurah(
      surahId: prev,
      surahName: 'Sourate $prev',
      totalAyahs: AudioPlaybackState.ayahCountForSurah(prev),
    );
  }

  Future<void> nextSurah() async {
    final int next = (state.currentSurahId + 1).clamp(1, 114);
    await playSurah(
      surahId: next,
      surahName: 'Sourate $next',
      totalAyahs: AudioPlaybackState.ayahCountForSurah(next),
    );
  }

  Future<void> setSpeed(double newSpeed) async {
    final double clamped = newSpeed.clamp(0.75, 1.75);
    state = state.copyWith(speed: clamped);
    try {
      await _player.setSpeed(clamped);
    } catch (_) {}
  }

  void cycleRepeatMode() {
    final int nextIdx =
        (state.repeatMode.index + 1) % RepeatPlaybackMode.values.length;
    state = state.copyWith(repeatMode: RepeatPlaybackMode.values[nextIdx]);
  }

  void setReciter(ReciterOption reciter) {
    state = state.copyWith(reciter: reciter);
    if (state.isPlaying) {
      playSurah(
        surahId: state.currentSurahId,
        surahName: state.currentSurahName,
        activeAyahNumber: state.currentAyahNumber,
        totalAyahs: state.totalAyahsInSurah,
      );
    }
  }

  void setSleepTimerMinutes(int? minutes) {
    _sleepTimer?.cancel();
    if (minutes == null || minutes <= 0) {
      state = state.copyWith(clearSleepTimer: true);
      return;
    }
    state = state.copyWith(sleepTimerMinutes: minutes);
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      if (mounted && state.isPlaying) {
        togglePlayPause();
        state = state.copyWith(clearSleepTimer: true);
      }
    });
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final StateNotifierProvider<AudioController, AudioPlaybackState>
    audioControllerProvider =
    StateNotifierProvider<AudioController, AudioPlaybackState>(
  (Ref ref) => AudioController(),
);
