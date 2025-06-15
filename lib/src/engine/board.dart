// lib/src/engine/board.dart
import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import '../bloc/game_bloc.dart';
import '../engine/matcher.dart';
import '../engine/petal_piece.dart';
import '../engine/spawner.dart';
import '../game/candy_game.dart';

class GameBoard extends PositionComponent with HasGameRef<CandyGame> {
  final Vector2 gridSize;
  final double pieceSize;

  late final GameBloc _gameBloc;
  final List<List<PetalPiece>> _grid;
  final PetalSpawner spawner = PetalSpawner();
  final PetalMatcher matcher = PetalMatcher();
  int multiplier = 1;

  double get cellSize => pieceSize;

  GameBoard({required this.gridSize, required this.pieceSize})
      : _grid = List.generate(
          gridSize.y.toInt(),
          (i) => List.generate(gridSize.x.toInt(), (j) => PetalPiece.empty()),
        );
        
  void setBloc(GameBloc bloc) {
    _gameBloc = bloc;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // O tamanho é definido com base nos parâmetros recebidos.
    size = Vector2(gridSize.x * pieceSize, gridSize.y * pieceSize);
  }

  Future<void> populateBoard() async {
    final random = Random();
    final pieceTypes = PetalType.values.where((t) => t != PetalType.empty && !t.name.startsWith('special')).toList();

    // Loop para garantir que o tabuleiro não comece com matches
    while (true) {
      // Limpa todos os componentes filhos antes de gerar um novo tabuleiro
      removeAll(children);

      for (var row = 0; row < gridSize.y; row++) {
        for (var col = 0; col < gridSize.x; col++) {
          final randomType = pieceTypes[random.nextInt(pieceTypes.length)];
          final piece = PetalPiece(randomType);
          
          piece.size = Vector2.all(pieceSize);
          piece.position = Vector2(col * pieceSize, row * pieceSize);
          _grid[row][col] = piece;
          add(piece);
        }
      }

      // Se não encontrou nenhum match, o tabuleiro é válido e podemos sair do loop
      final initialMatches = matcher.findMatches(_grid);
      if (initialMatches.isEmpty) {
        break;
      }

      print("Debug: Tabuleiro inicial com matches. Gerando novamente...");
    }
  }

  /// Processa os matches, decide se cria peças especiais e retorna todas as posições a serem limpas.
  Set<Offset> processMatches(List<MatchData> matches) {
    Set<Offset> piecesToClear = {};
    for (final match in matches) {
      piecesToClear.addAll(match.positions);

      // Lógica para criar uma peça especial
      if (match.type == MatchType.line4 || match.type == MatchType.line5) {
        final position = match.positions.first;
        piecesToClear.remove(position);
        final row = position.dy.toInt();
        final col = position.dx.toInt();
        
        // Remove a peça antiga antes de adicionar a nova
        _grid[row][col].removeFromParent();

        final specialPetal = PetalPiece(PetalType.special_bomb);
        specialPetal.size = Vector2.all(pieceSize);
        specialPetal.position = Vector2(col * pieceSize, row * pieceSize);
        _grid[row][col] = specialPetal;
        add(specialPetal);
        
        //_gameBloc.add(SpecialPieceCreated(specialPetal));
      }
    }
    return piecesToClear;
  }

  /// Marca as peças que deram match como 'empty' no grid lógico.
  void markMatchesAsEmpty(Set<Offset> matches) {
    for (var offset in matches) {
      _grid[offset.dy.toInt()][offset.dx.toInt()] = PetalPiece.empty();
    }
  }

  /// Aplica a gravidade, movendo peças para baixo e preenchendo o topo.
  Future<void> applyGravityAndRefill() async {
    final futures = <Future>[];
    for (var col = 0; col < gridSize.x; col++) {
      int emptySpaces = 0;
      for (var row = gridSize.y.toInt() - 1; row >= 0; row--) {
        if (_grid[row][col].type == PetalType.empty) {
          emptySpaces++;
        } else if (emptySpaces > 0) {
          final pieceToMove = _grid[row][col];
          final newRow = row + emptySpaces;
          _grid[newRow][col] = pieceToMove;
          _grid[row][col] = PetalPiece.empty();
          final fallEffect = MoveToEffect(
            Vector2(col * pieceSize, newRow * pieceSize),
            EffectController(duration: 0.3, curve: Curves.easeIn),
          );
          final futureOr = pieceToMove.add(fallEffect);
          if (futureOr is Future) futures.add(futureOr);
        }
      }
      for (var i = 0; i < emptySpaces; i++) {
        final newRow = emptySpaces - 1 - i;
        final newPiece = spawner.spawnPetalForSlot(newRow, col, _grid);
        newPiece.size = Vector2.all(pieceSize);
        newPiece.position = Vector2(col * pieceSize, -(i + 1) * pieceSize);
        _grid[newRow][col] = newPiece;
        add(newPiece);
        final fallEffect = MoveToEffect(
          Vector2(col * pieceSize, newRow * pieceSize),
          EffectController(duration: 0.5, curve: Curves.easeIn),
        );
        final futureOr = newPiece.add(fallEffect);
        if (futureOr is Future) futures.add(futureOr);
      }
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  /// Apenas realiza a troca lógica das peças na grade.
  void swapPieces(int row1, int col1, int row2, int col2) {
    final piece1 = _grid[row1][col1];
    final piece2 = _grid[row2][col2];
    _grid[row1][col1] = piece2;
    _grid[row2][col2] = piece1;
  }

  PetalPiece pieceAt(int row, int col) => _grid[row][col];
  bool isValidPosition(int row, int col) => row >= 0 && row < gridSize.y && col >= 0 && col < gridSize.x;
  List<MatchData> findMatches() => matcher.findMatches(_grid);
  void incrementMultiplier() => multiplier++;
  void resetMultiplier() => multiplier = 1;
  List<List<PetalType>> getGridTypes() => _grid.map((row) => row.map((piece) => piece.type).toList()).toList();
}