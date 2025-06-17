// lib/src/actions/remove_pieces_action.dart

import 'dart:math';
import 'package:meu_candy_crush_clone/src/engine/action_manager.dart';
import 'package:meu_candy_crush_clone/src/engine/petal_piece.dart';
import 'package:flame/components.dart';

/// Uma ação que anima o desaparecimento de um conjunto de peças.
class RemovePiecesAction extends Action {
  /// O conjunto de peças a serem removidas.
  final Set<PetalPiece> piecesToRemove;

  /// A duração da animação em milissegundos.
  final int durationMs;

  late final int _startTime;
  late final int _endTime;

  // ✅ CORREÇÃO AQUI:
  // Envolvemos os parâmetros do construtor em chaves `{}` para torná-los
  // nomeados. `required` garante que `pieces` seja sempre fornecido.
  RemovePiecesAction({
    required this.piecesToRemove,
    this.durationMs = 200,
  });

  @override
  void onStart(Map<String, dynamic> globals) {
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _endTime = _startTime + durationMs;
  }

  @override
  void perform(actionQueue, globals) {
    final int currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime >= _endTime) {
      // Animação terminada: remove os componentes do jogo.
      for (final piece in piecesToRemove) {
        piece.opacity = 0;
        piece.scale = Vector2.zero();
      }
      
      terminate(); // <-- AVISA QUE A AÇÃO TERMINOU
      return;
    }

    // Calcula o progresso da animação (de 0.0 a 1.0)
    final double t = (currentTime - _startTime) / durationMs;
    // Uma curva "easeIn" para a animação parecer mais natural
    final double easedT = pow(t, 2).toDouble();

    // Aplica a animação em cada peça
    for (final piece in piecesToRemove) {
      // Diminui o tamanho
      piece.scale = Vector2.all(1.0 - easedT);
      // Diminui a opacidade
      piece.opacity = 1.0 - easedT;
    }
  }
}
