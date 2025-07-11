import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

/// Zen Audio Manager
/// Handles ambient nature sounds for the Zen garden environment
class ZenAudioManager {
  static final ZenAudioManager _instance = ZenAudioManager._internal();
  factory ZenAudioManager() => _instance;
  ZenAudioManager._internal();

  // Audio players for different sound layers
  late final AudioPlayer _ambientPlayer;
  late final AudioPlayer _windPlayer;
  late final AudioPlayer _naturePlayer;
  late final AudioPlayer _sfxPlayer;

  bool _initialized = false;
  bool _muted = false;
  bool _isPlaying = false;

  // Ambient sound settings
  double _ambientVolume = 0.3;
  double _windVolume = 0.2;
  double _natureVolume = 0.25;
  double _sfxVolume = 0.4;

  // Timers for randomized nature sounds
  Timer? _windTimer;
  Timer? _leafTimer;
  Timer? _birdTimer;

  /// Initialize the Zen audio manager
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize audio players
      _ambientPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      _windPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      _naturePlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

      // Set initial volumes
      await _ambientPlayer.setVolume(_ambientVolume);
      await _windPlayer.setVolume(_windVolume);
      await _naturePlayer.setVolume(_natureVolume);
      await _sfxPlayer.setVolume(_sfxVolume);

      _initialized = true;
      print('Zen Audio Manager initialized successfully');
    } catch (e) {
      print('Failed to initialize Zen Audio Manager: $e');
    }
  }

  /// Start the ambient Zen garden sounds
  Future<void> startAmbientSounds() async {
    if (!_initialized) await init();
    if (_muted || _isPlaying) return;

    try {
      _isPlaying = true;

      // Start continuous ambient sounds
      await _startContinuousAmbient();

      // Start randomized nature sounds
      _startRandomizedNatureSounds();

      print('Zen ambient sounds started');
    } catch (e) {
      print('Failed to start ambient sounds: $e');
      _isPlaying = false;
    }
  }

  /// Stop all ambient sounds
  Future<void> stopAmbientSounds() async {
    if (!_initialized) return;

    _isPlaying = false;

    // Stop timers
    _windTimer?.cancel();
    _leafTimer?.cancel();
    _birdTimer?.cancel();

    // Stop audio players
    await _ambientPlayer.stop();
    await _windPlayer.stop();
    await _naturePlayer.stop();

    print('Zen ambient sounds stopped');
  }

  /// Start continuous ambient background sounds
  Future<void> _startContinuousAmbient() async {
    try {
      // For now, we'll use silence since we don't have specific ambient audio files
      // In a real implementation, you'd have:
      // - Gentle flowing water sounds
      // - Soft wind through bamboo
      // - Distant temple bells

      // Placeholder: Create a silent ambient track
      // await _ambientPlayer.play(AssetSource('audio/zen_ambient.mp3'));

      // Wind sounds (if available)
      // await _windPlayer.play(AssetSource('audio/zen_wind.mp3'));
    } catch (e) {
      print('Could not load ambient audio files: $e');
    }
  }

  /// Start randomized nature sounds with varying intervals
  void _startRandomizedNatureSounds() {
    // Wind gusts (every 10-30 seconds)
    _windTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      if (math.Random().nextInt(20) == 0) {
        // 5% chance per second
        _playWindGust();
      }
    });

    // Leaf rustling (every 5-15 seconds)
    _leafTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      if (math.Random().nextInt(12) == 0) {
        // ~8% chance per second
        _playLeafRustle();
      }
    });

    // Distant bird calls (every 30-60 seconds)
    _birdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      if (math.Random().nextInt(45) == 0) {
        // ~2% chance per second
        _playBirdCall();
      }
    });
  }

  /// Play a wind gust sound
  Future<void> _playWindGust() async {
    if (_muted) return;

    try {
      // In a real implementation, you'd have:
      // await _naturePlayer.play(AssetSource('audio/wind_gust.wav'));
      print('Wind gust sound played');
    } catch (e) {
      print('Could not play wind gust: $e');
    }
  }

  /// Play leaf rustling sound
  Future<void> _playLeafRustle() async {
    if (_muted) return;

    try {
      // In a real implementation, you'd have:
      // await _naturePlayer.play(AssetSource('audio/leaf_rustle.wav'));
      print('Leaf rustle sound played');
    } catch (e) {
      print('Could not play leaf rustle: $e');
    }
  }

  /// Play distant bird call
  Future<void> _playBirdCall() async {
    if (_muted) return;

    try {
      // In a real implementation, you'd have:
      // await _naturePlayer.play(AssetSource('audio/bird_call.wav'));
      print('Bird call sound played');
    } catch (e) {
      print('Could not play bird call: $e');
    }
  }

  /// Play meditation bell sound
  Future<void> playMeditationBell() async {
    if (_muted) return;

    try {
      // In a real implementation, you'd have:
      // await _sfxPlayer.play(AssetSource('audio/meditation_bell.wav'));
      print('Meditation bell sound played');
    } catch (e) {
      print('Could not play meditation bell: $e');
    }
  }

  /// Play stone placement sound
  Future<void> playStonePlacement() async {
    if (_muted) return;

    try {
      // In a real implementation, you'd have:
      // await _sfxPlayer.play(AssetSource('audio/stone_placement.wav'));
      print('Stone placement sound played');
    } catch (e) {
      print('Could not play stone placement: $e');
    }
  }

  /// Play water ripple sound
  Future<void> playWaterRipple() async {
    if (_muted) return;

    try {
      // In a real implementation, you'd have:
      // await _sfxPlayer.play(AssetSource('audio/water_ripple.wav'));
      print('Water ripple sound played');
    } catch (e) {
      print('Could not play water ripple: $e');
    }
  }

  /// Toggle mute state
  Future<void> toggleMute() async {
    if (!_initialized) await init();

    _muted = !_muted;

    if (_muted) {
      await _ambientPlayer.setVolume(0);
      await _windPlayer.setVolume(0);
      await _naturePlayer.setVolume(0);
      await _sfxPlayer.setVolume(0);
    } else {
      await _ambientPlayer.setVolume(_ambientVolume);
      await _windPlayer.setVolume(_windVolume);
      await _naturePlayer.setVolume(_natureVolume);
      await _sfxPlayer.setVolume(_sfxVolume);
    }

    print('Zen audio ${_muted ? 'muted' : 'unmuted'}');
  }

  /// Set volume levels
  Future<void> setVolumes({
    double? ambient,
    double? wind,
    double? nature,
    double? sfx,
  }) async {
    if (!_initialized) await init();

    if (ambient != null) {
      _ambientVolume = ambient.clamp(0.0, 1.0);
      await _ambientPlayer.setVolume(_muted ? 0 : _ambientVolume);
    }

    if (wind != null) {
      _windVolume = wind.clamp(0.0, 1.0);
      await _windPlayer.setVolume(_muted ? 0 : _windVolume);
    }

    if (nature != null) {
      _natureVolume = nature.clamp(0.0, 1.0);
      await _naturePlayer.setVolume(_muted ? 0 : _natureVolume);
    }

    if (sfx != null) {
      _sfxVolume = sfx.clamp(0.0, 1.0);
      await _sfxPlayer.setVolume(_muted ? 0 : _sfxVolume);
    }
  }

  /// Get current mute state
  bool get isMuted => _muted;

  /// Get current playing state
  bool get isPlaying => _isPlaying;

  /// Dispose resources
  Future<void> dispose() async {
    await stopAmbientSounds();

    await _ambientPlayer.dispose();
    await _windPlayer.dispose();
    await _naturePlayer.dispose();
    await _sfxPlayer.dispose();

    _initialized = false;
    print('Zen Audio Manager disposed');
  }
}

/// Zen Sound Effects Enum
enum ZenSoundEffect {
  meditationBell,
  stonePlacement,
  waterRipple,
  windGust,
  leafRustle,
  birdCall,
}

/// Extension to easily play Zen sound effects
extension ZenSoundEffectExtension on ZenSoundEffect {
  Future<void> play() async {
    final audioManager = ZenAudioManager();

    switch (this) {
      case ZenSoundEffect.meditationBell:
        await audioManager.playMeditationBell();
        break;
      case ZenSoundEffect.stonePlacement:
        await audioManager.playStonePlacement();
        break;
      case ZenSoundEffect.waterRipple:
        await audioManager.playWaterRipple();
        break;
      case ZenSoundEffect.windGust:
        await audioManager._playWindGust();
        break;
      case ZenSoundEffect.leafRustle:
        await audioManager._playLeafRustle();
        break;
      case ZenSoundEffect.birdCall:
        await audioManager._playBirdCall();
        break;
    }
  }
}
