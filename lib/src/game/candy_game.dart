import 'dart:async';
import 'dart:math';
import 'dart:collection'; // <-- ADICIONE ESTA LINHA
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../actions/swap_pieces_action.dart';
import '../actions/callback_action.dart';
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
    pieceSlots = List.generate(kPieceCountWidth * kPieceCountHeight, (index) {
      final i = index % kPieceCountWidth;
      final j = (index / kPieceCountWidth).floor();
      final x = i * pieceSize + offsetX;
      final y = j * pieceSize + offsetY;
      return Aabb2.minMax(Vector2(x, y), Vector2(x + pieceSize, y + pieceSize));
    });

    // --- LÓGICA DE GERAÇÃO MODIFICADA ---
    // 5. Gera peças garantindo que não haja combinações iniciais
    final List<PetalPiece> generatedPieces = [];
    for (int j = 0; j < kPieceCountHeight; j++) {
      for (int i = 0; i < kPieceCountWidth; i++) {
        PetalType newType;
        bool isMatch;

        do {
          isMatch = false;
          newType = _randomPieceType(); // Gera um tipo aleatório

          // Verifica combinação horizontal (com as 2 peças à esquerda)
          if (i >= 2) {
            final piece1 = generatedPieces[j * kPieceCountWidth + (i - 1)];
            final piece2 = generatedPieces[j * kPieceCountWidth + (i - 2)];
            if (piece1.type == newType && piece2.type == newType) {
              isMatch = true;
            }
          }

          // Verifica combinação vertical (com as 2 peças acima)
          if (j >= 2) {
            final piece1 = generatedPieces[(j - 1) * kPieceCountWidth + i];
            final piece2 = generatedPieces[(j - 2) * kPieceCountWidth + i];
            if (piece1.type == newType && piece2.type == newType) {
              isMatch = true;
            }
          }
        } while (isMatch);

        // Posição da nova peça
        final position = Vector2(
          i * pieceSize + offsetX,
          j * pieceSize + offsetY,
        );

        // Adiciona a peça válida à lista
        generatedPieces.add(
          PetalPiece(
            type: newType,
            position: position,
            size: Vector2.all(pieceSize),
          ),
        );
      }
    }

    pieces = generatedPieces;
    await addAll(pieces);
  }

  // Add this new helper method
  PetalPiece? pieceAt(int i, int j) {
    if (i < 0 || i >= kPieceCountWidth || j < 0 || j >= kPieceCountHeight) {
      return null;
    }
    final index = j * kPieceCountWidth + i;
    return pieces[index];
  }

  // DENTRO DA CLASSE CandyGame

/// Orquestrador principal para encontrar combinações complexas baseadas em linhas.
Set<PetalPiece> _findAndResolveComplexMatches(int startX, int startY) {
  final Set<PetalPiece> initialSeed = _findLinesAt(startX, startY);

  // Se nenhuma linha inicial for encontrada no ponto de partida, não há combinação.
  if (initialSeed.isEmpty) {
    return {};
  }

  final Set<PetalPiece> finalMatchPieces = Set.from(initialSeed);
  final Queue<PetalPiece> piecesToProcess = Queue.from(initialSeed);

  // Enquanto houver peças a serem verificadas...
  while (piecesToProcess.isNotEmpty) {
    final currentPiece = piecesToProcess.removeFirst();
    final index = pieces.indexOf(currentPiece);
    final i = index % kPieceCountWidth;
    final j = (index / kPieceCountWidth).floor();

    // Verifique se esta peça também forma novas linhas
    final Set<PetalPiece> foundLines = _findLinesAt(i, j);

    for (final newPiece in foundLines) {
      // Se `add` retornar true, a peça era nova e deve ser processada também.
      if (finalMatchPieces.add(newPiece)) {
        piecesToProcess.add(newPiece);
      }
    }
  }

  return finalMatchPieces;
}

/// Encontra todas as linhas retas (H e V) de 3+ peças que passam por um ponto (i, j).
Set<PetalPiece> _findLinesAt(int i, int j) {
  final PetalPiece? startPiece = pieceAt(i, j);
  if (startPiece == null) {
    return {};
  }
  final currentType = startPiece.type;
  final Set<PetalPiece> foundPieces = {};

  // Varredura Horizontal
  List<PetalPiece> horizontalLine = [startPiece];
  for (int x = i - 1; x >= 0; x--) { // Esquerda
    final p = pieceAt(x, j);
    if (p?.type == currentType) { horizontalLine.add(p!); } else { break; }
  }
  for (int x = i + 1; x < kPieceCountWidth; x++) { // Direita
    final p = pieceAt(x, j);
    if (p?.type == currentType) { horizontalLine.add(p!); } else { break; }
  }

  // Varredura Vertical
  List<PetalPiece> verticalLine = [startPiece];
  for (int y = j - 1; y >= 0; y--) { // Cima
    final p = pieceAt(i, y);
    if (p?.type == currentType) { verticalLine.add(p!); } else { break; }
  }
  for (int y = j + 1; y < kPieceCountHeight; y++) { // Baixo
    final p = pieceAt(i, y);
    if (p?.type == currentType) { verticalLine.add(p!); } else { break; }
  }

  if (horizontalLine.length >= 3) {
    foundPieces.addAll(horizontalLine);
  }
  if (verticalLine.length >= 3) {
    foundPieces.addAll(verticalLine);
  }

  return foundPieces;
}

  // DENTRO DA CLASSE CandyGame

void _play(int fromIndex, int toIndex) {
  if (actionManager.isRunning()) {
    return;
  }

  print("Tentativa de troca: $fromIndex <-> $toIndex");

  // ETAPA 1: TROCA LÓGICA TEMPORÁRIA
  final PetalPiece fromPiece = pieces[fromIndex];
  final PetalPiece toPiece = pieces[toIndex];
  final temp = pieces[fromIndex];
  pieces[fromIndex] = pieces[toIndex];
  pieces[toIndex] = temp;

  // ETAPA 2: VERIFICAÇÃO IMEDIATA DE COMBINAÇÃO
  final fromI = fromIndex % kPieceCountWidth;
  final fromJ = (fromIndex / kPieceCountWidth).floor();
  final toI = toIndex % kPieceCountWidth;
  final toJ = (toIndex / kPieceCountWidth).floor();
  final Set<PetalPiece> allFoundPieces = {};
  allFoundPieces.addAll(_findAndResolveComplexMatches(toI, toJ));
  allFoundPieces.addAll(_findAndResolveComplexMatches(fromI, fromJ));

  // Posições de origem e destino
  final Vector2 fromPosition = pieceSlots[fromIndex].min.clone();
  final Vector2 toPosition = pieceSlots[toIndex].min.clone();

  // ETAPA 3: DECISÃO (ANIMAR TROCA OU "BATE E VOLTA")

  // CASO A: COMBINAÇÃO ENCONTRADA
  if (allFoundPieces.isNotEmpty) {
    print("Combinação VÁLIDA encontrada com ${allFoundPieces.length} peças!");
    
    // Apenas UMA ação para a troca simultânea, usando o construtor de Map.
    actionManager.push(SwapPiecesAction(
      pieceDestinations: {
        fromPiece: toPosition,
        toPiece: fromPosition,
      },
    ));
    
    // Futuramente, adicione a ação para remover as peças combinadas aqui.

  }
  // CASO B: NENHUMA COMBINAÇÃO ENCONTRADA
  else {
    print("Nenhuma combinação encontrada. Revertendo.");

    // 1. Desfazemos a troca lógica.
    final temp = pieces[fromIndex];
    pieces[fromIndex] = pieces[toIndex];
    pieces[toIndex] = temp;

    // 2. DUAS ações sequenciais para o "bate e volta".
    // Primeira ação: move as peças para as posições trocadas.
    actionManager.push(SwapPiecesAction(
      pieceDestinations: {
        fromPiece: toPosition,
        toPiece: fromPosition,
      },
      durationMs: 150,
    ));
    // Segunda ação: move as peças de volta para as posições originais.
    actionManager.push(SwapPiecesAction(
      pieceDestinations: {
        fromPiece: fromPosition,
        toPiece: toPosition,
      },
      durationMs: 150,
    ));
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
      // Verifica se o movimento é para uma peça adjacente (não diagonal)
      int from = _lastProcessedIndex;
      int to = currentIndex;
      int fromX = from % kPieceCountWidth;
      int fromY = (from / kPieceCountWidth).floor();
      int toX = to % kPieceCountWidth;
      int toY = (to / kPieceCountWidth).floor();

      if ((fromX == toX && (fromY - toY).abs() == 1) ||
          (fromY == toY && (fromX - toX).abs() == 1)) {
        // Inicia a ação de troca
        _play(from, to);

        // Reseta o índice para garantir que um único arrasto gere apenas uma troca.
        _lastProcessedIndex = -1;
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
  final nonSpecialTypes =
      PetalType.values; // Adicione filtro se tiver peças especiais
  return nonSpecialTypes[Random().nextInt(nonSpecialTypes.length)];
}
