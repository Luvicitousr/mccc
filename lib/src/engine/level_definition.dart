// lib/src/engine/level_definition.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'petal_piece.dart'; // Precisamos do PetalType

class LevelDefinition {
  final int levelNumber;
  final int moves;
  final Map<PetalType, int> objectives;
  final int width;
  final int height;
  final List<int> layout;

  LevelDefinition({
    required this.levelNumber,
    required this.moves,
    required this.objectives,
    required this.width,
    required this.height,
    required this.layout,
  });

  // Factory constructor para criar uma instância a partir de um mapa JSON.
  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    final board = json['board'] as Map<String, dynamic>;
    final objectivesJson = json['objectives'] as Map<String, dynamic>;

    // ✅ PASSO 1: Extrai o layout primeiro para que possamos analisá-lo.
    final layout = List<int>.from(board['layout']);

    // ✅ PASSO 2: Conta quantas peças do tipo '2' (enjaulada) existem no layout.
    final int cagedTileCount = layout.where((tile) => tile == 2).length;

    // Converte o mapa de objetivos de String para PetalType.
    final objectives = objectivesJson.map((key, value) {
      // Encontra o PetalType correspondente ao nome da chave (ex: "CHERRY" -> PetalType.cherry)
      final petalType = PetalType.values.firstWhere(
        (e) => e.name.toUpperCase() == key.toUpperCase(),
      );
      return MapEntry(petalType, value as int);
    });

    // ✅ PASSO 3: Se houver peças enjauladas no tabuleiro, adiciona como um objetivo.
    if (cagedTileCount > 0) {
      // Usamos 'caged1' como a chave para representar o objetivo.
      objectives[PetalType.caged1] = cagedTileCount;
    }

    return LevelDefinition(
      levelNumber: json['level_number'] as int,
      moves: json['moves'] as int,
      objectives: objectives,
      width: board['width'] as int,
      height: board['height'] as int,
      layout: List<int>.from(board['layout']),
    );
  }

  // Método estático para carregar um nível a partir de um arquivo de asset.
  static Future<LevelDefinition> load(String levelFile) async {
    final jsonString = await rootBundle.loadString('assets/levels/$levelFile');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return LevelDefinition.fromJson(jsonMap);
  }
}
