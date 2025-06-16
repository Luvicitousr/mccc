import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
//import '../actions/swap_pieces_action.dart';
import '../engine/action_manager.dart';
import '../engine/petal_piece.dart';

const int kPieceCountWidth = 8;
const int kPieceCountHeight = 8;

class CandyGame extends FlameGame with DragCallbacks {
  late final List<Aabb2> pieceSlots;
  late final List<PetalPiece> pieces;
  int _lastProcessedIndex = -1;
  late final ActionManager actionManager;

  @override
  void update(double dt) {
    super.update(dt);
    actionManager.performStuff();
  }

  @override
  Color backgroundColor() => const Color.fromARGB(255, 255, 0, 0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    actionManager = ActionManager();

    // ✅ 1. Calcula o tamanho de cada peça
    final pieceSize = size.x / kPieceCountWidth;

    // ✅ 2. Calcula o tamanho total do tabuleiro
    final boardWidth = kPieceCountWidth * pieceSize;
    final boardHeight = kPieceCountHeight * pieceSize;

    // ✅ 3. Calcula o deslocamento para centralizar
    final offsetX = (size.x - boardWidth) / 2;
    final offsetY = (size.y - boardHeight) / 2;

    // ✅ 4. Gera slots com offset de centralização
    pieceSlots = List.generate(
      kPieceCountWidth * kPieceCountHeight,
      (index) {
        final i = index % kPieceCountWidth;
        final j = (index / kPieceCountWidth).floor();
        final x = i * pieceSize + offsetX;
        final y = j * pieceSize + offsetY;
        return Aabb2.minMax(Vector2(x, y), Vector2(x + pieceSize, y + pieceSize));
      },
    );

    // ✅ 5. Cria peças centralizadas
    pieces = List.generate(
      kPieceCountWidth * kPieceCountHeight,
      (index) {
        final i = index % kPieceCountWidth;
        final j = (index / kPieceCountWidth).floor();
        final position = Vector2(i * pieceSize + offsetX, j * pieceSize + offsetY);
        return PetalPiece(
          type: _randomPieceType(),
          position: position,
          size: Vector2.all(pieceSize),
        );
      },
    );

    await addAll(pieces);
  }

  void _play(Vector2 position) {
    if (!size.toRect().contains(position.toOffset())) return;
    final index = _getIndexFromPosition(position);
    if (index != -1) {
      //actionManager.push(ActionLog("Ação de jogar IMEDIATA no índice: $index"));
      print("Ação de jogar IMEDIATA no índice: $index");
    }
  }

  int _getIndexFromPosition(Vector2 position) {
    final pieceSize = size.x / kPieceCountWidth;
    final offsetX = (size.x - kPieceCountWidth * pieceSize) / 2;
    final offsetY = (size.y - kPieceCountHeight * pieceSize) / 2;

    // ✅ 6. Ajusta posição para compensar o offset de centralização
    final adjustedX = position.x - offsetX;
    final adjustedY = position.y - offsetY;

    final i = (adjustedX / pieceSize).floor();
    final j = (adjustedY / pieceSize).floor();

    if (i >= 0 && i < kPieceCountWidth && j >= 0 && j < kPieceCountHeight) {
      return j * kPieceCountWidth + i;
    }
    return -1;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (actionManager.isRunning()) return;
    final index = _getIndexFromPosition(event.localPosition);
    if (index != -1) _lastProcessedIndex = index;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (actionManager.isRunning()) return;
    final currentIndex = _getIndexFromPosition(event.localEndPosition);
    if (currentIndex != -1 && currentIndex != _lastProcessedIndex) {
      _play(event.localEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _lastProcessedIndex = -1;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _lastProcessedIndex = -1;
  }
}

PetalType _randomPieceType() {
    final nonSpecialTypes =
        PetalType.values; // Adicione filtro se tiver peças especiais
    return nonSpecialTypes[Random().nextInt(nonSpecialTypes.length)];
  }