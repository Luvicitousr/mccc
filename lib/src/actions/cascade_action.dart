// lib/src/actions/cascade_action.dart
import 'dart:collection';
import 'package:flame/components.dart';
import 'package:meu_candy_crush_clone/src/engine/petal_piece.dart';
import 'package:meu_candy_crush_clone/src/game/candy_game.dart';
import '../engine/action_manager.dart';
import 'callback_action.dart';
import 'swap_pieces_action.dart';

class CascadeAction extends Action {
  final CandyGame game;

  CascadeAction(this.game);

  @override
  void perform(ListQueue<Action> actionQueue, Map<String, dynamic> globals) {
    // Esta ação agora calcula o resultado final da cascata de uma só vez.
    final pieceSize = game.size.x / game.level.width;
    final moves = <PetalPiece, Vector2>{};
    final finalPiecesState = List<PetalPiece>.from(game.pieces);

    // Itera através de cada coluna para aplicar a lógica de segmento.
    for (int i = 0; i < game.level.width; i++) {
      // 1. Encontra os limites dos segmentos (muros, topo e fundo).
      final wallBoundaries = <int>[-1]; // Topo virtual
      for (int j = 0; j < game.level.height; j++) {
        if (game.pieceAt(i, j)!.type == PetalType.wall) {
          wallBoundaries.add(j);
        }
      }
      wallBoundaries.add(game.level.height); // Fundo virtual

      // 2. Processa cada segmento da coluna, de cima para baixo.
      for (int k = 0; k < wallBoundaries.length - 1; k++) {
        final topWallIndex = wallBoundaries[k];
        final bottomWallIndex = wallBoundaries[k + 1];

        final segmentHeight = bottomWallIndex - topWallIndex - 1;
        if (segmentHeight <= 0) continue;

        // 3. Coleta as peças jogáveis existentes DENTRO do segmento.
        final piecesInSegment = Queue<PetalPiece>();
        for (int j = topWallIndex + 1; j < bottomWallIndex; j++) {
          final piece = game.pieceAt(i, j)!;
          if (piece.type != PetalType.empty) {
            // Muros não entram aqui
            piecesInSegment.add(piece);
          }
        }

        // 4. Gera novas peças APENAS se for o segmento do topo.
        if (topWallIndex == -1) {
          final newPieceCount = segmentHeight - piecesInSegment.length;
          for (int n = 0; n < newPieceCount; n++) {
            final newPiece = PetalPiece(
              type: game.randomPieceType(),
              position: Vector2.zero(), // A posição será definida na animação
              size: Vector2.all(pieceSize),
            );
            // Adiciona no início da fila para que caiam do topo.
            piecesInSegment.addFirst(newPiece);
          }
        }

        // 5. Preenche o segmento na lista final, de baixo para cima.
        for (int j = bottomWallIndex - 1; j > topWallIndex; j--) {
          final index = j * game.level.width + i;

          final pieceToPlace = piecesInSegment.isNotEmpty
              ? piecesInSegment.removeLast()
              : finalPiecesState[index]; // Mantém o buraco se não houver peça

          finalPiecesState[index] = pieceToPlace;
        }
      }
    }

    // Após calcular todo o novo estado, agora vamos preparar a animação.
    final newPiecesToAdd = <PetalPiece>[];
    for (int i = 0; i < finalPiecesState.length; i++) {
      final piece = finalPiecesState[i];
      // Se a peça ainda não está no jogo, é uma peça nova.
      if (!game.children.contains(piece)) {
        newPiecesToAdd.add(piece);
        final slot = game.pieceSlots[i];
        // Define a posição inicial acima da tela
        piece.position = Vector2(
          slot.min.x,
          -pieceSize * (newPiecesToAdd.length),
        );
      }
      // Registra a posição final de todas as peças para a animação.
      moves[piece] = game.pieceSlots[i].min;
    }

    // Atualiza o estado lógico do jogo e adiciona as novas peças à árvore de componentes.
    game.pieces = finalPiecesState;
    game.addAll(newPiecesToAdd);

    // Agenda as ações de animação e a próxima verificação.
    if (moves.isNotEmpty) {
      actionQueue.addFirst(
        SwapPiecesAction(pieceDestinations: moves, durationMs: 400),
      );
    }
    actionQueue.addFirst(
      FunctionAction(() {
        final newMatches = game.findAllMatchesOnBoard();
        if (newMatches.isNotEmpty) {
          game.processMatches(newMatches);
        }
      }),
    );

    // A ação cumpriu seu propósito e termina imediatamente.
    terminate();
  }
}
