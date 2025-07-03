import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

/// 🎮 Game State Manager with Bomb Tutorial Integration
/// This version includes integration with the bomb tutorial system
class GameStateManager extends ChangeNotifier {
  static GameStateManager? _instance;
  static GameStateManager get instance => _instance ??= GameStateManager._();

  GameStateManager._();

  // Game state
  int _currentLevel = 1;
  List<bool> _levelCompleted = List.filled(100, false);
  List<int> _levelStars = List.filled(100, 0);
  Map<String, dynamic> _playerStats = {};
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;

  // ✅ NOVO: Integração com tutorial da bomba
  bool _bombTutorialShown = false;
  bool _firstBombEncountered = false;

  // Getters
  int get currentLevel => _currentLevel;
  List<bool> get levelCompleted => List.unmodifiable(_levelCompleted);
  List<int> get levelStars => List.unmodifiable(_levelStars);
  Map<String, dynamic> get playerStats => Map.unmodifiable(_playerStats);
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  // ✅ NOVO: Getters para tutorial da bomba
  bool get bombTutorialShown => _bombTutorialShown;
  bool get firstBombEncountered => _firstBombEncountered;

  // Calculated statistics
  int get totalStars => _levelStars.fold(0, (sum, stars) => sum + stars);
  int get completedLevels =>
      _levelCompleted.where((completed) => completed).length;
  double get completionPercentage => completedLevels / _levelCompleted.length;

  /// Initialize manager by loading saved data
  Future<void> initialize() async {
    await _loadGameData();
    if (kDebugMode) {
      print("[GAME_STATE] Manager initialized");
      print("[GAME_STATE] Current level: $_currentLevel");
      print("[GAME_STATE] Completed levels: $completedLevels");
      print("[GAME_STATE] Total stars: $totalStars");
      print("[GAME_STATE] Bomb tutorial shown: $_bombTutorialShown");
      print("[GAME_STATE] First bomb encountered: $_firstBombEncountered");
    }
  }

  /// Mark a level as completed
  Future<void> completeLevel(int level,
      {int stars = 3, Map<String, dynamic>? stats}) async {
    if (level < 1 || level > _levelCompleted.length) {
      if (kDebugMode) {
        print("[GAME_STATE] ❌ Invalid level: $level");
      }
      return;
    }

    final levelIndex = level - 1;
    final wasAlreadyCompleted = _levelCompleted[levelIndex];

    // Update state
    _levelCompleted[levelIndex] = true;

    // Update stars (keep highest score)
    if (stars > _levelStars[levelIndex]) {
      _levelStars[levelIndex] = stars.clamp(0, 3);
    }

    // Advance to next level if necessary
    if (!wasAlreadyCompleted && level == _currentLevel) {
      _currentLevel = math.min(_currentLevel + 1, _levelCompleted.length);
    }

    // Update statistics
    if (stats != null) {
      _updatePlayerStats(level, stats);
    }

    // Save data
    await _saveGameData();

    // Notify listeners
    notifyListeners();

    if (kDebugMode) {
      print("[GAME_STATE] ✅ Level $level completed with $stars stars");
      if (!wasAlreadyCompleted) {
        print("[GAME_STATE] 🎉 First completion of level $level!");
      }
    }
  }

  /// ✅ NOVO: Marca que o tutorial da bomba foi mostrado
  Future<void> markBombTutorialShown() async {
    _bombTutorialShown = true;
    await _saveGameData();
    notifyListeners();

    if (kDebugMode) {
      print("[GAME_STATE] 🎓 Tutorial da bomba marcado como mostrado");
    }
  }

  /// ✅ NOVO: Marca que a primeira bomba foi encontrada
  Future<void> markFirstBombEncountered() async {
    _firstBombEncountered = true;
    await _saveGameData();
    notifyListeners();

    if (kDebugMode) {
      print("[GAME_STATE] 💣 Primeira bomba marcada como encontrada");
    }
  }

  /// ✅ NOVO: Verifica se deve mostrar tutorial da bomba
  bool shouldShowBombTutorial() {
    return !_bombTutorialShown && !_firstBombEncountered;
  }

  /// Unlock a specific level (for debug/admin)
  Future<void> unlockLevel(int level) async {
    if (level < 1 || level > _levelCompleted.length) return;

    _currentLevel = math.max(_currentLevel, level);
    await _saveGameData();
    notifyListeners();

    if (kDebugMode) {
      print("[GAME_STATE] 🔓 Level $level unlocked");
    }
  }

  /// Reset game progress
  Future<void> resetProgress() async {
    _currentLevel = 1;
    _levelCompleted = List.filled(100, false);
    _levelStars = List.filled(100, 0);
    _playerStats.clear();

    // ✅ NOVO: Reset tutorial flags
    _bombTutorialShown = false;
    _firstBombEncountered = false;

    await _saveGameData();
    notifyListeners();

    if (kDebugMode) {
      print("[GAME_STATE] 🔄 Progress reset (including bomb tutorial)");
    }
  }

  /// ✅ NOVO: Reset apenas flags do tutorial (para debug)
  Future<void> resetBombTutorialFlags() async {
    if (!kDebugMode) {
      print("[GAME_STATE] ⚠️ Tutorial reset só é permitido em modo debug");
      return;
    }

    _bombTutorialShown = false;
    _firstBombEncountered = false;

    await _saveGameData();
    notifyListeners();

    if (kDebugMode) {
      print("[GAME_STATE] 🔄 Flags do tutorial da bomba resetadas (DEBUG)");
    }
  }

  /// Update audio/haptics settings
  Future<void> updateSettings({
    bool? sound,
    bool? music,
    bool? haptics,
  }) async {
    if (sound != null) _soundEnabled = sound;
    if (music != null) _musicEnabled = music;
    if (haptics != null) _hapticsEnabled = haptics;

    await _saveGameData();
    notifyListeners();

    if (kDebugMode) {
      print("[GAME_STATE] ⚙️ Settings updated");
    }
  }

  /// Check if a level is unlocked
  bool isLevelUnlocked(int level) {
    return level <= _currentLevel;
  }

  /// Get statistics for a specific level
  Map<String, dynamic>? getLevelStats(int level) {
    return _playerStats['level_$level'];
  }

  /// Update player statistics with proper type handling
  void _updatePlayerStats(int level, Map<String, dynamic> stats) {
    final levelKey = 'level_$level';

    if (!_playerStats.containsKey(levelKey)) {
      _playerStats[levelKey] = <String, dynamic>{};
    }

    final levelStats = _playerStats[levelKey] as Map<String, dynamic>;

    // Update specific statistics with proper type handling
    stats.forEach((key, value) {
      switch (key) {
        case 'moves_used':
          final currentBest = levelStats['best_moves'] as int?;
          final newValue = value as int;
          levelStats['best_moves'] =
              currentBest != null ? math.min(currentBest, newValue) : newValue;
          break;

        case 'time_taken':
          final currentBest = levelStats['best_time'] as num?;
          final newValue = value as num;
          levelStats['best_time'] =
              currentBest != null ? math.min(currentBest, newValue) : newValue;
          break;

        case 'score':
          final currentBest = levelStats['best_score'] as int?;
          final newValue = value as int;
          levelStats['best_score'] =
              currentBest != null ? math.max(currentBest, newValue) : newValue;
          break;

        default:
          levelStats[key] = value;
      }
    });

    // Increment attempt counter
    levelStats['attempts'] = (levelStats['attempts'] as int? ?? 0) + 1;
    levelStats['last_played'] = DateTime.now().millisecondsSinceEpoch;
  }

  /// Load saved data from SharedPreferences
  Future<void> _loadGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load current level
      _currentLevel = prefs.getInt('current_level') ?? 1;

      // Load completed levels
      final completedString = prefs.getString('levels_completed');
      if (completedString != null) {
        final completedList = json.decode(completedString) as List;
        _levelCompleted = completedList.cast<bool>();
      }

      // Load stars
      final starsString = prefs.getString('level_stars');
      if (starsString != null) {
        final starsList = json.decode(starsString) as List;
        _levelStars = starsList.cast<int>();
      }

      // Load statistics
      final statsString = prefs.getString('player_stats');
      if (statsString != null) {
        _playerStats = json.decode(statsString) as Map<String, dynamic>;
      }

      // Load settings
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;

      // ✅ NOVO: Load bomb tutorial flags
      _bombTutorialShown = prefs.getBool('bomb_tutorial_shown') ?? false;
      _firstBombEncountered = prefs.getBool('first_bomb_encountered') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print("[GAME_STATE] ❌ Error loading data: $e");
      }
    }
  }

  /// Save data to SharedPreferences
  Future<void> _saveGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save current level
      await prefs.setInt('current_level', _currentLevel);

      // Save completed levels
      await prefs.setString('levels_completed', json.encode(_levelCompleted));

      // Save stars
      await prefs.setString('level_stars', json.encode(_levelStars));

      // Save statistics
      await prefs.setString('player_stats', json.encode(_playerStats));

      // Save settings
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('music_enabled', _musicEnabled);
      await prefs.setBool('haptics_enabled', _hapticsEnabled);

      // ✅ NOVO: Save bomb tutorial flags
      await prefs.setBool('bomb_tutorial_shown', _bombTutorialShown);
      await prefs.setBool('first_bomb_encountered', _firstBombEncountered);
    } catch (e) {
      if (kDebugMode) {
        print("[GAME_STATE] ❌ Error saving data: $e");
      }
    }
  }
}

/// 📊 Extension for advanced statistics with proper type handling
extension GameStateAnalytics on GameStateManager {
  /// Calculate average time per level
  double get averageTimePerLevel {
    double totalTime = 0;
    int levelsWithTime = 0;

    for (int i = 1; i <= completedLevels; i++) {
      final stats = getLevelStats(i);
      if (stats != null && stats['best_time'] != null) {
        totalTime += (stats['best_time'] as num).toDouble();
        levelsWithTime++;
      }
    }

    return levelsWithTime > 0 ? totalTime / levelsWithTime : 0;
  }

  /// Calculate average efficiency (stars/attempts)
  double get averageEfficiency {
    double totalEfficiency = 0;
    int levelsWithAttempts = 0;

    for (int i = 1; i <= completedLevels; i++) {
      final stats = getLevelStats(i);
      final stars = _levelStars[i - 1];

      if (stats != null && stats['attempts'] != null && stats['attempts'] > 0) {
        totalEfficiency += stars / (stats['attempts'] as int);
        levelsWithAttempts++;
      }
    }

    return levelsWithAttempts > 0 ? totalEfficiency / levelsWithAttempts : 0;
  }

  /// Get level with best performance
  int get bestPerformanceLevel {
    int bestLevel = 1;
    double bestRatio = 0;

    for (int i = 1; i <= completedLevels; i++) {
      final stars = _levelStars[i - 1];
      final stats = getLevelStats(i);

      if (stats != null && stats['attempts'] != null && stats['attempts'] > 0) {
        final ratio = stars / (stats['attempts'] as int);
        if (ratio > bestRatio) {
          bestRatio = ratio;
          bestLevel = i;
        }
      }
    }

    return bestLevel;
  }
}

/// 🛠️ Utility class for safe mathematical operations
class SafeMath {
  /// Safe min function that handles dynamic types
  static T safeMin<T extends num>(dynamic a, dynamic b) {
    if (a is! T || b is! T) {
      throw ArgumentError('Both arguments must be of type $T');
    }
    return math.min(a as T, b as T);
  }

  /// Safe max function that handles dynamic types
  static T safeMax<T extends num>(dynamic a, dynamic b) {
    if (a is! T || b is! T) {
      throw ArgumentError('Both arguments must be of type $T');
    }
    return math.max(a as T, b as T);
  }

  /// Flexible min that works with any numeric types
  static num flexibleMin(num a, num b) => math.min(a, b);

  /// Flexible max that works with any numeric types
  static num flexibleMax(num a, num b) => math.max(a, b);
}
