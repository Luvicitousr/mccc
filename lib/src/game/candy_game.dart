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
import '../engine/level_definition.dart'; // Importa a nossa nova classe

class CandyGame extends FlameGame with DragCallbacks {
  late final List<Aabb2> pieceSlots;
  late List<PetalPiece> pieces;
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

  // ✅ 1. GUARDA A DEFINIÇÃO DO NÍVEL ATUAL.
  final LevelDefinition level;

  // ✅ 2. O CONSTRUTOR AGORA RECEBE UM NÍVEL.
  CandyGame({required this.level});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ 3. INICIALIZA TUDO A PARTIR DO OBJETO 'level'.
    objectives = ValueNotifier(Map<PetalType, int>.from(level.objectives));
    movesLeft = ValueNotifier(level.moves);

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
    final pieceSize = size.x / level.width;

    // ✅ 2. Calcula o tamanho total do tabuleiro
    final boardWidth = level.width * pieceSize;
    final boardHeight = level.height * pieceSize;

    // ✅ 3. Calcula o deslocamento para centralizar
    final offsetX = (size.x - boardWidth) / 2;
    final offsetY = (size.y - boardHeight) / 2;

    // ✅ Validação explícita do posicionamento
    assert(offsetX >= 0 && offsetY >= 0, "Offset negativo: $offsetX, $offsetY");

    // ✅ 4. Gera slots com offset de centralização
    pieceSlots = List.generate(level.width * level.height, (index) {
      final i = index % level.width;
      final j = (index / level.width).floor();
      final x = i * pieceSize + offsetX;
      final y = j * pieceSize + offsetY;
      return Aabb2.minMax(Vector2(x, y), Vector2(x + pieceSize, y + pieceSize));
    });

    // --- LÓGICA DE GERAÇÃO MODIFICADA ---
    // 5. Gera peças garantindo que não haja combinações iniciais
    final List<PetalPiece> generatedPieces = [];
    for (int j = 0; j < level.height; j++) {
      for (int i = 0; i < level.width; i++) {
        final index = j * level.width + i;
        final position = Vector2(
          i * pieceSize + offsetX,
          j * pieceSize + offsetY,
        );

        PetalType pieceType;

        // Verifica o layout do nível para decidir o que criar
        if (level.layout[index] == 0) {
          // Se for 0 no layout, é um buraco. Criamos uma peça "vazia".
          pieceType = PetalType.wall;
        } else {
          // Se for uma célula normal, gera uma peça aleatória sem combinação.
          // ESTA É A SUA LÓGICA, AGORA CORRIGIDA:
          bool isMatch;
          do {
            isMatch = false;
            pieceType = _randomPieceType(); // Gera um tipo aleatório

            // Verifica combinação horizontal (com as 2 peças à esquerda)
            if (i >= 2) {
              // Garante que estamos checando células que não são buracos
              if (level.layout[index - 1] == 1 &&
                  level.layout[index - 2] == 1) {
                // ✅ USA level.width em vez de kPieceCountWidth
                final piece1 = generatedPieces[j * level.width + (i - 1)];
                final piece2 = generatedPieces[j * level.width + (i - 2)];
                if (piece1.type == pieceType && piece2.type == pieceType) {
                  isMatch = true;
                }
              }
            }

            // Verifica combinação vertical (com as 2 peças acima)
            if (j >= 2) {
              // Garante que estamos checando células que não são buracos
              if (level.layout[index - level.width] == 1 &&
                  level.layout[index - (level.width * 2)] == 1) {
                // ✅ USA level.width em vez de kPieceCountWidth
                final piece1 = generatedPieces[(j - 1) * level.width + i];
                final piece2 = generatedPieces[(j - 2) * level.width + i];
                if (piece1.type == pieceType && piece2.type == pieceType) {
                  isMatch = true;
                }
              }
            }
          } while (isMatch);
        }

        // Adiciona a peça (normal ou vazia) à lista.
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

  // Add this new helper method
  PetalPiece? pieceAt(int i, int j) {
    if (i < 0 || i >= level.width || j < 0 || j >= level.height) {
      return null;
    }
    final index = j * level.width + i;
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
      final i = index % level.width;
      final j = (index / level.width).floor();

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

    // ✅ NOVA VERIFICAÇÃO: Peças não jogáveis não podem formar combinações.
    // Se a peça inicial for um muro ou um espaço vazio, ela não pode iniciar uma combinação.
    if (startPiece.type == PetalType.wall ||
        startPiece.type == PetalType.empty) {
      return {}; // Retorna um conjunto vazio imediatamente.
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
    for (int x = i + 1; x < level.width; x++) {
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
    for (int y = j + 1; y < level.height; y++) {
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

  // DENTRO DA CLASSE CandyGame

  /// Encontra todas as peças do tipo 'wall' que são adjacentes a um conjunto de peças.
  Set<PetalPiece> _findAdjacentWalls(Set<PetalPiece> pieceSet) {
    final wallsToClear = <PetalPiece>{};

    for (final piece in pieceSet) {
      final index = pieces.indexOf(piece);
      final i = index % level.width;
      final j = (index / level.width).floor();

      // Lista de coordenadas vizinhas (cima, baixo, esquerda, direita)
      final neighborsCoords = [
        Point(i, j - 1), // Cima
        Point(i, j + 1), // Baixo
        Point(i - 1, j), // Esquerda
        Point(i + 1, j), // Direita
      ];

      for (final coord in neighborsCoords) {
        final neighborPiece = pieceAt(coord.x.toInt(), coord.y.toInt());
        // Se o vizinho existe e é um buraco, adiciona à lista para limpeza.
        // ✅ Se o vizinho existe e é um MURO, adiciona à lista para limpeza.
        if (neighborPiece != null && neighborPiece.type == PetalType.wall) {
          wallsToClear.add(neighborPiece);
        }
      }
    }

    return wallsToClear;
  }

  // DENTRO DA CLASSE CandyGame

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

            // Apenas chama a função. Ela agora gerencia a própria
            // sequência de animação e a próxima verificação.
            _cascadeAndRefill();
          }),
        );
  }

  // DENTRO DA CLASSE CandyGame

  /// Aplica gravidade e preenchimento por segmentos de coluna, respeitando os muros.
  void _cascadeAndRefill() {
    final pieceSize = size.x / level.width;
    final moves = <PetalPiece, Vector2>{};

    final newPiecesState = List<PetalPiece>.from(pieces);

    // Itera através de cada coluna.
    for (int i = 0; i < level.width; i++) {
      // 1. Encontra os limites dos segmentos (muros, topo e fundo).
      final wallBoundaries = <int>[-1]; // Adiciona o "topo" virtual
      for (int j = 0; j < level.height; j++) {
        if (pieceAt(i, j)!.type == PetalType.wall) {
          wallBoundaries.add(j);
        }
      }
      wallBoundaries.add(level.height); // Adiciona o "fundo" virtual

      // 2. Processa cada segmento da coluna, de baixo para cima.
      for (int k = wallBoundaries.length - 2; k >= 0; k--) {
        final topWallIndex = wallBoundaries[k];
        final bottomWallIndex = wallBoundaries[k + 1];

        final segmentHeight = bottomWallIndex - topWallIndex - 1;
        if (segmentHeight <= 0) continue;

        // 3. Coleta as peças jogáveis existentes DENTRO do segmento.
        final piecesInSegment = Queue<PetalPiece>();
        for (int j = topWallIndex + 1; j < bottomWallIndex; j++) {
          final piece = pieceAt(i, j)!;
          if (piece.type != PetalType.empty) {
            // Muros não entram aqui
            piecesInSegment.add(piece);
          }
        }

        // 4. Se este é o segmento do topo, gera novas peças para preencher.
        final bool isTopSegment = topWallIndex == -1;
        if (isTopSegment) {
          final newPieceCount = segmentHeight - piecesInSegment.length;
          for (int n = 0; n < newPieceCount; n++) {
            final newPosition = pieceSlots[n * level.width + i].min;
            final newPiece = PetalPiece(
              type: _randomPieceType(),
              position: Vector2(
                newPosition.x,
                -pieceSize * (newPieceCount - n),
              ),
              size: Vector2.all(pieceSize),
            );
            add(newPiece); // Adiciona a nova peça ao jogo
            piecesInSegment.addFirst(newPiece); // Adiciona no início da fila
          }
        }

        // 5. Preenche o segmento na nova lista, de baixo para cima.
        for (int j = bottomWallIndex - 1; j > topWallIndex; j--) {
          final index = j * level.width + i;
          final newPosition = pieceSlots[index].min;

          final pieceToPlace = piecesInSegment.isNotEmpty
              ? piecesInSegment.removeLast()
              : pieceAt(i, j)!; // Se não há peças, deixa o buraco (empty)

          newPiecesState[index] = pieceToPlace;
          moves[pieceToPlace] = newPosition;
        }
      }
    }

    // Limpa peças que foram substituídas por completo
    for (final oldPiece in pieces) {
      if (!newPiecesState.contains(oldPiece)) {
        oldPiece.removeFromParent();
      }
    }

    pieces = newPiecesState;

    // Empurra as ações para a fila
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

  // ✅ NOVO: Encontra todas as combinações no tabuleiro.
  /// Varre o tabuleiro inteiro e retorna um Set com todas as peças
  /// que fazem parte de alguma combinação.
  Set<PetalPiece> _findAllMatchesOnBoard() {
    final allMatches = <PetalPiece>{};
    for (int j = 0; j < level.height; j++) {
      for (int i = 0; i < level.width; i++) {
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
    // ✅ 1. ADICIONE ESTA VERIFICAÇÃO NO INÍCIO DO MÉTODO.
    final fromPiece = pieces[fromIndex];
    final toPiece = pieces[toIndex];

    // Se a peça de origem ou de destino for um buraco, não faz nada.
    if (fromPiece.type == PetalType.wall || toPiece.type == PetalType.wall) {
      return;
    }
    if (actionManager.isRunning()) {
      return;
    }

    // Troca lógica temporária para verificação.
    final temp = pieces[fromIndex];
    pieces[fromIndex] = pieces[toIndex];
    pieces[toIndex] = temp;

    // Verifica se a troca resultou em alguma combinação.
    final fromI = fromIndex % level.width;
    final fromJ = (fromIndex / level.width).floor();
    final toI = toIndex % level.width;
    final toJ = (toIndex / level.width).floor();

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
    final pieceSize = size.x / level.width;
    final offsetX = (size.x - level.width * pieceSize) / 2;
    final offsetY = (size.y - level.width * pieceSize) / 2;

    // ✅ 6. Ajusta posição para compensar o offset de centralização
    final adjustedX = position.x - offsetX;
    final adjustedY = position.y - offsetY;

    final i = (adjustedX / pieceSize).floor();
    final j = (adjustedY / pieceSize).floor();

    if (i >= 0 && i < level.width && j >= 0 && j < level.width) {
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
      // Verifica se o movimento é para uma peça adjacente (não diagonal)
      int from = _lastProcessedIndex;
      int to = currentIndex;
      int fromX = from % level.width;
      int fromY = (from / level.width).floor();
      int toX = to % level.width;
      int toY = (to / level.width).floor();

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
  // A declaração da lista e as chamadas de 'remove' são uma única instrução.
  final List<PetalType> playableTypes = List.from(PetalType.values)
    ..remove(PetalType.empty)
    ..remove(PetalType.wall); // O ponto e vírgula (;) só vai no final de tudo.

  // Retorna um tipo aleatório apenas da lista de peças jogáveis.
  return playableTypes[Random().nextInt(playableTypes.length)];
}
