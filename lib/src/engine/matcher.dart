// lib/src/engine/matcher.dart
import 'package:flutter/material.dart';
import './petal_piece.dart';

// ✅ Enum para identificar o tipo de match encontrado
enum MatchType {
  line3,
  line4,
  line5,
  lShape, // Para futuras implementações
  tShape, // Para futuras implementações
}

// ✅ Nova classe para retornar dados mais ricos sobre cada match
class MatchData {
  final Set<Offset> positions;
  final MatchType type;
  final PetalType petalType;

  MatchData({
    required this.positions,
    required this.type,
    required this.petalType,
  });
}

class PetalMatcher {
  /// Encontra todas as combinações no tabuleiro e retorna dados detalhados sobre elas.
  List<MatchData> findMatches(List<List<PetalPiece>> grid) {
    final List<MatchData> allMatches = [];
    final Set<Offset> alreadyInMatch = {};

    final rows = grid.length;
    if (rows == 0) return [];
    final cols = grid[0].length;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final currentPos = Offset(col.toDouble(), row.toDouble());
        if (alreadyInMatch.contains(currentPos)) {
          continue;
        }

        final currentType = grid[row][col].type;
        if (currentType == PetalType.empty) {
          continue;
        }

        // Procura por combinações horizontais e verticais a partir da peça atual
        final horizontalMatch = _findRun(grid, row, col, 1, 0);
        final verticalMatch = _findRun(grid, row, col, 0, 1);

        if (horizontalMatch.length >= 3) {
          final matchType = _getMatchType(horizontalMatch.length);
          allMatches.add(MatchData(
              positions: horizontalMatch,
              type: matchType,
              petalType: currentType));
          alreadyInMatch.addAll(horizontalMatch);
        }

        if (verticalMatch.length >= 3) {
          final matchType = _getMatchType(verticalMatch.length);
          allMatches.add(MatchData(
              positions: verticalMatch,
              type: matchType,
              petalType: currentType));
          alreadyInMatch.addAll(verticalMatch);
        }
      }
    }

    // TODO: Adicionar lógica para mesclar matches em L e T se necessário
    return allMatches;
  }
  
  /// Helper para encontrar uma sequência de peças iguais em uma direção.
  Set<Offset> _findRun(
      List<List<PetalPiece>> grid, int startRow, int startCol, int stepX, int stepY) {
    final run = <Offset>{};
    final startType = grid[startRow][startCol].type;
    final rows = grid.length;
    final cols = grid[0].length;

    int currentRow = startRow;
    int currentCol = startCol;

    while (currentRow >= 0 && currentRow < rows && currentCol >= 0 && currentCol < cols &&
           grid[currentRow][currentCol].type == startType) {
      // ✅ Correção: Offset(coluna, linha)
      run.add(Offset(currentCol.toDouble(), currentRow.toDouble()));
      currentCol += stepX;
      currentRow += stepY;
    }
    return run;
  }

  /// Converte o tamanho de um match em um MatchType.
  MatchType _getMatchType(int length) {
    switch (length) {
      case 3:
        return MatchType.line3;
      case 4:
        return MatchType.line4;
      case 5:
      default:
        return MatchType.line5;
    }
  }

  /// Verifica se existe qualquer match no tabuleiro.
  bool hasMatches(List<List<PetalPiece>> grid) {
    return findMatches(grid).isNotEmpty;
  }
}