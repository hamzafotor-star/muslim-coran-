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
    this.reciter = defaultRecitersFirst,
    this.position = Duration.zero,
    this.duration = const Duration(minutes: 1, seconds: 15),
    this.speed = 1.0,
    this.repeatMode = RepeatPlaybackMode.off,
    this.sleepTimerMinutes,
    this.isOfflineFile = false,
    this.errorMessage,
  });

  static const ReciterOption defaultRecitersFirst = ReciterOption(
    id: 1,
    name: 'Mishary Rashid Al-Afasy',
    style: 'Murattal',
    baseUrl:
        'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/',
  );

  static const List<ReciterOption> availableReciters = <ReciterOption>[
    defaultRecitersFirst,
    ReciterOption(
      id: 2,
      name: 'Mahmoud Khalil Al-Husary',
      style: 'Murattal',
      baseUrl:
          'https://download.quranicaudio.com/quran/mahmood_khaleel_al-husaree/',
    ),
  ];

  final bool isPlaying;
  final bool isVisible;
  final int currentSurahId;
  final String currentSurahName;
  final int currentAyahNumber;
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

  void _initPlayerStreams() {
    _player.positionStream.listen((Duration pos) {
      if (mounted) {
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
        } else {
          state = state.copyWith(isPlaying: false);
        }
      }
    });
  }

  Future<void> playSurah({
    required int surahId,
    required String surahName,
    int activeAyahNumber = 1,
  }) async {
    state = state.copyWith(
      isVisible: true,
      isPlaying: true,
      currentSurahId: surahId.clamp(1, 114),
      currentSurahName: surahName,
      currentAyahNumber: activeAyahNumber,
      clearError: true,
    );

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String padded = surahId.clamp(1, 114).toString().padLeft(3, '0');
      final File localFile = File(
        p.join(appDir.path, 'audio', 'reciter_${state.reciter.id}', '$padded.mp3'),
      );

      if (localFile.existsSync()) {
        state = state.copyWith(isOfflineFile: true);
        await _player.setFilePath(localFile.path);
      } else {
        state = state.copyWith(isOfflineFile: false);
        await _player.setUrl(state.reciter.surahAudioUrl(surahId));
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

  Future<void> seekTo(Duration target) async {
    state = state.copyWith(position: target);
    try {
      await _player.seek(target);
    } catch (_) {}
  }

  Future<void> skipBySeconds(int deltaSeconds) async {
    final int nextMs = (state.position.inMilliseconds + (deltaSeconds * 1000))
        .clamp(0, state.duration.inMilliseconds);
    await seekTo(Duration(milliseconds: nextMs));
  }

  Future<void> previousSurah() async {
    final int prev = (state.currentSurahId - 1).clamp(1, 114);
    await playSurah(surahId: prev, surahName: 'Sourate $prev');
  }

  Future<void> nextSurah() async {
    final int next = (state.currentSurahId + 1).clamp(1, 114);
    await playSurah(surahId: next, surahName: 'Sourate $next');
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
