// lib/src/utils/animations.dart
import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import '../engine/board.dart';
import '../engine/petal_piece.dart';

class SwapAnimation extends Component {
  final GameBoard board;
  final int row1, col1, row2, col2;
  final void Function()? onComplete;

  SwapAnimation({
    required this.board,
    required this.row1,
    required this.col1,
    required this.row2,
    required this.col2,
    this.onComplete,
  });

  @override
  Future<void> onLoad() async {
    final piece1 = board.pieceAt(row1, col1);
    final piece2 = board.pieceAt(row2, col2);
    final position1 = Vector2(col1 * board.cellSize, row1 * board.cellSize);
    final position2 = Vector2(col2 * board.cellSize, row2 * board.cellSize);
    final futures = <Future>[];
    addEffect(Component component, Effect effect) {
      final futureOr = component.add(effect);
      if (futureOr is Future) futures.add(futureOr);
    }

    addEffect(piece1, MoveToEffect(position2, EffectController(duration: 0.3, curve: Curves.easeInOut)));
    addEffect(piece2, MoveToEffect(position1, EffectController(duration: 0.3, curve: Curves.easeInOut)));
    
    if (futures.isNotEmpty) await Future.wait(futures);
    
    onComplete?.call();
    removeFromParent();
  }
}

class MatchAnimation extends Component {
  final List<PetalPiece> matchedPieces;
  final int cascadeLevel;
  final void Function()? onComplete;

  MatchAnimation({
    required this.matchedPieces,
    this.cascadeLevel = 1,
    this.onComplete,
  });

  @override
  Future<void> onLoad() async {
    final futures = <Future>[];
    final random = Random();

    for (final piece in matchedPieces) {
      final sequence = SequenceEffect([
        ScaleEffect.to(Vector2.all(1.0 + cascadeLevel * 0.1), EffectController(duration: 0.1, curve: Curves.easeOut)),
        //ParallelEffect([
          ScaleEffect.to(Vector2.zero(), EffectController(duration: max(0.1, 0.3 - (cascadeLevel * 0.04)), curve: Curves.easeIn)),
          RotateEffect.by((random.nextDouble() - 0.5) * 0.5, EffectController(duration: 0.2)),
        //]),
      ]);
      final futureOr = piece.add(sequence);
      if (futureOr is Future) futures.add(futureOr);
    }

    if (futures.isNotEmpty) await Future.wait(futures);
    
    for (final piece in matchedPieces) {
      piece.removeFromParent();
    }
    
    onComplete?.call();
    removeFromParent();
  }
}