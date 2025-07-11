import 'package:flutter/foundation.dart';
import '../engine/level_definition.dart';
import '../engine/petal_piece.dart';
import 'game_state_manager.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🎮 Gerenciador de Níveis - Sistema Modular (VERSÃO FINAL)
class LevelManager {
  static LevelManager? _instance;
  static LevelManager get instance => _instance ??= LevelManager._();

  LevelManager._();

  final Map<int, LevelDefinition> _levelCache = {};

  LevelDefinition loadLevel(int levelNumber) {
    if (_levelCache.containsKey(levelNumber)) {
      return _levelCache[levelNumber]!;
    }
    final level = _createLevelDefinition(levelNumber);
    _levelCache[levelNumber] = level;
    return level;
  }

  LevelDefinition _createLevelDefinition(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return _createLevel1();
      case 2:
        return _createLevel2();
      case 3:
        return _createLevel3();
      case 4:
        return _createLevel4();
      case 5:
        return _createLevel5();
      default:
        return _generateProceduralLevel(levelNumber);
    }
  }

  /// 🌸 Nível 1 - Tutorial Básico
  LevelDefinition _createLevel1() {
    return LevelDefinition(
      levelNumber: 1,
      width: 6,
      height: 8,
      moves: 15,
      objectives: {
        PetalType.cherry: 10,
        PetalType.maple: 8,

        // ✅ OBJETIVO ADICIONADO: Remover as 4 peças enjauladas.
        PetalType.caged1: 4,
      },
      layout: [
        // Linha 0 (topo)
        PetalType.empty, PetalType.empty, PetalType.empty, PetalType.empty,
        PetalType.empty, PetalType.empty,
        // Linhas 1 a 7 - '1' indica um espaço para peça jogável aleatória
        1, 1, 1, 1, 1, 1,
        1, 0, 0, 0, 0, 1,
        1, 0, 2, 2, 0, 1,
        1, 0, 2, 2, 0, 1,
        1, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1,
      ],
      title: "Primeiro Niwadama",
      description:
          "Liberte os ovos de Niwadama fazendo combinações ao lado deles!",
      difficulty: LevelDifficulty.easy,

      // ✅ 3. DEFINA AS PONTUAÇÕES PARA AS ESTRELAS
      starThresholds: [
        1000,
        2500,
        4000,
      ], // 1 estrela: 1000, 2 estrelas: 2500, 3 estrelas: 4000
      specialFeatures: [
        LevelFeature.tutorial,
        LevelFeature.cages,
      ], // Adiciona a feature de jaulas
    );
  }

  /// 🍁 Nível 2 - Introdução aos Obstáculos
  LevelDefinition _createLevel2() {
    // ✅ CORREÇÃO: Layout convertido para o formato de planta baixa (blueprint).
    return LevelDefinition(
      levelNumber: 2,
      width: 6,
      height: 8,
      moves: 20,
      objectives: {
        PetalType.cherry: 12,
        PetalType.maple: 10,
        PetalType.orchid: 8,
      },
      layout: [
        // Linha 0 (topo)
        PetalType.empty, PetalType.empty, PetalType.empty, PetalType.empty,
        PetalType.empty, PetalType.empty,
        // Layout com inteiros: 1 = Peça Jogável, 0 = Parede
        1, 1, 0, 0, 1, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 0, 0, 1, 1,
        1, 1, 1, 1, 1, 1,
      ],
      title: "Pedras no Caminho",
      description: "Cuidado com as pedras! Elas não podem ser movidas.",
      difficulty: LevelDifficulty.easy,

      // ✅ 3. DEFINA AS PONTUAÇÕES PARA AS ESTRELAS
      starThresholds: [
        1200, 2800, 4500
      ],
      specialFeatures: [LevelFeature.walls],
    );
  }

  /// 🌺 Nível 3 - Mais Cores
  LevelDefinition _createLevel3() {
    // Passo 1: Crie a lista base e armazene em uma variável.
    // ✅ CORREÇÃO: Adicionado 'growable: true' para criar uma lista modificável.
    final layout = List<dynamic>.filled(7 * 9, 1, growable: true);

    // Passo 2: Crie a lista de substituições.
    final replacements = [for (var i = 0; i < 7; ++i) PetalType.empty];

    // Passo 3: Modifique a lista 'layout' em si. Esta linha não retorna valor.
    layout.replaceRange(0, 7, replacements);

    // Passo 4: Passe a lista já modificada para o construtor.
    return LevelDefinition(
      levelNumber: 3,
      width: 7,
      height: 9,
      moves: 25,
      objectives: {
        PetalType.cherry: 15,
        PetalType.maple: 12,
        PetalType.orchid: 10,
        PetalType.plum: 8,
      },
      layout: layout, // Use a variável que foi modificada.
      title: "Jardim Colorido",
      description:
          "Agora com quatro tipos de pétalas! Planeje seus movimentos.",
      difficulty: LevelDifficulty.medium,

      // ✅ 3. DEFINA AS PONTUAÇÕES PARA AS ESTRELAS
      starThresholds: [
        1800, 4000, 6000
      ],
      specialFeatures: [LevelFeature.multiColor],
    );
  }

  /// 🥚 Nível 4 - Introdução às Jaulas
  LevelDefinition _createLevel4() {
    return LevelDefinition(
      levelNumber: 4,
      width: 6,
      height: 8,
      moves: 18,
      objectives: {
        PetalType.cherry: 10,
        PetalType.maple: 8,
        PetalType.caged1: 4, // Objetivo agora é a jaula
      },
      layout: [
        // Linha 0
        PetalType.empty, PetalType.empty, PetalType.empty, PetalType.empty,
        PetalType.empty, PetalType.empty,
        // Layout com inteiros: 1 = Peça Jogável, 2 = Jaula
        1, 1, 2, 2, 1, 1,
        1, 1, 1, 1, 1, 1,
        1, 2, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1,
      ],
      title: "Ovos Preciosos",
      description: "Quebre os ovos fazendo combinações ao lado deles!",
      difficulty: LevelDifficulty.medium,

      // ✅ 3. DEFINA AS PONTUAÇÕES PARA AS ESTRELAS
      starThresholds: [
        2400, 5200, 7500
      ], // 1 estrela: 1000, 2 estrelas: 2500, 3 estrelas: 4000
      specialFeatures: [LevelFeature.cages],
    );
  }

  /// 💣 Nível 5 - Primeira Bomba
  LevelDefinition _createLevel5() {
    // ✅ CORREÇÃO: Layout convertido para o formato de planta baixa (blueprint).
    return LevelDefinition(
      levelNumber: 5,
      width: 7,
      height: 9,
      moves: 22,
      objectives: {
        PetalType.cherry: 20,
        PetalType.maple: 15,
        PetalType.orchid: 12,
        PetalType.bomb: 1, // Usar a bomba
      },
      layout: [
        // Linha 0
        PetalType.empty, PetalType.empty, PetalType.empty, PetalType.empty,
        PetalType.empty, PetalType.empty, PetalType.empty,
        // Layout com inteiros: 1 = Peça, 0 = Parede, 4 = Bomba
        1, 1, 1, 0, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1,
        0, 1, 1, 4, 1, 1, 0,
        1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1,
      ],
      title: "Poder da Bomba",
      description:
          "Use a bomba para limpar uma grande área! Combine 5 pétalas para criar mais.",
      difficulty: LevelDifficulty.medium,

      // ✅ 3. DEFINA AS PONTUAÇÕES PARA AS ESTRELAS
      starThresholds: [
        3000,
        6400,
        9000,
      ], // 1 estrela: 1000, 2 estrelas: 2500, 3 estrelas: 4000
      specialFeatures: [LevelFeature.bombs, LevelFeature.walls],
    );
  }

  /// 🎲 Geração procedural para níveis não implementados
  LevelDefinition _generateProceduralLevel(int levelNumber) {
    final difficulty = _calculateDifficulty(levelNumber);
    final size = _calculateSize(levelNumber);
    final moves = _calculateMoves(levelNumber, difficulty);
    final objectives = _generateObjectives(levelNumber, difficulty);

    // ✅ CORREÇÃO: O layout procedural agora também gera uma planta baixa.
    final layout = _generateProceduralLayout(
      size.width,
      size.height,
      levelNumber,
    );

    // ✅ CHAMA A NOVA FUNÇÃO PARA GERAR AS METAS
    final starThresholds = _generateStarThresholds(levelNumber, difficulty);

    return LevelDefinition(
      levelNumber: levelNumber,
      width: size.width,
      height: size.height,
      moves: moves,
      objectives: objectives,
      layout: layout,
      title: "Jardim ${_getLevelTheme(levelNumber)}",
      description: _getLevelDescription(levelNumber),
      difficulty: difficulty,
      starThresholds: starThresholds, // ✅ PASSA AS METAS GERADAS
      specialFeatures: _getSpecialFeatures(levelNumber),
    );
  }

  /// 📊 Calcula dificuldade baseada no nível
  LevelDifficulty _calculateDifficulty(int levelNumber) {
    if (levelNumber <= 10) return LevelDifficulty.easy;
    if (levelNumber <= 20) return LevelDifficulty.medium;
    if (levelNumber <= 30) return LevelDifficulty.hard;
    return LevelDifficulty.expert;
  }

  /// 📐 Calcula tamanho do tabuleiro
  ({int width, int height}) _calculateSize(int levelNumber) {
    if (levelNumber <= 5) return (width: 6, height: 8);
    if (levelNumber <= 15) return (width: 7, height: 9);
    if (levelNumber <= 25) return (width: 8, height: 10);
    return (width: 9, height: 11);
  }

  /// 🎯 Calcula número de movimentos
  int _calculateMoves(int levelNumber, LevelDifficulty difficulty) {
    final baseMoves = switch (difficulty) {
      LevelDifficulty.easy => 20,
      LevelDifficulty.medium => 18,
      LevelDifficulty.hard => 15,
      LevelDifficulty.expert => 12,
    };

    // Adiciona variação baseada no nível
    final variation = (levelNumber % 5) - 2; // -2 a +2
    return (baseMoves + variation).clamp(10, 30);
  }

  /// 🎯 Gera objetivos do nível
  Map<PetalType, int> _generateObjectives(
    int levelNumber,
    LevelDifficulty difficulty,
  ) {
    final objectives = <PetalType, int>{};

    // Tipos básicos sempre presentes
    objectives[PetalType.cherry] = _getObjectiveCount(
      levelNumber,
      difficulty,
      1.0,
    );
    objectives[PetalType.maple] = _getObjectiveCount(
      levelNumber,
      difficulty,
      0.8,
    );

    // Adiciona mais tipos conforme o nível
    if (levelNumber >= 3) {
      objectives[PetalType.orchid] = _getObjectiveCount(
        levelNumber,
        difficulty,
        0.6,
      );
    }
    if (levelNumber >= 5) {
      objectives[PetalType.plum] = _getObjectiveCount(
        levelNumber,
        difficulty,
        0.5,
      );
    }
    if (levelNumber >= 8) {
      objectives[PetalType.lily] = _getObjectiveCount(
        levelNumber,
        difficulty,
        0.4,
      );
    }
    if (levelNumber >= 12) {
      objectives[PetalType.peony] = _getObjectiveCount(
        levelNumber,
        difficulty,
        0.3,
      );
    }

    // Objetivos especiais
    if (levelNumber >= 4 && levelNumber % 3 == 1) {
      objectives[PetalType.caged2] = (levelNumber / 4).ceil().clamp(2, 8);
    }
    if (levelNumber >= 5 && levelNumber % 5 == 0) {
      objectives[PetalType.bomb] = 1;
    }

    return objectives;
  }

  /// 📊 Calcula quantidade de objetivo
  int _getObjectiveCount(
    int levelNumber,
    LevelDifficulty difficulty,
    double multiplier,
  ) {
    final baseCount = switch (difficulty) {
      LevelDifficulty.easy => 12,
      LevelDifficulty.medium => 15,
      LevelDifficulty.hard => 18,
      LevelDifficulty.expert => 22,
    };

    return ((baseCount * multiplier) + (levelNumber * 0.5)).round().clamp(
      5,
      30,
    );
  }

  /// 🎲 Gera metas de pontuação para as estrelas baseado no nível e dificuldade
  List<int> _generateStarThresholds(
    int levelNumber,
    LevelDifficulty difficulty,
  ) {
    // Fator base para a pontuação
    final baseScore = 1500;
    // Bônus por nível
    final levelBonus = levelNumber * 150;
    // Multiplicador de dificuldade
    final difficultyMultiplier = switch (difficulty) {
      LevelDifficulty.easy => 1.0,
      LevelDifficulty.medium => 1.4,
      LevelDifficulty.hard => 1.8,
      LevelDifficulty.expert => 2.2,
    };

    // Calcula a pontuação para a primeira estrela
    final oneStar = ((baseScore + levelBonus) * difficultyMultiplier).round();

    // As outras estrelas são múltiplos da primeira
    return [
      oneStar, // 1 estrela
      (oneStar * 2.5).round(), // 2 estrelas
      (oneStar * 4).round(), // 3 estrelas
    ];
  }

  /// 🗺️ ✅ CORREÇÃO: Gera layout procedural como uma planta baixa de inteiros.
  List<dynamic> _generateProceduralLayout(
    int width,
    int height,
    int levelNumber,
  ) {
    final layout = <dynamic>[];
    final random = _createSeededRandom(levelNumber);

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if (row == 0) {
          // Primeira linha sempre vazia para spawn
          layout.add(PetalType.empty);
        } else {
          // Adiciona obstáculos ocasionalmente
          if (_shouldAddObstacle(levelNumber, row, col, random)) {
            layout.add(_getRandomObstacleBlueprint(levelNumber, random));
          } else {
            // Adiciona um espaço para peça jogável
            layout.add(1);
          }
        }
      }
    }
    return layout;
  }

  /// 🎲 Cria random com seed baseada no nível.
  math.Random _createSeededRandom(int levelNumber) {
    return math.Random(levelNumber * 12345);
  }

  /// 🧱 Verifica se deve adicionar obstáculo.
  bool _shouldAddObstacle(
    int levelNumber,
    int row,
    int col,
    math.Random random,
  ) {
    if (levelNumber < 2) return false;
    final obstacleChance = (levelNumber * 0.02).clamp(0.0, 0.15);
    return random.nextDouble() < obstacleChance;
  }

  /// 🧱 ✅ CORREÇÃO: Retorna um inteiro representando o obstáculo da planta baixa.
  int _getRandomObstacleBlueprint(int levelNumber, math.Random random) {
    // Mapeamento: 0=Parede, 2=Jaula, 4=Bomba
    final obstacles = <int>[0];
    if (levelNumber >= 4) obstacles.add(2); // Jaula
    if (levelNumber >= 8) obstacles.add(2); // Aumenta chance de jaula
    if (levelNumber >= 5 && levelNumber % 5 == 0) obstacles.add(4); // Bomba

    return obstacles[random.nextInt(obstacles.length)];
  }

  /// 🎨 Obtém tema do nível
  String _getLevelTheme(int levelNumber) {
    final themes = [
      "da Primavera",
      "do Verão",
      "do Outono",
      "do Inverno",
      "Secreto",
      "Místico",
      "Encantado",
      "Celestial",
      "dos Sonhos",
      "da Harmonia",
      "da Serenidade",
      "da Sabedoria",
    ];
    return themes[(levelNumber - 1) % themes.length];
  }

  /// 📝 Obtém descrição do nível
  String _getLevelDescription(int levelNumber) {
    if (levelNumber <= 10) {
      return "Continue aprendendo as mecânicas básicas do jardim.";
    } else if (levelNumber <= 20) {
      return "Desafios mais complexos aguardam no jardim.";
    } else if (levelNumber <= 30) {
      return "Apenas mestres jardineiros chegam até aqui.";
    } else {
      return "O jardim revela seus segredos mais profundos.";
    }
  }

  /// ⭐ Obtém características especiais
  List<LevelFeature> _getSpecialFeatures(int levelNumber) {
    final features = <LevelFeature>[];

    if (levelNumber >= 2) features.add(LevelFeature.walls);
    if (levelNumber >= 3) features.add(LevelFeature.multiColor);
    if (levelNumber >= 4) features.add(LevelFeature.cages);
    if (levelNumber >= 5) features.add(LevelFeature.bombs);
    if (levelNumber >= 10) features.add(LevelFeature.timeLimit);
    if (levelNumber >= 15) features.add(LevelFeature.cascade);
    if (levelNumber >= 20) features.add(LevelFeature.powerUps);

    return features;
  }

  /// 🔓 Verifica se um nível está desbloqueado
  bool isLevelUnlocked(int levelNumber) {
    final gameState = GameStateManager.instance;
    return gameState.isLevelUnlocked(levelNumber);
  }

  /// 📊 Obtém estatísticas do nível
  LevelStats? getLevelStats(int levelNumber) {
    final gameState = GameStateManager.instance;
    final stats = gameState.getLevelStats(levelNumber);

    if (stats == null) return null;

    return LevelStats(
      attempts: stats['attempts'] ?? 0,
      bestMoves: stats['best_moves'],
      bestTime: stats['best_time'],
      bestScore: stats['best_score'],
      lastPlayed: stats['last_played'],
    );
  }

  /// 🎯 Obtém próximo nível disponível
  int getNextAvailableLevel() {
    final gameState = GameStateManager.instance;
    return gameState.currentLevel;
  }

  /// 🧹 Limpa cache de níveis
  void clearCache() {
    _levelCache.clear();
    if (kDebugMode) {
      print("[LEVEL_MANAGER] 🧹 Cache de níveis limpo");
    }
  }

  /// 📊 Obtém informações de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'cached_levels': _levelCache.keys.toList(),
      'cache_size': _levelCache.length,
      'next_available': getNextAvailableLevel(),
    };
  }
}

/// 📊 Estatísticas de um nível
class LevelStats {
  final int attempts;
  final int? bestMoves;
  final num? bestTime;
  final int? bestScore;
  final int? lastPlayed;

  LevelStats({
    required this.attempts,
    this.bestMoves,
    this.bestTime,
    this.bestScore,
    this.lastPlayed,
  });

  DateTime? get lastPlayedDate {
    if (lastPlayed == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(lastPlayed!);
  }
}

/// 🎯 Dificuldades de nível
enum LevelDifficulty { easy, medium, hard, expert }

/// ⭐ Características especiais dos níveis
enum LevelFeature {
  tutorial,
  walls,
  multiColor,
  cages,
  bombs,
  timeLimit,
  cascade,
  powerUps,
}

/// 🔧 Extensões para facilitar o uso
extension LevelDifficultyExtension on LevelDifficulty {
  String get displayName {
    switch (this) {
      case LevelDifficulty.easy:
        return 'Fácil';
      case LevelDifficulty.medium:
        return 'Médio';
      case LevelDifficulty.hard:
        return 'Difícil';
      case LevelDifficulty.expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case LevelDifficulty.easy:
        return const Color(0xFF4CAF50);
      case LevelDifficulty.medium:
        return const Color(0xFFFF9800);
      case LevelDifficulty.hard:
        return const Color(0xFFE91E63);
      case LevelDifficulty.expert:
        return const Color(0xFF9C27B0);
    }
  }
}

extension LevelFeatureExtension on LevelFeature {
  String get displayName {
    switch (this) {
      case LevelFeature.tutorial:
        return 'Tutorial';
      case LevelFeature.walls:
        return 'Obstáculos';
      case LevelFeature.multiColor:
        return 'Múltiplas Cores';
      case LevelFeature.cages:
        return 'Jaulas';
      case LevelFeature.bombs:
        return 'Bombas';
      case LevelFeature.timeLimit:
        return 'Tempo Limitado';
      case LevelFeature.cascade:
        return 'Cascata';
      case LevelFeature.powerUps:
        return 'Power-ups';
    }
  }

  IconData get icon {
    switch (this) {
      case LevelFeature.tutorial:
        return Icons.school;
      case LevelFeature.walls:
        return Icons.block;
      case LevelFeature.multiColor:
        return Icons.palette;
      case LevelFeature.cages:
        return Icons.lock;
      case LevelFeature.bombs:
        return Icons.local_fire_department;
      case LevelFeature.timeLimit:
        return Icons.timer;
      case LevelFeature.cascade:
        return Icons.waterfall_chart;
      case LevelFeature.powerUps:
        return Icons.flash_on;
    }
  }
}
