// lib/src/audio/audio_manager.dart
import 'package:audioplayers/audioplayers.dart';

/// Gerencia o áudio de fundo e efeitos sonoros do jogo.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  late final AudioPlayer _bgPlayer;
  // ✅ Adiciona um player dedicado para efeitos sonoros (SFX)
  late final AudioPlayer _sfxPlayer;

  bool _initialized = false;
  bool _muted = false;
  
  /// Inicializa os players de áudio.
  Future<void> init() async {
    if (_initialized) return;
    
    // Configura o player de música de fundo para tocar em loop
    _bgPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(0.5);

    // ✅ Configura o player de SFX para parar o som anterior antes de tocar um novo
    _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

    _initialized = true;
  }

  // --- MÉTODOS DE MÚSICA DE FUNDO (Sem alterações) ---

  Future<void> playBackground() async {
    if (!_initialized) await init();
    if (_muted) return;
    await _bgPlayer.play(AssetSource('audio/background.mp3'));
  }

  Future<void> pauseBackground() async {
    if (!_initialized) return;
    await _bgPlayer.pause();
  }

  Future<void> toggleMute() async {
    if (!_initialized) await init();
    _muted = !_muted;
    if (_muted) {
      await _bgPlayer.setVolume(0);
      // Podemos também parar os SFX se o jogo for mutado
      await _sfxPlayer.setVolume(0);
    } else {
      await _bgPlayer.setVolume(0.5);
      await _sfxPlayer.setVolume(1.0);
      await _bgPlayer.resume();
    }
  }

  // --- MÉTODOS DE EFEITOS SONOROS (Usando o novo _sfxPlayer) ---

  Future<void> playSwapSound() async {
    if (_muted) return;
    await _sfxPlayer.play(AssetSource('audio/swap.wav'));
  }

  Future<void> playMatchSound() async {
    if (_muted) return;
    await _sfxPlayer.play(AssetSource('audio/match.wav'));
  }

  Future<void> playSpecialSound() async {
    if (_muted) return;
    await _sfxPlayer.play(AssetSource('audio/special.wav'));
  }

  // ✅ MÉTODO QUE ESTAVA FALTANDO, agora usando o _sfxPlayer
  Future<void> playErrorSound() async {
    if (_muted) return;
    await _sfxPlayer.play(AssetSource('audio/error.wav'));
  }

  /// Libera recursos de áudio.
  Future<void> dispose() async {
    if (_initialized) {
      await _bgPlayer.dispose();
      // ✅ Libera o player de SFX também
      await _sfxPlayer.dispose();
    }
  }
}