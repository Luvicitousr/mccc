// lib/src/game/candy_game.dart
import '../actions/shuffle_animation_action.dart'; // <-- IMPORTE A NOVA AÇÃO
import '../actions/animate_falls_action.dart';
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

// Estrutura para representar um movimento de queda
class FallMovement {
  final PetalPiece piece;
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final String pathType; // 'vertical', 'diagonal-left', 'diagonal-right'
  final int pathLength;
  final List<Point<int>> pathSteps;

  FallMovement({
    required this.piece,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.pathType,
    required this.pathLength,
    required this.pathSteps,
  });
}

// Estrutura para representar um caminho diagonal
class DiagonalPath {
  final bool isValid;
  final int finalRow;
  final int finalCol;
  final int pathLength;
  final String direction; // 'left' ou 'right'
  final List<Point<int>> steps;

  DiagonalPath({
    required this.isValid,
    required this.finalRow,
    required this.finalCol,
    required this.pathLength,
    required this.direction,
    required this.steps,
  });

  static DiagonalPath invalid() {
    return DiagonalPath(
      isValid: false,
      finalRow: -1,
      finalCol: -1,
      pathLength: 0,
      direction: '',
      steps: [],
    );
  }
}

// =========================================================================
// ENUM PARA RESULTADOS DE VALIDAÇÃO DE MOVIMENTO
// =========================================================================
enum MoveValidationResult {
  valid,
  invalidEmptyTarget,
  invalidWallTarget,
  invalidWallSource,
  invalidSamePosition,
  invalidNotAdjacent,
  invalidOutOfBounds,
}

// =========================================================================
// CLASSE PARA DETALHES DE VALIDAÇÃO
// =========================================================================
class MoveValidationDetails {
  final MoveValidationResult result;
  final String message;
  final bool isAllowed;

  const MoveValidationDetails({
    required this.result,
    required this.message,
    required this.isAllowed,
  });

  static const MoveValidationDetails valid = MoveValidationDetails(
    result: MoveValidationResult.valid,
    message: "Movimento válido",
    isAllowed: true,
  );

  static const MoveValidationDetails invalidEmptyTarget = MoveValidationDetails(
    result: MoveValidationResult.invalidEmptyTarget,
    message: "Não é possível mover para um espaço vazio",
    isAllowed: false,
  );

  static const MoveValidationDetails invalidWallTarget = MoveValidationDetails(
    result: MoveValidationResult.invalidWallTarget,
    message: "Não é possível mover para uma parede",
    isAllowed: false,
  );

  static const MoveValidationDetails invalidWallSource = MoveValidationDetails(
    result: MoveValidationResult.invalidWallSource,
    message: "Não é possível mover uma parede",
    isAllowed: false,
  );

  static const MoveValidationDetails invalidSamePosition =
      MoveValidationDetails(
        result: MoveValidationResult.invalidSamePosition,
        message: "Posições de origem e destino são iguais",
        isAllowed: false,
      );

  static const MoveValidationDetails invalidNotAdjacent = MoveValidationDetails(
    result: MoveValidationResult.invalidNotAdjacent,
    message: "Posições não são adjacentes",
    isAllowed: false,
  );

  static const MoveValidationDetails invalidOutOfBounds = MoveValidationDetails(
    result: MoveValidationResult.invalidOutOfBounds,
    message: "Posição fora dos limites do tabuleiro",
    isAllowed: false,
  );
}

class CandyGame extends FlameGame with DragCallbacks {
  // ✅ MODIFICAÇÃO: Variável para armazenar os sprites pré-carregados.
  late final Map<PetalType, Sprite> spriteMap;
  late final List<Aabb2> pieceSlots;
  late List<PetalPiece> pieces;
  int _lastProcessedIndex = -1;
  late final ActionManager actionManager;
  late final ValueNotifier<int> movesLeft;
  bool _isGameOver = false;
  late final ValueNotifier<Map<PetalType, int>> objectives;
  bool _isGameWon = false;
  final LevelDefinition level;

  CandyGame({required this.level});

  // ✅ NOVO MÉTODO: Carrega todos os sprites necessários uma única vez.
  Future<void> _loadSprites() async {
    spriteMap = {};
    for (var type in PetalType.values) {
      if (type != PetalType.empty) {
        // O try-catch garante que, se uma imagem estiver faltando, o jogo não quebre.
        // Em vez disso, ele pode usar um sprite de erro se você tiver um.
        try {
          spriteMap[type] = await Sprite.load('tiles/${type.name}_petal.png');
        } catch (e) {
          if (kDebugMode) {
            print("Erro ao carregar sprite para $type: $e");
          }
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    actionManager.globals['dt'] = dt;
    actionManager.performStuff();
    if (movesLeft.value == 0 && !actionManager.isRunning() && !_isGameOver) {
      _isGameOver = true;
      pauseEngine();
      overlays.add('gameOverPanel');
    }
    final allObjectivesMet = objectives.value.values.every(
      (count) => count <= 0,
    );
    if (allObjectivesMet && !_isGameWon && !_isGameOver) {
      _isGameWon = true;
      pauseEngine();
      overlays.add('gameWonPanel');
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ MODIFICAÇÃO: Chama o novo método de pré-carregamento.
    await _loadSprites();

    objectives = ValueNotifier(Map<PetalType, int>.from(level.objectives));
    movesLeft = ValueNotifier(level.moves);
    overlays.add('movesPanel');
    overlays.add('objectivesPanel');
    final background = await Sprite.load('Background.jpg');
    add(SpriteComponent(sprite: background, size: size, priority: -1));
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
        PetalType pieceType = PetalType.empty;

        // ✅ CORREÇÃO DE SINTAXE: O 'else' foi colocado na linha correta.
        if (level.layout[index] == 0) {
          pieceType = PetalType.wall;
        } else if (level.layout[index] == 2) {
          pieceType = PetalType.caged1;
        } else {
          // Este 'else' agora corretamente lida com layout == 1
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

        // ✅ MODIFICAÇÃO: Passa o mapa de sprites para cada peça criada.
        generatedPieces.add(
          PetalPiece(
            type: pieceType,
            spriteMap: spriteMap,
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
    if (index >= 0 && index < pieces.length) {
      return pieces[index];
    }
    return null;
  }

  // =========================================================================
  // 🚫 SISTEMA DE VALIDAÇÃO DE MOVIMENTO - PROIBIR ESPAÇOS VAZIOS
  // =========================================================================

  /// Valida se um movimento é permitido de acordo com as regras do jogo
  /// REGRA PRINCIPAL: Não é permitido mover peças para espaços vazios
  MoveValidationDetails validateMove(int fromIndex, int toIndex) {
    // Validação 1: Verificar limites dos índices
    if (fromIndex < 0 ||
        fromIndex >= pieces.length ||
        toIndex < 0 ||
        toIndex >= pieces.length) {
      if (kDebugMode) {
        print(
          "[VALIDATION] ❌ Movimento inválido: índices fora dos limites ($fromIndex -> $toIndex)",
        );
      }
      return MoveValidationDetails.invalidOutOfBounds;
    }

    // Validação 2: Verificar se as posições são diferentes
    if (fromIndex == toIndex) {
      if (kDebugMode) {
        print("[VALIDATION] ❌ Movimento inválido: mesma posição ($fromIndex)");
      }
      return MoveValidationDetails.invalidSamePosition;
    }

    // Converter índices para coordenadas
    final fromCol = fromIndex % level.width;
    final fromRow = (fromIndex / level.width).floor();
    final toCol = toIndex % level.width;
    final toRow = (toIndex / level.width).floor();

    // Validação 3: Verificar se as posições são adjacentes
    final isAdjacent =
        (fromCol == toCol && (fromRow - toRow).abs() == 1) ||
        (fromRow == toRow && (fromCol - toCol).abs() == 1);

    if (!isAdjacent) {
      if (kDebugMode) {
        print(
          "[VALIDATION] ❌ Movimento inválido: posições não adjacentes ($fromCol,$fromRow) -> ($toCol,$toRow)",
        );
      }
      return MoveValidationDetails.invalidNotAdjacent;
    }

    final fromPiece = pieces[fromIndex];
    final toPiece = pieces[toIndex];

    // Validação 4: Verificar se a peça de origem não é uma parede
    if (fromPiece.type == PetalType.wall) {
      if (kDebugMode) {
        print(
          "[VALIDATION] ❌ Movimento inválido: tentativa de mover parede em ($fromCol,$fromRow)",
        );
      }
      return MoveValidationDetails.invalidWallSource;
    }

    // Validação 5: REGRA PRINCIPAL - Verificar se o destino não é um espaço vazio
    if (toPiece.type == PetalType.empty) {
      if (kDebugMode) {
        print(
          "[VALIDATION] ❌ Movimento BLOQUEADO: tentativa de mover para espaço vazio em ($toCol,$toRow)",
        );
        print(
          "[VALIDATION]    Origem: ${fromPiece.type} em ($fromCol,$fromRow)",
        );
        print("[VALIDATION]    Destino: VAZIO em ($toCol,$toRow)");
      }
      return MoveValidationDetails.invalidEmptyTarget;
    }

    // Validação 6: Verificar se o destino não é uma parede
    if (toPiece.type == PetalType.wall) {
      if (kDebugMode) {
        print(
          "[VALIDATION] ❌ Movimento inválido: tentativa de mover para parede em ($toCol,$toRow)",
        );
      }
      return MoveValidationDetails.invalidWallTarget;
    }

    // Se chegou até aqui, o movimento é válido
    if (kDebugMode) {
      print(
        "[VALIDATION] ✅ Movimento VÁLIDO: ${fromPiece.type} ($fromCol,$fromRow) ↔ ${toPiece.type} ($toCol,$toRow)",
      );
    }
    return MoveValidationDetails.valid;
  }

  /// Valida movimento usando coordenadas diretamente
  MoveValidationDetails validateMoveByCoordinates(
    int fromCol,
    int fromRow,
    int toCol,
    int toRow,
  ) {
    final fromIndex = fromRow * level.width + fromCol;
    final toIndex = toRow * level.width + toCol;
    return validateMove(fromIndex, toIndex);
  }

  /// Verifica se existe pelo menos um movimento válido no tabuleiro
  bool hasValidMovesAvailable() {
    int validMoveCount = 0;

    for (int row = 0; row < level.height; row++) {
      for (int col = 0; col < level.width; col++) {
        final currentIndex = row * level.width + col;
        final currentPiece = pieces[currentIndex];

        // Pula se for parede ou espaço vazio
        if (currentPiece.type == PetalType.wall ||
            currentPiece.type == PetalType.empty) {
          continue;
        }

        // Verifica movimentos adjacentes
        final adjacentPositions = [
          [col, row - 1], // Cima
          [col, row + 1], // Baixo
          [col - 1, row], // Esquerda
          [col + 1, row], // Direita
        ];

        for (final pos in adjacentPositions) {
          final adjCol = pos[0];
          final adjRow = pos[1];

          // Verifica limites
          if (adjCol < 0 ||
              adjCol >= level.width ||
              adjRow < 0 ||
              adjRow >= level.height) {
            continue;
          }

          final adjIndex = adjRow * level.width + adjCol;
          final validation = validateMove(currentIndex, adjIndex);

          if (validation.isAllowed) {
            // Verifica se o movimento resultaria em match
            if (_checkPotentialMatch(col, row, adjCol, adjRow)) {
              validMoveCount++;
              if (kDebugMode) {
                print(
                  "[VALIDATION] ✅ Movimento válido encontrado: ($col,$row) -> ($adjCol,$adjRow)",
                );
              }
              return true; // Encontrou pelo menos um movimento válido
            }
          }
        }
      }
    }

    if (kDebugMode) {
      print("[VALIDATION] ❌ Nenhum movimento válido encontrado no tabuleiro");
    }
    return false;
  }

  /// Mostra feedback visual para movimento inválido
  void _showInvalidMovefeedback(MoveValidationDetails validation) {
    if (kDebugMode) {
      print("[FEEDBACK] 🚫 ${validation.message}");
    }

    // Aqui você pode adicionar efeitos visuais como:
    // - Shake animation na peça
    // - Highlight vermelho
    // - Som de erro
    // - Partículas de "bloqueado"

    // Exemplo de implementação futura:
    // _showErrorParticles();
    // _playErrorSound();
    // _shakeInvalidPiece(fromIndex);
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
        startPiece.type == PetalType.empty ||
        startPiece.type == PetalType.caged1 || // Não pode iniciar match
        startPiece.type == PetalType.caged2) {
      // Não pode iniciar match
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

  /// Encontra peças enjauladas adjacentes a uma combinação, aplica dano a elas
  /// e retorna um conjunto das peças que foram completamente destruídas.
  Set<PetalPiece> _findAndDamageAdjacentCagedPetals(
    Set<PetalPiece> matchedPieces,
  ) {
    final Set<PetalPiece> piecesToDestroy = {};
    final Set<PetalPiece> alreadyDamaged =
        {}; // Evita dano duplo na mesma rodada

    for (final piece in matchedPieces) {
      final index = pieces.indexOf(piece);
      final i = index % level.width;
      final j = (index / level.width).floor();

      final neighborsCoords = [
        Point(i, j - 1), // Top
        Point(i, j + 1), // Bottom
        Point(i - 1, j), // Left
        Point(i + 1, j), // Right
      ];

      for (final coord in neighborsCoords) {
        final neighborPiece = pieceAt(coord.x.toInt(), coord.y.toInt());

        if (neighborPiece != null && !alreadyDamaged.contains(neighborPiece)) {
          if (neighborPiece.type == PetalType.caged1) {
            // Dano nível 1: transforma em jaula quebrada
            neighborPiece.changeType(PetalType.caged2);
            alreadyDamaged.add(neighborPiece);
          } else if (neighborPiece.type == PetalType.caged2) {
            // Dano nível 2: destrói a peça
            // A peça será removida em _processMatches
            piecesToDestroy.add(neighborPiece);
            alreadyDamaged.add(neighborPiece);
          }
        }
      }
    }
    return piecesToDestroy;
  }

  void _processMatches(Set<PetalPiece> matchedPieces) {
    if (matchedPieces.isEmpty) {
      return;
    }
    final wallsToClear = _findAdjacentWalls(matchedPieces);
    final cagedPetalsToDestroy = _findAndDamageAdjacentCagedPetals(
      matchedPieces,
    );
    final allPiecesToAnimate = {
      ...matchedPieces,
      ...wallsToClear,
      ...cagedPetalsToDestroy,
    };

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

            // Loop para objetivos de peças enjauladas destruídas
            for (final cagedPetal in cagedPetalsToDestroy) {
              // Usamos 'caged1' como o tipo chave para representar o objetivo de "destruir jaulas"
              if (currentObjectives.containsKey(PetalType.caged1)) {
                currentObjectives[PetalType.caged1] =
                    (currentObjectives[PetalType.caged1]! - 1).clamp(0, 999);
                objectivesUpdated = true;
              }
              cagedPetal.changeType(PetalType.empty);
            }

            for (final wall in wallsToClear) {
              wall.changeType(PetalType.empty);
            }

            // ✅ CORREÇÃO LÓGICA: Peças enjauladas destruídas devem se tornar vazias.
            for (final cagedPetal in cagedPetalsToDestroy) {
              cagedPetal.changeType(PetalType.empty);
            }

            if (objectivesUpdated) {
              objectives.value = currentObjectives;
            }
            _startSequentialCascade();
          }),
        );
  }

  // =========================================================================
  // ALGORITMO DE CASCATA SEQUENCIAL - 4 FASES EXATAS
  // 1. Quedas Verticais → 2. Preenchimento → 3. Queda Diagonal → 4. Repetir
  // =========================================================================

  void _startSequentialCascade() {
    if (kDebugMode) {
      print("[DEBUG] ========================================");
      print("[DEBUG] INICIANDO CASCATA SEQUENCIAL (4 FASES)");
      print("[DEBUG] ========================================");
    }

    // Inicia na Fase 1: Quedas Verticais
    _phase1_VerticalFalls();
  }

  // =========================================================================
  // FASE 1: QUEDAS VERTICAIS
  // Execute todas as quedas verticais possíveis até não haver mais
  // =========================================================================
  void _phase1_VerticalFalls() {
    if (kDebugMode) {
      print("[DEBUG] FASE 1: Executando quedas verticais...");
    }

    int verticalIterations = 0;
    const maxVerticalIterations = 20;

    void performVerticalIteration() {
      verticalIterations++;

      if (kDebugMode) {
        print("[DEBUG] FASE 1: Iteração vertical #$verticalIterations");
      }

      if (verticalIterations > maxVerticalIterations) {
        if (kDebugMode) {
          print("[DEBUG] FASE 1: Máximo de iterações verticais atingido");
        }
        _phase2_FillTopSpaces();
        return;
      }

      // Encontra TODAS as quedas verticais possíveis
      final verticalMovements = _findAllVerticalFalls();

      if (verticalMovements.isNotEmpty) {
        if (kDebugMode) {
          print(
            "[DEBUG] FASE 1: Encontradas ${verticalMovements.length} quedas verticais",
          );
        }

        // Executa TODOS os movimentos verticais
        for (final movement in verticalMovements) {
          _executeMovement(movement);
        }

        // Anima e continua iteração vertical
        _animateMovements(verticalMovements, performVerticalIteration);
      } else {
        if (kDebugMode) {
          print(
            "[DEBUG] FASE 1: Nenhuma queda vertical encontrada. Indo para Fase 2.",
          );
        }
        _phase2_FillTopSpaces();
      }
    }

    performVerticalIteration();
  }

  // =========================================================================
  // FASE 2: PREENCHIMENTO DO TOPO
  // Preencha todos os espaços vazios no topo do tabuleiro
  // =========================================================================
  void _phase2_FillTopSpaces() {
    if (kDebugMode) {
      print("[DEBUG] FASE 2: Preenchendo espaços vazios no topo...");
    }

    final refillMovements = _createTopRefillMovements();

    if (refillMovements.isNotEmpty) {
      if (kDebugMode) {
        print(
          "[DEBUG] FASE 2: Preenchendo ${refillMovements.length} espaços vazios",
        );
      }

      // Anima preenchimento e vai para Fase 3 - usando TopFillAction para suavidade
      _animateTopFillMovements(refillMovements, _phase3_SingleDiagonalFall);
    } else {
      if (kDebugMode) {
        print("[DEBUG] FASE 2: Nenhum espaço vazio no topo. Indo para Fase 3.");
      }
      _phase3_SingleDiagonalFall();
    }
  }

  // =========================================================================
  // FASE 3: QUEDA DIAGONAL ÚNICA
  // Execute APENAS a queda diagonal mais próxima da base
  // =========================================================================
  void _phase3_SingleDiagonalFall() {
    if (kDebugMode) {
      print(
        "[DEBUG] FASE 3: Verificando queda diagonal mais próxima da base...",
      );
    }

    // Encontra APENAS a queda diagonal mais próxima da base
    final closestDiagonalMovement = _findClosestDiagonalFall();

    if (closestDiagonalMovement != null) {
      if (kDebugMode) {
        print("[DEBUG] FASE 3: Encontrada queda diagonal:");
        print(
          "[DEBUG]   - Peça: (${closestDiagonalMovement.fromRow}, ${closestDiagonalMovement.fromCol})",
        );
        print(
          "[DEBUG]   - Destino: (${closestDiagonalMovement.toRow}, ${closestDiagonalMovement.toCol})",
        );
        print("[DEBUG]   - Tipo: ${closestDiagonalMovement.pathType}");
      }

      // Executa APENAS esta queda diagonal
      _executeMovement(closestDiagonalMovement);

      // Anima e vai para Fase 4 (retorno à Fase 1)
      _animateMovements([closestDiagonalMovement], _phase4_RepeatCycle);
    } else {
      if (kDebugMode) {
        print(
          "[DEBUG] FASE 3: Nenhuma queda diagonal encontrada. Tabuleiro estabilizado.",
        );
      }
      _finalizeCascade();
    }
  }

  // =========================================================================
  // FASE 4: REPETIR CICLO
  // Retorne à Fase 1 e repita até estabilização completa
  // =========================================================================
  void _phase4_RepeatCycle() {
    if (kDebugMode) {
      print("[DEBUG] FASE 4: Retornando à Fase 1 para repetir ciclo...");
    }

    // Retorna à Fase 1 para repetir o ciclo
    _phase1_VerticalFalls();
  }

  // =========================================================================
  // MÉTODOS AUXILIARES PARA AS FASES
  // =========================================================================

  // Encontra TODAS as quedas verticais possíveis no tabuleiro
  List<FallMovement> _findAllVerticalFalls() {
    final movements = <FallMovement>[];

    // Varre TODAS as colunas da esquerda para direita
    for (int col = 0; col < level.width; col++) {
      int writeIndex = level.height - 1;

      // Varre de baixo para cima, compactando peças
      for (int row = level.height - 1; row >= 0; row--) {
        final piece = pieceAt(col, row);

        if (piece != null &&
            piece.type != PetalType.empty &&
            piece.type != PetalType.wall) {
          if (row != writeIndex) {
            // Peça precisa cair verticalmente
            movements.add(
              FallMovement(
                piece: piece,
                fromRow: row,
                fromCol: col,
                toRow: writeIndex,
                toCol: col,
                pathType: 'vertical',
                pathLength: writeIndex - row,
                pathSteps: _generateVerticalPath(row, col, writeIndex, col),
              ),
            );
          }
          writeIndex--;
        } else if (piece?.type == PetalType.wall) {
          // Parede redefine o writeIndex
          writeIndex = row - 1;
        }
      }
    }

    return movements;
  }

  // Encontra APENAS a queda diagonal mais próxima da base do tabuleiro
  FallMovement? _findClosestDiagonalFall() {
    FallMovement? closestMovement;
    int closestRow = -1;
    int closestCol = level.width; // Para priorizar esquerda

    // Varre de baixo para cima, da esquerda para direita
    for (int row = level.height - 2; row >= 0; row--) {
      for (int col = 0; col < level.width; col++) {
        final piece = pieceAt(col, row);

        if (piece != null &&
            piece.type != PetalType.empty &&
            piece.type != PetalType.wall) {
          final movement = _calculateOptimalDiagonalMovement(row, col, piece);

          if (movement != null) {
            // Verifica se esta é a queda mais próxima da base
            // Prioriza: 1) Linha mais baixa, 2) Coluna mais à esquerda
            if (row > closestRow || (row == closestRow && col < closestCol)) {
              closestMovement = movement;
              closestRow = row;
              closestCol = col;
            }
          }
        }
      }
    }

    return closestMovement;
  }

  // =========================================================================
  // 🔧 ENHANCED DIAGONAL MOVEMENT LOGIC WITH WALL COLLISION RULES
  // =========================================================================

  /// Verifica se uma peça pode cair diagonalmente considerando as regras de colisão com paredes
  /// REGRAS IMPLEMENTADAS:
  /// 1. Diagonal direita: bloqueada se há parede à direita E parede abaixo
  /// 2. Diagonal esquerda: bloqueada se há parede à esquerda E parede abaixo
  bool _canPieceFallDiagonally(int col, int row) {
    // Verifica se pode cair diagonalmente para a esquerda
    final canFallLeft = _canFallDiagonallyInDirection(col, row, 'left');

    // Verifica se pode cair diagonalmente para a direita
    final canFallRight = _canFallDiagonallyInDirection(col, row, 'right');

    return canFallLeft || canFallRight;
  }

  /// Verifica se uma peça pode cair diagonalmente em uma direção específica
  /// aplicando as regras rigorosas de colisão com paredes
  bool _canFallDiagonallyInDirection(int col, int row, String direction) {
    // Primeiro verifica se há um caminho diagonal válido básico
    final diagonalPath = _findDiagonalPath(row, col, direction);
    if (!diagonalPath.isValid) {
      return false;
    }

    // Aplica as regras específicas de colisão com paredes
    if (direction == 'left') {
      // REGRA: Não pode cair diagonalmente para a esquerda se há parede à esquerda E parede abaixo
      return !_hasWallCollisionLeft(col, row);
    } else {
      // REGRA: Não pode cair diagonalmente para a direita se há parede à direita E parede abaixo
      return !_hasWallCollisionRight(col, row);
    }
  }

  /// Verifica se há colisão de parede que impede queda diagonal para a esquerda
  /// REGRA: Bloqueia movimento se há parede à esquerda AND parede abaixo
  bool _hasWallCollisionLeft(int col, int row) {
    // Verifica se há parede diretamente à esquerda
    final leftPiece = pieceAt(col - 1, row);
    final hasWallLeft = leftPiece?.type == PetalType.wall;

    // Verifica se há parede diretamente abaixo
    final belowPiece = pieceAt(col, row + 1);
    final hasWallBelow = belowPiece?.type == PetalType.wall;

    // Bloqueia movimento APENAS se AMBAS as condições são verdadeiras
    final isBlocked = hasWallLeft && hasWallBelow;

    if (kDebugMode && isBlocked) {
      print("[DIAGONAL] 🚫 Queda diagonal esquerda BLOQUEADA em ($col, $row):");
      print("[DIAGONAL]    - Parede à esquerda: $hasWallLeft");
      print("[DIAGONAL]    - Parede abaixo: $hasWallBelow");
      print("[DIAGONAL]    - Movimento bloqueado: $isBlocked");
    }

    return isBlocked;
  }

  /// Verifica se há colisão de parede que impede queda diagonal para a direita
  /// REGRA: Bloqueia movimento se há parede à direita AND parede abaixo
  bool _hasWallCollisionRight(int col, int row) {
    // Verifica se há parede diretamente à direita
    final rightPiece = pieceAt(col + 1, row);
    final hasWallRight = rightPiece?.type == PetalType.wall;

    // Verifica se há parede diretamente abaixo
    final belowPiece = pieceAt(col, row + 1);
    final hasWallBelow = belowPiece?.type == PetalType.wall;

    // Bloqueia movimento APENAS se AMBAS as condições são verdadeiras
    final isBlocked = hasWallRight && hasWallBelow;

    if (kDebugMode && isBlocked) {
      print("[DIAGONAL] 🚫 Queda diagonal direita BLOQUEADA em ($col, $row):");
      print("[DIAGONAL]    - Parede à direita: $hasWallRight");
      print("[DIAGONAL]    - Parede abaixo: $hasWallBelow");
      print("[DIAGONAL]    - Movimento bloqueado: $isBlocked");
    }

    return isBlocked;
  }

  /// Valida movimento diagonal com regras de colisão rigorosas
  /// Retorna true se o movimento é permitido, false se bloqueado por paredes
  bool validateDiagonalMovement(int col, int row, String direction) {
    // Verificação de limites
    if (col < 0 || col >= level.width || row < 0 || row >= level.height) {
      if (kDebugMode) {
        print("[DIAGONAL] ❌ Posição fora dos limites: ($col, $row)");
      }
      return false;
    }

    // Verifica se a peça existe e pode se mover
    final piece = pieceAt(col, row);
    if (piece == null ||
        piece.type == PetalType.empty ||
        piece.type == PetalType.wall) {
      if (kDebugMode) {
        print(
          "[DIAGONAL] ❌ Peça não pode se mover: ${piece?.type} em ($col, $row)",
        );
      }
      return false;
    }

    // Aplica as regras específicas de colisão
    final canMove = _canFallDiagonallyInDirection(col, row, direction);

    if (kDebugMode) {
      if (canMove) {
        print(
          "[DIAGONAL] ✅ Movimento diagonal $direction PERMITIDO em ($col, $row)",
        );
      } else {
        print(
          "[DIAGONAL] 🚫 Movimento diagonal $direction BLOQUEADO em ($col, $row)",
        );
      }
    }

    return canMove;
  }

  // Calcula o movimento diagonal ótimo para uma peça específica
  FallMovement? _calculateOptimalDiagonalMovement(
    int row,
    int col,
    PetalPiece piece,
  ) {
    // Verifica caminhos diagonais com as novas regras de colisão
    final leftPath = validateDiagonalMovement(col, row, 'left')
        ? _findDiagonalPath(row, col, 'left')
        : DiagonalPath.invalid();

    final rightPath = validateDiagonalMovement(col, row, 'right')
        ? _findDiagonalPath(row, col, 'right')
        : DiagonalPath.invalid();

    // Prioriza esquerda sobre direita em caso de empate
    if (leftPath.isValid && rightPath.isValid) {
      // Se ambos são válidos, escolhe o de menor comprimento
      // Em caso de empate, prioriza esquerda
      final chosenPath = leftPath.pathLength <= rightPath.pathLength
          ? leftPath
          : rightPath;

      if (kDebugMode) {
        print(
          "[DIAGONAL] ✅ Caminho escolhido: ${chosenPath.direction} (length: ${chosenPath.pathLength})",
        );
      }

      return _createMovementFromPath(piece, row, col, chosenPath);
    } else if (leftPath.isValid) {
      if (kDebugMode) {
        print(
          "[DIAGONAL] ✅ Usando caminho esquerdo (length: ${leftPath.pathLength})",
        );
      }
      return _createMovementFromPath(piece, row, col, leftPath);
    } else if (rightPath.isValid) {
      if (kDebugMode) {
        print(
          "[DIAGONAL] ✅ Usando caminho direito (length: ${rightPath.pathLength})",
        );
      }
      return _createMovementFromPath(piece, row, col, rightPath);
    }

    if (kDebugMode) {
      print(
        "[DIAGONAL] ❌ Nenhum caminho diagonal válido para peça em ($col, $row)",
      );
    }
    return null;
  }

  // Cria movimentos para preencher espaços vazios no topo
  List<FallMovement> _createTopRefillMovements() {
    final movements = <FallMovement>[];
    final pieceSize = size.x / level.width;
    final offsetX = (size.x - level.width * pieceSize) / 2;
    final offsetY = (size.y - level.height * pieceSize) / 2;
    for (int col = 0; col < level.width; col++) {
      int emptyCount = 0;
      for (int row = 0; row < level.height; row++) {
        final piece = pieceAt(col, row);
        if (piece?.type == PetalType.empty) {
          emptyCount++;
        } else {
          break;
        }
      }
      for (int k = 0; k < emptyCount; k++) {
        final index = k * level.width + col;
        final position = Vector2(
          col * pieceSize + offsetX,
          k * pieceSize + offsetY,
        );
        final startPosition = Vector2(position.x, -pieceSize * (k + 1));

        // ✅ MODIFICAÇÃO: Passa o mapa de sprites para a nova peça criada.
        final newPiece = PetalPiece(
          type: _randomPieceType(),
          spriteMap: spriteMap,
          position: startPosition,
          size: Vector2.all(pieceSize),
        );

        pieces[index] = newPiece;
        add(
          newPiece,
        ); // A adição aqui agora é segura por causa do pré-carregamento.

        movements.add(
          FallMovement(
            piece: newPiece,
            fromRow: -k - 1,
            fromCol: col,
            toRow: k,
            toCol: col,
            pathType: 'vertical',
            pathLength: k + 1,
            pathSteps: _generateVerticalPath(-k - 1, col, k, col),
          ),
        );
      }
    }
    return movements;
  }

  /// Verifica se existe pelo menos uma jogada possível no tabuleiro.
  bool _hasPossibleMoves() {
    // Usa o novo sistema de validação
    return hasValidMovesAvailable();
  }

  /// Simula uma troca e verifica se resulta em um match, sem alterar o tabuleiro.
  bool _checkPotentialMatch(int i1, int j1, int i2, int j2) {
    final piece1 = pieceAt(i1, j1);
    final piece2 = pieceAt(i2, j2);

    if (piece1 == null || piece2 == null || piece2.type == PetalType.wall) {
      return false;
    }

    final originalType1 = piece1.type;
    final originalType2 = piece2.type;

    // Simula a troca
    piece1.type = originalType2;
    piece2.type = originalType1;

    // Verifica se a troca cria um match em qualquer uma das duas posições
    final bool isMatch =
        _findLinesAt(i1, j1).isNotEmpty || _findLinesAt(i2, j2).isNotEmpty;

    // IMPORTANTE: Desfaz a simulação para restaurar o estado original
    piece1.type = originalType1;
    piece2.type = originalType2;

    return isMatch;
  }

  /// 🔧 CORREÇÃO CRÍTICA: Método de embaralhamento com proteção contra múltiplas execuções
  void _triggerShuffle() {
    // Verifica se já há uma ação de embaralhamento em execução
    if (actionManager.isRunning()) {
      if (kDebugMode) {
        print(
          "[DEBUG] ⚠️ Embaralhamento ignorado: ActionManager já está executando",
        );
      }
      return;
    }

    if (kDebugMode) {
      print("[DEBUG] 🎲 Sem jogadas! Acionando a ShuffleAnimationAction.");
    }

    try {
      // Cria nova instância da ação de embaralhamento
      final shuffleAction = ShuffleAnimationAction(game: this);
      actionManager.push(shuffleAction);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("[DEBUG] ❌ Erro ao criar ShuffleAnimationAction: $e");
        print("[DEBUG] Stack trace: $stackTrace");
      }
    }
  }

  // Finaliza a cascata e verifica por novos matches
  void _finalizeCascade() {
    if (kDebugMode) {
      print("[DEBUG] ========================================");
      print("[DEBUG] CASCATA SEQUENCIAL FINALIZADA");
      print("[DEBUG] TABULEIRO COMPLETAMENTE ESTABILIZADO");
      print("[DEBUG] ========================================");
    }

    final newMatches = _findAllMatchesOnBoard();
    if (newMatches.isNotEmpty) {
      if (kDebugMode) {
        print(
          "[DEBUG] Novos matches encontrados após estabilização. Processando...",
        );
      }
      _processMatches(newMatches);
    } else {
      // Se não há novos matches, verifique se o jogador tem jogadas possíveis.
      if (!_hasPossibleMoves()) {
        // Se não houver jogadas, acione a ação de embaralhar.
        _triggerShuffle();
      } else {
        // Se há jogadas, o jogo está pronto para o input do usuário.
        if (kDebugMode) {
          print("[DEBUG] Nenhum novo match encontrado. Jogo estável.");
        }
      }
    }
  }

  // =========================================================================
  // MÉTODOS AUXILIARES EXISTENTES (mantidos do código original)
  // =========================================================================

  // Encontra caminho diagonal em uma direção específica
  DiagonalPath _findDiagonalPath(int startRow, int startCol, String direction) {
    final board = _createBoardCopy();
    return _findDiagonalPathOnBoard(board, startRow, startCol, direction);
  }

  // Cria uma cópia do estado atual do tabuleiro
  List<List<PetalType>> _createBoardCopy() {
    return List<List<PetalType>>.generate(
      level.height,
      (row) => List<PetalType>.generate(
        level.width,
        (col) => pieceAt(col, row)?.type ?? PetalType.empty,
      ),
    );
  }

  // =========================================================================
  // 🔧 CORREÇÃO CRÍTICA: Verificação de limites no caminho diagonal
  // =========================================================================
  DiagonalPath _findDiagonalPathOnBoard(
    List<List<PetalType>> board,
    int startRow,
    int startCol,
    String direction,
  ) {
    // Validação de entrada para prevenir erros
    if (startRow < 0 ||
        startRow >= level.height ||
        startCol < 0 ||
        startCol >= level.width) {
      if (kDebugMode) {
        print("[DEBUG] ERRO: Posição inicial inválida ($startCol, $startRow)");
      }
      return DiagonalPath.invalid();
    }

    final colDirection = direction == 'left' ? -1 : 1;
    DiagonalPath bestPath = DiagonalPath.invalid();

    // Calcula o máximo de passos diagonais possíveis para evitar overflow
    final maxDiagonalSteps = direction == 'left'
        ? startCol // Para esquerda, limitado pela posição atual
        : (level.width -
              1 -
              startCol); // Para direita, limitado pelo fim do tabuleiro

    if (kDebugMode) {
      print(
        "[DEBUG] Calculando diagonal $direction de ($startCol, $startRow), max steps: $maxDiagonalSteps",
      );
    }

    // Tenta diferentes distâncias diagonais com verificação de limites
    for (
      int diagonalSteps = 1;
      diagonalSteps <= maxDiagonalSteps;
      diagonalSteps++
    ) {
      final targetCol = startCol + (colDirection * diagonalSteps);
      final targetRow = startRow + diagonalSteps;

      // CORREÇÃO CRÍTICA: Verificação rigorosa de limites
      if (targetCol < 0 ||
          targetCol >= level.width ||
          targetRow < 0 ||
          targetRow >= level.height) {
        if (kDebugMode) {
          print(
            "[DEBUG] Limite atingido em targetCol=$targetCol, targetRow=$targetRow",
          );
        }
        break;
      }

      // Verifica se o caminho diagonal está livre
      if (!_isDiagonalPathClear(
        board,
        startRow,
        startCol,
        targetRow,
        targetCol,
      )) {
        if (kDebugMode) {
          print(
            "[DEBUG] Caminho diagonal bloqueado em ($targetCol, $targetRow)",
          );
        }
        break;
      }

      // Encontra quão longe pode cair verticalmente desta posição diagonal
      final verticalTarget = _findVerticalFallTarget(
        board,
        targetRow,
        targetCol,
      );

      if (verticalTarget > startRow) {
        final totalPathLength = diagonalSteps + (verticalTarget - targetRow);
        bestPath = DiagonalPath(
          isValid: true,
          finalRow: verticalTarget,
          finalCol: targetCol,
          pathLength: totalPathLength,
          direction: direction,
          steps: _generateDiagonalPath(
            startRow,
            startCol,
            verticalTarget,
            targetCol,
          ),
        );

        if (kDebugMode) {
          print(
            "[DEBUG] Caminho diagonal válido encontrado: ($startCol,$startRow) -> ($targetCol,$verticalTarget), length=$totalPathLength",
          );
        }
      }
    }

    return bestPath;
  }

  // Encontra o alvo de queda vertical com verificação de limites
  int _findVerticalFallTarget(List<List<PetalType>> board, int row, int col) {
    // Verificação de limites de entrada
    if (row < 0 || row >= level.height || col < 0 || col >= level.width) {
      return row; // Retorna a posição atual se inválida
    }

    int targetRow = row;

    for (int r = row + 1; r < level.height; r++) {
      if (board[r][col] == PetalType.empty) {
        targetRow = r;
      } else {
        break;
      }
    }

    return targetRow;
  }

  // Verifica se o caminho diagonal está livre de obstáculos
  bool _isDiagonalPathClear(
    List<List<PetalType>> board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    final rowDiff = toRow - fromRow;
    final colDiff = toCol - fromCol;

    if ((rowDiff).abs() != (colDiff).abs()) return false;

    final rowStep = rowDiff > 0 ? 1 : -1;
    final colStep = colDiff > 0 ? 1 : -1;

    int currentRow = fromRow + rowStep;
    int currentCol = fromCol + colStep;

    while (currentRow != toRow || currentCol != toCol) {
      // Verificação rigorosa de limites
      if (currentRow < 0 ||
          currentRow >= level.height ||
          currentCol < 0 ||
          currentCol >= level.width) {
        return false;
      }

      if (board[currentRow][currentCol] != PetalType.empty) {
        return false;
      }

      currentRow += rowStep;
      currentCol += colStep;
    }

    // Verifica posição final com limites
    if (toRow < 0 ||
        toRow >= level.height ||
        toCol < 0 ||
        toCol >= level.width) {
      return false;
    }

    return board[toRow][toCol] == PetalType.empty;
  }

  // Cria movimento a partir de um caminho
  FallMovement _createMovementFromPath(
    PetalPiece piece,
    int fromRow,
    int fromCol,
    DiagonalPath path,
  ) {
    return FallMovement(
      piece: piece,
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: path.finalRow,
      toCol: path.finalCol,
      pathType: path.direction == 'left' ? 'diagonal-left' : 'diagonal-right',
      pathLength: path.pathLength,
      pathSteps: path.steps,
    );
  }

  // Executa um movimento no tabuleiro
  void _executeMovement(FallMovement movement) {
    final fromIndex = movement.fromRow * level.width + movement.fromCol;
    final toIndex = movement.toRow * level.width + movement.toCol;
    if (fromIndex < 0 ||
        fromIndex >= pieces.length ||
        toIndex < 0 ||
        toIndex >= pieces.length) {
      if (kDebugMode) {
        print(
          "[DEBUG] ERRO: Índices inválidos em _executeMovement: fromIndex=$fromIndex, toIndex=$toIndex",
        );
      }
      return;
    }

    // ✅ MODIFICAÇÃO: Passa o mapa de sprites ao criar a peça vazia.
    pieces[fromIndex] = PetalPiece(
      type: PetalType.empty,
      spriteMap: spriteMap,
      position: pieces[fromIndex].position,
      size: pieces[fromIndex].size,
    );

    pieces[toIndex] = movement.piece;
  }

  // =========================================================================
  // ANIMAÇÃO OTIMIZADA - 25% MAIS RÁPIDA
  // =========================================================================

  // Anima movimentos e executa callback com velocidade otimizada
  void _animateMovements(
    List<FallMovement> movements,
    VoidCallback onComplete,
  ) {
    if (movements.isEmpty) {
      onComplete();
      return;
    }

    final pieceDestinations = <PetalPiece, Vector2>{};

    for (final movement in movements) {
      final targetIndex = movement.toRow * level.width + movement.toCol;
      pieceDestinations[movement.piece] = pieceSlots[targetIndex].min;
    }

    // Usa AnimateFallsAction otimizada com duração 25% menor
    actionManager
        .push(
          AnimateFallsAction(
            pieceDestinations: pieceDestinations,
            baseDuration: 0.3, // Reduzido de 0.4 para 0.3 (25% mais rápido)
          ),
        )
        .push(FunctionAction(onComplete));
  }

  // Anima preenchimento do topo com animação especializada
  void _animateTopFillMovements(
    List<FallMovement> movements,
    VoidCallback onComplete,
  ) {
    if (movements.isEmpty) {
      onComplete();
      return;
    }

    final pieceDestinations = <PetalPiece, Vector2>{};

    for (final movement in movements) {
      final targetIndex = movement.toRow * level.width + movement.toCol;
      pieceDestinations[movement.piece] = pieceSlots[targetIndex].min;
    }

    // Usa TopFillAction para animação mais suave do preenchimento
    actionManager
        .push(TopFillAction(pieceDestinations: pieceDestinations))
        .push(FunctionAction(onComplete));
  }

  // Gera caminho vertical
  List<Point<int>> _generateVerticalPath(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    final steps = <Point<int>>[];
    for (int r = fromRow + 1; r <= toRow; r++) {
      steps.add(Point(toCol, r));
    }
    return steps;
  }

  // Gera caminho diagonal
  List<Point<int>> _generateDiagonalPath(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    final steps = <Point<int>>[];

    // Passos diagonais
    final diagonalSteps = (toCol - fromCol).abs();
    final colDirection = toCol > fromCol ? 1 : -1;

    for (int i = 1; i <= diagonalSteps; i++) {
      steps.add(Point(fromCol + (colDirection * i), fromRow + i));
    }

    // Passos verticais
    final verticalStart = fromRow + diagonalSteps;
    for (int r = verticalStart + 1; r <= toRow; r++) {
      steps.add(Point(toCol, r));
    }

    return steps;
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

  // =========================================================================
  // 🎮 MÉTODO PRINCIPAL DE JOGADA COM VALIDAÇÃO RIGOROSA
  // =========================================================================
  void _play(int fromIndex, int toIndex) {
    if (actionManager.isRunning()) {
      if (kDebugMode) {
        print("[PLAY] ⏸️ Movimento ignorado: ActionManager está executando");
      }
      return;
    }

    // 🚫 VALIDAÇÃO PRINCIPAL: Aplicar regras de movimento
    final validation = validateMove(fromIndex, toIndex);

    if (!validation.isAllowed) {
      // Movimento inválido - mostrar feedback e bloquear
      _showInvalidMovefeedback(validation);
      return;
    }

    // Se chegou até aqui, o movimento passou na validação básica
    final fromPiece = pieces[fromIndex];
    final toPiece = pieces[toIndex];

    // Executa a troca temporária para verificar matches
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
      // Movimento válido que resulta em match
      movesLeft.value--;

      if (kDebugMode) {
        print(
          "[PLAY] ✅ Movimento EXECUTADO: ${fromPiece.type} ↔ ${toPiece.type}",
        );
        print("[PLAY]    Matches encontrados: ${allFoundPieces.length} peças");
        print("[PLAY]    Movimentos restantes: ${movesLeft.value}");
      }

      actionManager
          .push(
            SwapPiecesAction(
              pieceDestinations: {fromPiece: toPosition, toPiece: fromPosition},
              durationMs: 150,
            ),
          )
          .push(
            FunctionAction(() {
              _processMatches(allFoundPieces);
            }),
          );
    } else {
      // Movimento não resulta em match - reverter
      if (kDebugMode) {
        print("[PLAY] ❌ Movimento REVERTIDO: não resulta em match");
      }

      final temp = pieces[fromIndex];
      pieces[fromIndex] = pieces[toIndex];
      pieces[toIndex] = temp;

      actionManager
          .push(
            SwapPiecesAction(
              pieceDestinations: {fromPiece: toPosition, toPiece: fromPosition},
              durationMs: 75, // Reduzido de 100ms para 75ms (25% mais rápido)
            ),
          )
          .push(
            SwapPiecesAction(
              pieceDestinations: {fromPiece: fromPosition, toPiece: toPosition},
              durationMs: 75, // Reduzido de 100ms para 75ms (25% mais rápido)
            ),
          );
    }
  }

  int getIndexFromPosition(Vector2 position) {
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
    final index = getIndexFromPosition(event.localPosition);
    if (index != -1) _lastProcessedIndex = index;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (actionManager.isRunning()) return;
    final currentIndex = getIndexFromPosition(event.localEndPosition);
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
    ..remove(PetalType.wall)
    ..remove(PetalType.caged1)
    ..remove(PetalType.caged2);
  return playableTypes[Random().nextInt(playableTypes.length)];
}
