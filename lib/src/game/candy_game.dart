// lib/src/game/candy_game.dart

import 'dart:async';
import 'dart:math';
import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../actions/swap_pieces_action.dart';
import '../actions/remove_pieces_action.dart';
import '../actions/callback_action.dart';
import '../engine/action_manager.dart';
import '../engine/petal_piece.dart';
import 'package:flutter/foundation.dart';
import '../engine/level_definition.dart';

class CandyGame extends FlameGame with DragCallbacks {
  late final List<Aabb2> pieceSlots;
  late List<PetalPiece> pieces;
  int _lastProcessedIndex = -1;
  late final ActionManager actionManager;

  @override
  void update(double dt) {
    super.update(dt);
    actionManager.performStuff();

    // Lógica de Fim de Jogo (Derrota)
    if (movesLeft.value == 0 && !actionManager.isRunning() && !_isGameOver) {
      _isGameOver = true;
      pauseEngine();
      overlays.add('gameOverPanel');
    }

    // Lógica de Fim de Jogo (Vitória)
    final allObjectivesMet = objectives.value.values.every(
      (count) => count <= 0,
    );
    if (allObjectivesMet && !_isGameWon && !_isGameOver) {
      _isGameWon = true;
      pauseEngine();
      overlays.add('gameWonPanel');
    }
  }

  late final ValueNotifier<int> movesLeft;
  bool _isGameOver = false;
  late final ValueNotifier<Map<PetalType, int>> objectives;
  bool _isGameWon = false;
  final LevelDefinition level;

  CandyGame({required this.level});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    objectives = ValueNotifier(Map<PetalType, int>.from(level.objectives));
    movesLeft = ValueNotifier(level.moves);

    overlays.add('movesPanel');
    overlays.add('objectivesPanel');

    final background = await Sprite.load('Background.jpg');
    add(
      SpriteComponent(
        sprite: background,
        size: size,
        position: Vector2.zero(),
        priority: -1,
      ),
    );
    actionManager = ActionManager();

    final pieceSize = size.x / level.width;
    final boardWidth = level.width * pieceSize;
    final boardHeight = level.height * pieceSize;
    final offsetX = (size.x - boardWidth) / 2;
    final offsetY = (size.y - boardHeight) / 2;

    assert(offsetX >= 0 && offsetY >= 0, "Offset negativo: $offsetX, $offsetY");

    pieceSlots = List.generate(level.width * level.height, (index) {
      final i = index % level.width;
      final j = (index / level.width).floor();
      final x = i * pieceSize + offsetX;
      final y = j * pieceSize + offsetY;
      return Aabb2.minMax(Vector2(x, y), Vector2(x + pieceSize, y + pieceSize));
    });

    final List<PetalPiece> generatedPieces = [];
    for (int j = 0; j < level.height; j++) {
      for (int i = 0; i < level.width; i++) {
        final index = j * level.width + i;
        final position = Vector2(
          i * pieceSize + offsetX,
          j * pieceSize + offsetY,
        );

        PetalType pieceType;
        if (level.layout[index] == 0) {
          pieceType = PetalType.wall;
        } else {
          bool isMatch;
          do {
            isMatch = false;
            pieceType = _randomPieceType();
            if (i >= 2) {
              if (level.layout[index - 1] == 1 &&
                  level.layout[index - 2] == 1) {
                final piece1 = generatedPieces[j * level.width + (i - 1)];
                final piece2 = generatedPieces[j * level.width + (i - 2)];
                if (piece1.type == pieceType && piece2.type == pieceType) {
                  isMatch = true;
                }
              }
            }
            if (j >= 2) {
              if (level.layout[index - level.width] == 1 &&
                  level.layout[index - (level.width * 2)] == 1) {
                final piece1 = generatedPieces[(j - 1) * level.width + i];
                final piece2 = generatedPieces[(j - 2) * level.width + i];
                if (piece1.type == pieceType && piece2.type == pieceType) {
                  isMatch = true;
                }
              }
            }
          } while (isMatch);
        }

        generatedPieces.add(
          PetalPiece(
            type: pieceType,
            position: position,
            size: Vector2.all(pieceSize),
          ),
        );
      }
    }

    pieces = generatedPieces;
    await addAll(pieces);
  }

  PetalPiece? pieceAt(int i, int j) {
    if (i < 0 || i >= level.width || j < 0 || j >= level.height) {
      return null;
    }
    final index = j * level.width + i;
    return pieces[index];
  }

  Set<PetalPiece> _findAndResolveComplexMatches(int startX, int startY) {
    final Set<PetalPiece> initialSeed = _findLinesAt(startX, startY);
    if (initialSeed.isEmpty) {
      return {};
    }

    final Set<PetalPiece> finalMatchPieces = Set.from(initialSeed);
    final Queue<PetalPiece> piecesToProcess = Queue.from(initialSeed);

    while (piecesToProcess.isNotEmpty) {
      final currentPiece = piecesToProcess.removeFirst();
      final index = pieces.indexOf(currentPiece);
      final i = index % level.width;
      final j = (index / level.width).floor();
      final Set<PetalPiece> foundLines = _findLinesAt(i, j);

      for (final newPiece in foundLines) {
        if (finalMatchPieces.add(newPiece)) {
          piecesToProcess.add(newPiece);
        }
      }
    }

    return finalMatchPieces;
  }

  Set<PetalPiece> _findLinesAt(int i, int j) {
    final PetalPiece? startPiece = pieceAt(i, j);
    if (startPiece == null ||
        startPiece.type == PetalType.wall ||
        startPiece.type == PetalType.empty) {
      return {};
    }
    final currentType = startPiece.type;
    final Set<PetalPiece> foundPieces = {};

    List<PetalPiece> horizontalLine = [startPiece];
    for (int x = i - 1; x >= 0; x--) {
      final p = pieceAt(x, j);
      if (p?.type == currentType) {
        horizontalLine.add(p!);
      } else {
        break;
      }
    }
    for (int x = i + 1; x < level.width; x++) {
      final p = pieceAt(x, j);
      if (p?.type == currentType) {
        horizontalLine.add(p!);
      } else {
        break;
      }
    }

    List<PetalPiece> verticalLine = [startPiece];
    for (int y = j - 1; y >= 0; y--) {
      final p = pieceAt(i, y);
      if (p?.type == currentType) {
        verticalLine.add(p!);
      } else {
        break;
      }
    }
    for (int y = j + 1; y < level.height; y++) {
      final p = pieceAt(i, y);
      if (p?.type == currentType) {
        verticalLine.add(p!);
      } else {
        break;
      }
    }

    if (horizontalLine.length >= 3) {
      foundPieces.addAll(horizontalLine);
    }
    if (verticalLine.length >= 3) {
      foundPieces.addAll(verticalLine);
    }

    return foundPieces;
  }

  Set<PetalPiece> _findAdjacentWalls(Set<PetalPiece> pieceSet) {
    final wallsToClear = <PetalPiece>{};

    for (final piece in pieceSet) {
      final index = pieces.indexOf(piece);
      final i = index % level.width;
      final j = (index / level.width).floor();

      final neighborsCoords = [
        Point(i, j - 1),
        Point(i, j + 1),
        Point(i - 1, j),
        Point(i + 1, j),
      ];

      for (final coord in neighborsCoords) {
        final neighborPiece = pieceAt(coord.x.toInt(), coord.y.toInt());
        if (neighborPiece != null && neighborPiece.type == PetalType.wall) {
          wallsToClear.add(neighborPiece);
        }
      }
    }

    return wallsToClear;
  }

  void _processMatches(Set<PetalPiece> matchedPieces) {
    if (matchedPieces.isEmpty) {
      return;
    }

    final wallsToClear = _findAdjacentWalls(matchedPieces);
    final allPiecesToAnimate = {...matchedPieces, ...wallsToClear};

    actionManager
        .push(RemovePiecesAction(piecesToRemove: allPiecesToAnimate))
        .push(
          FunctionAction(() {
            final currentObjectives = Map<PetalType, int>.from(
              objectives.value,
            );
            bool objectivesUpdated = false;

            for (final piece in matchedPieces) {
              if (currentObjectives.containsKey(piece.type)) {
                currentObjectives[piece.type] =
                    (currentObjectives[piece.type]! - 1).clamp(0, 999);
                objectivesUpdated = true;
              }
              piece.changeType(PetalType.empty);
            }

            for (final wall in wallsToClear) {
              wall.changeType(PetalType.empty);
            }

            if (objectivesUpdated) {
              objectives.value = currentObjectives;
            }

            _cascadeAndRefill();
          }),
        );
  }

  void _cascadeAndRefill() {
    final pieceSize = size.x / level.width;
    final moves = <PetalPiece, Vector2>{};
    var newPiecesState = List<PetalPiece>.from(pieces);

    bool piecesMoved;
    do {
      piecesMoved = false;
      // Gravidade Vertical e Diagonal
      for (int j = level.height - 2; j >= 0; j--) {
        for (int i = 0; i < level.width; i++) {
          final currentPiece = newPiecesState[j * level.width + i];
          if (currentPiece.type == PetalType.empty ||
              currentPiece.type == PetalType.wall) {
            continue;
          }

          // Checa diretamente abaixo
          final belowIndex = (j + 1) * level.width + i;
          if (newPiecesState[belowIndex].type == PetalType.empty) {
            final temp = newPiecesState[belowIndex];
            newPiecesState[belowIndex] = currentPiece;
            newPiecesState[j * level.width + i] = temp;
            piecesMoved = true;
            continue;
          }

          // Checa diagonal esquerda-baixo
          if (i > 0) {
            final diagLeftIndex = (j + 1) * level.width + (i - 1);
            if (newPiecesState[diagLeftIndex].type == PetalType.empty) {
              final temp = newPiecesState[diagLeftIndex];
              newPiecesState[diagLeftIndex] = currentPiece;
              newPiecesState[j * level.width + i] = temp;
              piecesMoved = true;
              continue;
            }
          }

          // Checa diagonal direita-baixo
          if (i < level.width - 1) {
            final diagRightIndex = (j + 1) * level.width + (i + 1);
            if (newPiecesState[diagRightIndex].type == PetalType.empty) {
              final temp = newPiecesState[diagRightIndex];
              newPiecesState[diagRightIndex] = currentPiece;
              newPiecesState[j * level.width + i] = temp;
              piecesMoved = true;
            }
          }
        }
      }
    } while (piecesMoved);

    // Preenchimento do Topo
    final addedPieces = <PetalPiece>[];
    for (int i = 0; i < level.width; i++) {
      int emptySpaces = 0;
      // Conta espaços vazios de cima para baixo na coluna
      for (int j = 0; j < level.height; j++) {
        if (newPiecesState[j * level.width + i].type == PetalType.empty) {
          emptySpaces++;
          final oldPiece = newPiecesState[j * level.width + i];
          oldPiece.removeFromParent();

          final newPosition = pieceSlots[i].min;
          final newPiece = PetalPiece(
            type: _randomPieceType(),
            position: Vector2(newPosition.x, -pieceSize * emptySpaces),
            size: Vector2.all(pieceSize),
          );
          add(newPiece);
          newPiecesState[j * level.width + i] = newPiece;
          addedPieces.add(newPiece);
        } else {
          break;
        }
      }
    }

    // Calcula os destinos finais para a animação
    for (int i = 0; i < newPiecesState.length; i++) {
      moves[newPiecesState[i]] = pieceSlots[i].min;
    }

    pieces = newPiecesState;

    actionManager.push(
      SwapPiecesAction(pieceDestinations: moves, durationMs: 400),
    );
    actionManager.push(
      FunctionAction(() {
        final newMatches = _findAllMatchesOnBoard();
        if (newMatches.isNotEmpty) {
          _processMatches(newMatches);
        }
      }),
    );
  }

  Set<PetalPiece> _findAllMatchesOnBoard() {
    final allMatches = <PetalPiece>{};
    for (int j = 0; j < level.height; j++) {
      for (int i = 0; i < level.width; i++) {
        allMatches.addAll(_findLinesAt(i, j));
      }
    }
    return allMatches;
  }

  void _play(int fromIndex, int toIndex) {
    if (actionManager.isRunning()) {
      return;
    }
    final fromPiece = pieces[fromIndex];
    final toPiece = pieces[toIndex];

    if (fromPiece.type == PetalType.wall || toPiece.type == PetalType.wall) {
      return;
    }

    final temp = pieces[fromIndex];
    pieces[fromIndex] = pieces[toIndex];
    pieces[toIndex] = temp;

    final fromI = fromIndex % level.width;
    final fromJ = (fromIndex / level.width).floor();
    final toI = toIndex % level.width;
    final toJ = (toIndex / level.width).floor();

    final Set<PetalPiece> allFoundPieces = {};
    allFoundPieces.addAll(_findAndResolveComplexMatches(toI, toJ));
    allFoundPieces.addAll(_findAndResolveComplexMatches(fromI, fromJ));

    final fromPosition = pieceSlots[fromIndex].min.clone();
    final toPosition = pieceSlots[toIndex].min.clone();

    if (allFoundPieces.isNotEmpty) {
      movesLeft.value--;
      actionManager
          .push(
            SwapPiecesAction(
              pieceDestinations: {fromPiece: toPosition, toPiece: fromPosition},
            ),
          )
          .push(
            FunctionAction(() {
              _processMatches(allFoundPieces);
            }),
          );
    } else {
      final temp = pieces[fromIndex];
      pieces[fromIndex] = pieces[toIndex];
      pieces[toIndex] = temp;

      actionManager
          .push(
            SwapPiecesAction(
              pieceDestinations: {fromPiece: toPosition, toPiece: fromPosition},
              durationMs: 150,
            ),
          )
          .push(
            SwapPiecesAction(
              pieceDestinations: {fromPiece: fromPosition, toPiece: toPosition},
              durationMs: 150,
            ),
          );
    }
  }

  int _getIndexFromPosition(Vector2 position) {
    final pieceSize = size.x / level.width;
    final offsetX = (size.x - level.width * pieceSize) / 2;
    final offsetY = (size.y - level.height * pieceSize) / 2;

    final adjustedX = position.x - offsetX;
    final adjustedY = position.y - offsetY;

    final i = (adjustedX / pieceSize).floor();
    final j = (adjustedY / pieceSize).floor();

    if (i >= 0 && i < level.width && j >= 0 && j < level.height) {
      return j * level.width + i;
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
      int from = _lastProcessedIndex;
      int to = currentIndex;
      int fromX = from % level.width;
      int fromY = (from / level.width).floor();
      int toX = to % level.width;
      int toY = (to / level.width).floor();

      if ((fromX == toX && (fromY - toY).abs() == 1) ||
          (fromY == toY && (fromX - toX).abs() == 1)) {
        _play(from, to);
        _lastProcessedIndex = -1;
      } else {
        _lastProcessedIndex = currentIndex;
      }
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
  final List<PetalType> playableTypes = List.from(PetalType.values)
    ..remove(PetalType.empty)
    ..remove(PetalType.wall);
  return playableTypes[Random().nextInt(playableTypes.length)];
}
