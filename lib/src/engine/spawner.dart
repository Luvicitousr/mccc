// lib/src/engine/spawner.dart
import 'dart:math';
import 'petal_piece.dart';

class PetalSpawner {
  final Random _random = Random();
  
  final List<PetalType> _spawnableTypes = PetalType.values
      .where((type) =>
          type != PetalType.empty &&
          !type.name.startsWith('special'))
      .toList();

  /// Cria e retorna uma nova PetalPiece com um tipo aleatório,
  /// garantindo que ela não crie uma combinação imediata na sua posição.
  PetalPiece spawnPetalForSlot(int row, int col, List<List<PetalPiece>> grid) {
    PetalType randomType;
    int attempts = 0;

    // Tenta até 10 vezes encontrar uma peça que não forme match.
    // Isso evita um loop infinito caso seja impossível não formar um match.
    do {
      randomType = _spawnableTypes[_random.nextInt(_spawnableTypes.length)];
      attempts++;
    } while (
      _createsMatch(row, col, randomType, grid) && attempts < 10
    );
    
    return PetalPiece(randomType);
  }

  /// Verifica se um tipo de peça em uma dada posição criaria um match.
  bool _createsMatch(int row, int col, PetalType type, List<List<PetalPiece>> grid) {
    // Checagem horizontal
    // Verifica as duas peças à esquerda: [X, X, T] (T é a peça nova)
    if (col >= 2 &&
        grid[row][col - 1].type == type &&
        grid[row][col - 2].type == type) {
      return true;
    }

    // Checagem vertical
    // Verifica as duas peças acima: [X]
    //                               [X]
    //                               [T] (T é a peça nova)
    if (row >= 2 &&
        grid[row - 1][col].type == type &&
        grid[row - 2][col].type == type) {
      return true;
    }

    // Nenhuma combinação foi criada
    return false;
  }
}