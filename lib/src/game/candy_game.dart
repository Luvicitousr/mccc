import 'dart:async';
import 'dart:math';
import 'dart:collection'; // <-- ADICIONE ESTA LINHA
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../actions/swap_pieces_action.dart';
// ✅ 1. Importe as novas ações que criamos/usaremos.
import '../actions/remove_pieces_action.dart';
import '../actions/callback_action.dart';
import '../engine/action_manager.dart';
import '../engine/petal_piece.dart';
import 'package:flutter/foundation.dart'; // Necessário para ValueNotifier

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

    // ✅ 3. LÓGICA DE FIM DE JOGO MOVIDA PARA CÁ.
    // Verifica se os movimentos acabaram, se não há ações rodando
    // e se o jogo já não terminou.
    if (movesLeft.value == 0 && !actionManager.isRunning() && !_isGameOver) {
      // Marca que o jogo terminou para não entrar aqui de novo.
      _isGameOver = true;

      // Pausa a lógica do jogo e exibe a tela de game over.
      pauseEngine();
      overlays.add('gameOverPanel');
    }

    // ✅ 4. ADICIONE A LÓGICA DE FIM DE JOGO (VITÓRIA).
    final allObjectivesMet = objectives.value.values.every(
      (count) => count <= 0,
    );
    if (allObjectivesMet && !_isGameWon && !_isGameOver) {
      _isGameWon = true;
      pauseEngine();
      overlays.add('gameWonPanel');
    }
  }

  // ✅ 1. ADICIONE O NOTIFIER PARA OS MOVIMENTOS E UM CALLBACK DE GAME OVER.
  /// Notificador que armazena os movimentos restantes. A UI vai escutar isso.
  late final ValueNotifier<int> movesLeft;

  // ✅ 1. Adicione uma flag para controlar o estado de "Game Over".
  bool _isGameOver = false;

  // ✅ 1. ADICIONE AS VARIÁVEIS PARA OS OBJETIVOS.
  late final ValueNotifier<Map<PetalType, int>> objectives;
  bool _isGameWon = false;

  CandyGame();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ 2. DEFINA OS OBJETIVOS PARA O NÍVEL.
    objectives = ValueNotifier({PetalType.cherry: 10, PetalType.maple: 10});

    // ✅ 3. INICIALIZE OS MOVIMENTOS E ATIVE O OVERLAY.
    movesLeft = ValueNotifier(30); // O jogador começa com 30 movimentos.

    // ✅ 3. ATIVE O NOVO OVERLAY DO PAINEL DE OBJETIVOS.
    overlays.add('movesPanel');
    overlays.add('objectivesPanel');

    // ✅ 2. ADICIONE ESTE BLOCO DE CÓDIGO NO INÍCIO DO onLOAD.
    // Carrega e adiciona o componente de imagem de fundo.
    final background = await Sprite.load('Background.jpg');
    add(
      SpriteComponent(
        sprite: background,
        size: size, // Faz a imagem ter o mesmo tamanho da tela.
        position: Vector2.zero(), // Posiciona no canto superior esquerdo.
        priority:
            -1, // Prioridade negativa para garantir que fique atrás de tudo.
      ),
    );
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
    for (int x = i - 1; x >= 0; x--) {
      // Esquerda
      final p = pieceAt(x, j);
      if (p?.type == currentType) {
        horizontalLine.add(p!);
      } else {
        break;
      }
    }
    for (int x = i + 1; x < kPieceCountWidth; x++) {
      // Direita
      final p = pieceAt(x, j);
      if (p?.type == currentType) {
        horizontalLine.add(p!);
      } else {
        break;
      }
    }

    // Varredura Vertical
    List<PetalPiece> verticalLine = [startPiece];
    for (int y = j - 1; y >= 0; y--) {
      // Cima
      final p = pieceAt(i, y);
      if (p?.type == currentType) {
        verticalLine.add(p!);
      } else {
        break;
      }
    }
    for (int y = j + 1; y < kPieceCountHeight; y++) {
      // Baixo
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

  // ✅ NOVO: Orquestrador principal da reação em cadeia.
  /// Inicia o processo de remoção e cascata para um conjunto de peças combinadas.
  void _processMatches(Set<PetalPiece> matchedPieces) {
    // Se não há o que processar, simplesmente retorna.
    if (matchedPieces.isEmpty) {
      return;
    }

    actionManager
        // 1. Anima o desaparecimento das peças da combinação atual.
        .push(RemovePiecesAction(piecesToRemove: matchedPieces))
        // 2. Após a animação, executa a lógica de cascata e verifica novas combinações.
        .push(
          FunctionAction(() {
            // ✅ 5. DECREMENTE OS OBJETIVOS QUANDO AS PEÇAS SÃO REMOVIDAS.
            // Cria uma cópia do mapa atual de objetivos.
            final currentObjectives = Map<PetalType, int>.from(
              objectives.value,
            );
            bool objectivesUpdated = false;
            // Marca as peças como 'empty' logicamente.
            for (final piece in matchedPieces) {
              // Se a peça combinada faz parte dos objetivos...
              if (currentObjectives.containsKey(piece.type)) {
                // Decrementa o contador.
                currentObjectives[piece.type] =
                    (currentObjectives[piece.type]! - 1).clamp(0, 999);
                objectivesUpdated = true;
              }
              piece.changeType(PetalType.empty);
            }

            if (objectivesUpdated) {
              objectives.value = currentObjectives;
            }

            // Calcula as animações de gravidade e preenchimento.
            final fallAnimation = _cascadeAndRefill();

            // Se houve alguma peça que se moveu ou foi criada...
            if (fallAnimation.pieceDestinations.isNotEmpty) {
              // 3. Anima a queda das peças.
              actionManager
                  .push(fallAnimation)
                  .push(
                    FunctionAction(() {
                      // 4. Após a queda, verifica o tabuleiro inteiro por novas combinações.
                      final newMatches = _findAllMatchesOnBoard();
                      // Se encontrou, inicia o processo de novo (reação em cadeia).
                      if (newMatches.isNotEmpty) {
                        _processMatches(newMatches);
                      }
                    }),
                  );
            }
          }),
        );
  }

  // ✅ NOVO: Lógica de gravidade e preenchimento.
  /// Aplica a gravidade, preenche o topo e retorna uma ação de animação (`SwapPiecesAction`)
  /// com todos os movimentos necessários.
  SwapPiecesAction _cascadeAndRefill() {
    final pieceSize = size.x / kPieceCountWidth;
    final Map<PetalPiece, Vector2> moves = {};

    // --- 1. Lógica de Gravidade (Peças caindo) ---
    for (int i = 0; i < kPieceCountWidth; i++) {
      int emptySlots = 0;
      // Itera a coluna de baixo para cima.
      for (int j = kPieceCountHeight - 1; j >= 0; j--) {
        final piece = pieceAt(i, j)!;
        if (piece.type == PetalType.empty) {
          emptySlots++;
        } else if (emptySlots > 0) {
          // ✅ LÓGICA CORRIGIDA: Realiza uma troca de posições na lista `pieces`.
          final currentIndex = j * kPieceCountWidth + i;
          final targetIndex = (j + emptySlots) * kPieceCountWidth + i;

          // A peça que vai se mover é a que está na posição atual.
          final pieceToMove = pieces[currentIndex];

          // Troca a peça atual com a peça do destino (que é uma peça vazia).
          pieces[currentIndex] = pieces[targetIndex];
          pieces[targetIndex] = pieceToMove;

          // Adiciona o movimento da peça que caiu para a animação.
          moves[piece] = pieceSlots[targetIndex].min.clone();
        }
      }
    }

    // --- 2. Lógica de Preenchimento (Novas peças do topo) ---
    for (int i = 0; i < kPieceCountWidth; i++) {
      for (int j = kPieceCountHeight - 1; j >= 0; j--) {
        final piece = pieceAt(i, j)!;
        if (piece.type == PetalType.empty) {
          // Posição inicial da animação (acima da tela).
          final slot = pieceSlots[j * kPieceCountWidth + i];
          piece.position = Vector2(slot.min.x, -pieceSize);

          // Muda o tipo para uma nova peça aleatória.
          piece.changeType(_randomPieceType());
          // Garante que a peça está visível para a animação.
          piece.opacity = 1.0;
          piece.scale = Vector2.all(1.0);

          // Adiciona o movimento para a animação (cair na posição final).
          moves[piece] = slot.min.clone();
        }
      }
    }

    // Retorna uma única ação que animará todas as peças simultaneamente.
    return SwapPiecesAction(pieceDestinations: moves, durationMs: 400);
  }

  // ✅ NOVO: Encontra todas as combinações no tabuleiro.
  /// Varre o tabuleiro inteiro e retorna um Set com todas as peças
  /// que fazem parte de alguma combinação.
  Set<PetalPiece> _findAllMatchesOnBoard() {
    final allMatches = <PetalPiece>{};
    for (int j = 0; j < kPieceCountHeight; j++) {
      for (int i = 0; i < kPieceCountWidth; i++) {
        // Usa a função já existente para encontrar linhas a partir de um ponto.
        // O `addAll` evita duplicatas pois é um Set.
        allMatches.addAll(_findLinesAt(i, j));
      }
    }
    return allMatches;
  }

  // ✅ MODIFICADO: O método _play agora apenas inicia o processo.
  /// Orquestra a troca inicial e inicia a primeira verificação de combinação.
  void _play(int fromIndex, int toIndex) {
    if (actionManager.isRunning()) {
      return;
    }

    final fromPiece = pieces[fromIndex];
    final toPiece = pieces[toIndex];

    // Troca lógica temporária para verificação.
    final temp = pieces[fromIndex];
    pieces[fromIndex] = pieces[toIndex];
    pieces[toIndex] = temp;

    // Verifica se a troca resultou em alguma combinação.
    final fromI = fromIndex % kPieceCountWidth;
    final fromJ = (fromIndex / kPieceCountWidth).floor();
    final toI = toIndex % kPieceCountWidth;
    final toJ = (toIndex / kPieceCountWidth).floor();

    final Set<PetalPiece> allFoundPieces = {};
    allFoundPieces.addAll(_findAndResolveComplexMatches(toI, toJ));
    allFoundPieces.addAll(_findAndResolveComplexMatches(fromI, fromJ));

    // Posições para as animações.
    final fromPosition = pieceSlots[fromIndex].min.clone();
    final toPosition = pieceSlots[toIndex].min.clone();

    // CASO A: COMBINAÇÃO VÁLIDA ENCONTRADA
    if (allFoundPieces.isNotEmpty) {
      // ✅ 4. DECREMENTE O NÚMERO DE MOVIMENTOS.
      movesLeft.value--;
      // Inicia a animação de troca.
      actionManager
          .push(
            SwapPiecesAction(
              pieceDestinations: {fromPiece: toPosition, toPiece: fromPosition},
            ),
          )
          .push(
            FunctionAction(() {
              // Após a troca, inicia a cascata e reações em cadeia.
              _processMatches(allFoundPieces);
            }),
          );
    }
    // CASO B: TROCA INVÁLIDA
    else {
      // Desfaz a troca lógica.
      final temp = pieces[fromIndex];
      pieces[fromIndex] = pieces[toIndex];
      pieces[toIndex] = temp;

      // Anima o "bate e volta".
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
  // 1. Cria uma lista com todos os tipos possíveis a partir do enum.
  final List<PetalType> allTypes = List.from(PetalType.values);

  // 2. Remove o tipo 'empty' da lista, garantindo que ele não seja escolhido.
  allTypes.remove(PetalType.empty);

  // 3. Retorna um tipo aleatório apenas da lista de peças jogáveis.
  return allTypes[Random().nextInt(allTypes.length)];
}
