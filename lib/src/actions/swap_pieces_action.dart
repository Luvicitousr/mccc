// lib/src/gameplay/actions/swap_pieces_action.dart
import 'dart:collection'; // <-- IMPORTAÇÃO NECESSÁRIA PARA ListQueue
import 'dart:math';
import 'package:flame/components.dart';
//import '../engine/board.dart';
//import '../utils/animations.dart';
import '../engine/action_manager.dart';
import '../engine/petal_piece.dart';

/// Uma ação que move uma lista de peças para seus respectivos destinos de forma simultânea,
/// com uma animação suave de aceleração e desaceleração (ease-in/ease-out).
class SwapPiecesAction extends Action {
  // MUDANÇA: Em vez de uma lista de peças e um único destino, usamos um mapa.
  // A chave é a peça a ser movida, e o valor é seu Vector2 de destino.
  final Map<PetalPiece, Vector2> pieceDestinations;

  /// A duração total da animação em milissegundos.
  final int durationMs;

  // Manteremos listas internas para a animação, para garantir uma ordem consistente.
  late final List<PetalPiece> _pieces;
  late final List<Vector2> _fromPositions;
  late final List<Vector2> _toPositions;

  late final int _startTime;
  late final int _endTime;

  // MUDANÇA: O construtor agora é mais flexível.
  SwapPiecesAction({
    required this.pieceDestinations,
    this.durationMs = 300,
  });

  @override
  void onStart(Map<String, dynamic> globals) {
    // MUDANÇA: Populamos nossas listas internas a partir do mapa.
    
    // 1. Pega a lista de peças a partir das chaves do mapa.
    _pieces = pieceDestinations.keys.toList();

    // 2. Armazena a posição inicial de cada peça.
    _fromPositions = _pieces.map((p) => p.position.clone()).toList();

    // 3. Armazena a posição final de cada peça a partir dos valores do mapa.
    _toPositions = _pieces.map((p) => pieceDestinations[p]!).toList();
    
    // 4. Calcula o tempo de início e fim da animação (semelhante a antes).
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _endTime = _startTime + durationMs;
  }

  // A CORREÇÃO ESTÁ AQUI: List<Action> foi trocado por ListQueue<Action>
  @override
  void perform(ListQueue<Action> actionQueue, Map<String, dynamic> globals) {
    final int currentTime = DateTime.now().millisecondsSinceEpoch;

    // Se a animação terminou
    if (currentTime >= _endTime) {
      // Garante que todas as peças estejam exatamente em suas posições finais.
      for (int i = 0; i < _pieces.length; i++) {
        _pieces[i].position = _toPositions[i];
      }
      terminate(); // Finaliza a ação.
      return;
    }

    // Calcula a proporção do tempo decorrido (de 0.0 a 1.0).
    final double t = (currentTime - _startTime) / durationMs;

    // **Aplica a interpolação quadrática ease-in/ease-out**
    final double easedT = _quadraticEaseInOut(t);

    // Atualiza a posição de cada peça.
    for (int i = 0; i < _pieces.length; i++) {
      final Vector2 start = _fromPositions[i];
      final Vector2 end = _toPositions[i];

      // Interpola linearmente entre a posição inicial e final usando o tempo "suavizado".
      _pieces[i].position = start + (end - start) * easedT;
    }
  }

  /// Calcula a proporção de tempo suavizada usando uma curva quadrática ease-in/out.
  /// - A primeira metade do movimento acelera (t²).
  /// - A segunda metade do movimento desacelera.
  double _quadraticEaseInOut(double t) {
    if (t < 0.5) {
      return 2 * t * t;
    } else {
      return 1 - pow(-2 * t + 2, 2) / 2;
    }
  }
}
