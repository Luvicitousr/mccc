import 'package:flutter/material.dart';
import 'petal_piece.dart';
import '../game/level_manager.dart';

/// 🎯 Definição de Nível - Estrutura Modular (VERSÃO CORRIGIDA)
class LevelDefinition {
  final int levelNumber;
  final int width;
  final int height;
  final int moves;
  final Map<PetalType, int> objectives;

  // ✅ O layout é uma "planta baixa" do nível, usando inteiros e enums.
  final List<dynamic> layout;

  final String title;
  final String description;
  final LevelDifficulty difficulty;
  final List<LevelFeature> specialFeatures;

  // ✅ 1. ADICIONE ESTA NOVA PROPRIEDADE
  // Define os pontos necessários para 1, 2 e 3 estrelas.
  final List<int> starThresholds;
  final Duration? timeLimit;
  final Map<String, dynamic>? customProperties;

  LevelDefinition({
    required this.levelNumber,
    required this.width,
    required this.height,
    required this.moves,
    required this.objectives,
    required this.layout,
    required this.title,
    required this.description,
    required this.difficulty,
    this.specialFeatures = const [],

    // ✅ 2. ADICIONE AO CONSTRUTOR
    required this.starThresholds,
    this.timeLimit,
    this.customProperties,
  }) {
    _validateDefinition();
  }

  /// 🔍 Valida a estrutura básica da definição.
  void _validateDefinition() {
    if (layout.length != width * height) {
      throw ArgumentError(
        'Layout size (${layout.length}) does not match width * height ($width * $height)',
      );
    }
    if (objectives.isEmpty) {
      throw ArgumentError('Level must have at least one objective');
    }

    // ✅ Validação para starThresholds
    if (starThresholds.length != 3) {
      throw ArgumentError(
        'starThresholds must contain exactly 3 integer values.',
      );
    }
  }

  /// Verifica se uma posição é válida no tabuleiro.
  bool isValidPosition(int row, int col) {
    return row >= 0 && row < height && col >= 0 && col < width;
  }

  /// Verifica se o nível tem uma característica específica.
  bool hasFeature(LevelFeature feature) {
    return specialFeatures.contains(feature);
  }

  /// ✅ CORREÇÃO: `copyWith` atualizado para aceitar List<dynamic>.
  LevelDefinition copyWith({
    int? levelNumber,
    int? width,
    int? height,
    int? moves,
    Map<PetalType, int>? objectives,
    List<dynamic>? layout, // <-- Corrigido
    String? title,
    String? description,
    LevelDifficulty? difficulty,
    List<LevelFeature>? specialFeatures,
    List<int>? starThresholds, // Adicionado
    Duration? timeLimit,
    Map<String, dynamic>? customProperties,
  }) {
    return LevelDefinition(
      levelNumber: levelNumber ?? this.levelNumber,
      width: width ?? this.width,
      height: height ?? this.height,
      moves: moves ?? this.moves,
      objectives: objectives ?? this.objectives,
      layout: layout ?? this.layout,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      specialFeatures: specialFeatures ?? this.specialFeatures,
      starThresholds: starThresholds ?? this.starThresholds, // Adicionado
      timeLimit: timeLimit ?? this.timeLimit,
      customProperties: customProperties ?? this.customProperties,
    );
  }

  /// ✅ CORREÇÃO: `toMap` para serializar corretamente a lista mista.
  Map<String, dynamic> toMap() {
    return {
      'levelNumber': levelNumber,
      'width': width,
      'height': height,
      'moves': moves,
      'objectives': objectives.map((key, value) => MapEntry(key.name, value)),
      'layout': layout.map((item) {
        if (item is PetalType) return item.name;
        return item; // Salva o inteiro como está.
      }).toList(),
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'specialFeatures': specialFeatures
          .map((feature) => feature.name)
          .toList(),
      'starThresholds': starThresholds, // Adicionado
      'timeLimit': timeLimit?.inMilliseconds,
      'customProperties': customProperties,
    };
  }

  /// ✅ CORREÇÃO: `fromMap` para deserializar corretamente a lista mista.
  factory LevelDefinition.fromMap(Map<String, dynamic> map) {
    return LevelDefinition(
      levelNumber: map['levelNumber'],
      width: map['width'],
      height: map['height'],
      moves: map['moves'],
      objectives: (map['objectives'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          PetalType.values.firstWhere((type) => type.name == key),
          value as int,
        ),
      ),
      layout: (map['layout'] as List<dynamic>).map((item) {
        if (item is int) return item;
        if (item is String) {
          try {
            return PetalType.values.firstWhere((type) => type.name == item);
          } catch (_) {
            return item;
          }
        }
        return item;
      }).toList(),
      title: map['title'],
      description: map['description'],
      difficulty: LevelDifficulty.values.firstWhere(
        (diff) => diff.name == map['difficulty'],
      ),
      specialFeatures:
          (map['specialFeatures'] as List<dynamic>?)
              ?.map(
                (featureName) => LevelFeature.values.firstWhere(
                  (feature) => feature.name == featureName,
                ),
              )
              .toList() ??
          [],

      // Adicionado com um valor padrão para evitar erros em dados antigos
      starThresholds: List<int>.from(
        map['starThresholds'] ?? [1000, 2000, 3000],
      ),
      timeLimit: map['timeLimit'] != null
          ? Duration(milliseconds: map['timeLimit'])
          : null,
      customProperties: map['customProperties'],
    );
  }

  // Os métodos de igualdade e hash (==, hashCode) não precisam de alteração,
  // pois o Dart consegue comparar a List<dynamic> corretamente.
  @override
  String toString() {
    return 'LevelDefinition(#$levelNumber: $title, ${width}x$height, $moves moves, ${objectives.length} objectives)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelDefinition &&
        other.levelNumber == levelNumber &&
        other.width == width &&
        other.height == height &&
        other.moves == moves &&
        _mapEquals(other.objectives, objectives) &&
        _listEquals(other.layout, layout) &&
        other.title == title &&
        other.description == description &&
        other.difficulty == difficulty &&
        _listEquals(other.specialFeatures, specialFeatures) &&
        other.timeLimit == timeLimit;
  }

  @override
  int get hashCode {
    return Object.hash(
      levelNumber,
      width,
      height,
      moves,
      objectives,
      Object.hashAll(layout), // Usar hashAll para listas é mais seguro
      title,
      description,
      difficulty,
      Object.hashAll(specialFeatures),
      timeLimit,
    );
  }

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 🎯 Builder para criar níveis de forma fluente (VERSÃO CORRIGIDA)
class LevelDefinitionBuilder {
  int? _levelNumber;
  int? _width;
  int? _height;
  int? _moves;
  Map<PetalType, int>? _objectives;

  // ✅ CORREÇÃO: Builder agora usa List<dynamic>
  List<dynamic>? _layout;

  String? _title;
  String? _description;
  LevelDifficulty? _difficulty;
  List<LevelFeature> _specialFeatures = [];
  Duration? _timeLimit;
  Map<String, dynamic>? _customProperties;

  // ✅ ADICIONE A PROPRIEDADE PARA STAR THRESHOLDS
  List<int>? _starThresholds;

  LevelDefinitionBuilder setLevelNumber(int levelNumber) {
    _levelNumber = levelNumber;
    return this;
  }

  LevelDefinitionBuilder setDimensions(int width, int height) {
    _width = width;
    _height = height;
    return this;
  }

  LevelDefinitionBuilder setMoves(int moves) {
    _moves = moves;
    return this;
  }

  LevelDefinitionBuilder setObjectives(Map<PetalType, int> objectives) {
    _objectives = objectives;
    return this;
  }

  LevelDefinitionBuilder addObjective(PetalType type, int count) {
    _objectives ??= {};
    _objectives![type] = count;
    return this;
  }

  // ✅ CORREÇÃO: `setLayout` atualizado para aceitar List<dynamic>.
  LevelDefinitionBuilder setLayout(List<dynamic> layout) {
    _layout = layout;
    return this;
  }

  LevelDefinitionBuilder setTitle(String title) {
    _title = title;
    return this;
  }

  LevelDefinitionBuilder setDescription(String description) {
    _description = description;
    return this;
  }

  LevelDefinitionBuilder setDifficulty(LevelDifficulty difficulty) {
    _difficulty = difficulty;
    return this;
  }

  LevelDefinitionBuilder addFeature(LevelFeature feature) {
    _specialFeatures.add(feature);
    return this;
  }

  LevelDefinitionBuilder setTimeLimit(Duration timeLimit) {
    _timeLimit = timeLimit;
    return this;
  }

  LevelDefinitionBuilder setCustomProperty(String key, dynamic value) {
    _customProperties ??= {};
    _customProperties![key] = value;
    return this;
  }

  // ✅ ADICIONE UM NOVO MÉTODO SETTER PARA STAR THRESHOLDS
  LevelDefinitionBuilder setStarThresholds(List<int> thresholds) {
    _starThresholds = thresholds;
    return this;
  }

  LevelDefinition build() {
    if (_levelNumber == null) throw ArgumentError('Level number is required');
    if (_width == null || _height == null)
      throw ArgumentError('Dimensions are required');
    if (_moves == null) throw ArgumentError('Moves count is required');
    if (_objectives == null) throw ArgumentError('Objectives are required');
    if (_layout == null) throw ArgumentError('Layout is required');
    if (_title == null) throw ArgumentError('Title is required');
    if (_description == null) throw ArgumentError('Description is required');
    if (_difficulty == null) throw ArgumentError('Difficulty is required');

    // ✅ ADICIONE A VERIFICAÇÃO PARA STAR THRESHOLDS
    if (_starThresholds == null)
      throw ArgumentError('Star thresholds are required');

    return LevelDefinition(
      levelNumber: _levelNumber!,
      width: _width!,
      height: _height!,
      moves: _moves!,
      objectives: _objectives!,
      layout: _layout!,
      title: _title!,
      description: _description!,
      difficulty: _difficulty!,
      specialFeatures: _specialFeatures,

      // ✅ PASSE O VALOR PARA O CONSTRUTOR
      starThresholds: _starThresholds!,
      timeLimit: _timeLimit,
      customProperties: _customProperties,
    );
  }
}

// As extensões não precisam de mudança, pois não acessam os métodos problemáticos do layout.
extension LevelDefinitionExtensions on LevelDefinition {
  bool get isTutorial => hasFeature(LevelFeature.tutorial);
  bool get isTimeLimited => timeLimit != null;
  Color get difficultyColor => difficulty.color;
  IconData get difficultyIcon {
    switch (difficulty) {
      case LevelDifficulty.easy:
        return Icons.sentiment_satisfied;
      case LevelDifficulty.medium:
        return Icons.sentiment_neutral;
      case LevelDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case LevelDifficulty.expert:
        return Icons.warning;
    }
  }
}
