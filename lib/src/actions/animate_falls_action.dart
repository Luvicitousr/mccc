// lib/src/actions/animate_falls_action.dart

import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import '../engine/action_manager.dart';
import 'dart:collection';
import '../engine/petal_piece.dart';

/// # AnimateFallsAction
/// Anima a queda de um conjunto de peças para suas posições de destino.
/// Versão otimizada com velocidade 25% maior e curva de animação natural.
class AnimateFallsAction extends Action {
  final Map<PetalPiece, Vector2> pieceDestinations;
  final double baseDuration; // Duração base da animação em segundos
  final int?
  durationMs; // Duração opcional em milissegundos para compatibilidade

  double _elapsedTime = 0;
  final Map<PetalPiece, Vector2> _initialPositions = {};
  final Map<PetalPiece, double> _fallDistances = {};
  late final double _actualDuration;

  AnimateFallsAction({
    required this.pieceDestinations,
    this.baseDuration = 0.3, // Reduzido de 0.4 para 0.3 (25% mais rápido)
    this.durationMs,
  }) {
    // Calcula duração final baseada no parâmetro fornecido
    if (durationMs != null) {
      _actualDuration = (durationMs! * 0.75) / 1000.0; // 25% mais rápido
    } else {
      _actualDuration = baseDuration;
    }
  }

  /// Calcula a distância de queda para cada peça para ajustar a velocidade
  void _calculateFallDistances() {
    for (var entry in pieceDestinations.entries) {
      final piece = entry.key;
      final destination = entry.value;
      final initialPos = _initialPositions[piece]!;

      // Calcula distância euclidiana para normalizar velocidade
      final distance = (destination - initialPos).length;
      _fallDistances[piece] = distance;
    }
  }

  /// Curva de animação otimizada para queda natural
  double _easeOutBounce(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    } else {
      t -= 2.625 / 2.75;
      return 7.5625 * t * t + 0.984375;
    }
  }

  /// Curva de animação suave para queda zen
  double _easeOutQuart(double t) {
    // ***** INÍCIO DA CORREÇÃO *****
    // Convertemos o resultado para double para satisfazer o tipo de retorno da função.
    return (1 - math.pow(1 - t, 4)).toDouble();
    // ***** FIM DA CORREÇÃO *****
  }

  /// Combina curvas para movimento natural e fluido
  double _combinedEasing(double t) {
    // Primeira metade: aceleração suave
    if (t <= 0.7) {
      final normalizedT = t / 0.7;
      return _easeOutQuart(normalizedT) * 0.85;
    }
    // Segunda metade: desaceleração com micro-bounce sutil
    else {
      final normalizedT = (t - 0.7) / 0.3;
      final bounceValue = _easeOutBounce(normalizedT) * 0.15;
      return 0.85 + bounceValue;
    }
  }

  /// Este método é chamado pelo ActionManager antes de 'perform'.
  @override
  void onStart(Map<String, dynamic> globals) {
    // Captura posições iniciais
    for (var piece in pieceDestinations.keys) {
      _initialPositions[piece] = piece.position.clone();
    }

    // Calcula distâncias para otimização de velocidade
    _calculateFallDistances();
  }

  /// Método principal de animação chamado a cada frame
  @override
  void perform(ListQueue<Action> actionQueue, Map<String, dynamic> globals) {
    final double dt = globals['dt'] as double? ?? (1 / 60);

    _elapsedTime += dt;
    final rawProgress = (_elapsedTime / _actualDuration).clamp(0.0, 1.0);

    // Aplica curva de animação natural
    final easedProgress = _combinedEasing(rawProgress);

    // Anima cada peça individualmente
    pieceDestinations.forEach((piece, destination) {
      final startPosition = _initialPositions[piece]!;
      final fallDistance = _fallDistances[piece]!;

      // Ajusta velocidade baseada na distância (peças que caem mais longe são ligeiramente mais rápidas)
      final distanceMultiplier = math.max(
        0.8,
        math.min(1.2, fallDistance / 100.0),
      );
      final adjustedProgress = (easedProgress * distanceMultiplier).clamp(
        0.0,
        1.0,
      );

      // Calcula posição interpolada com precisão
      final interpolatedPosition = Vector2(
        startPosition.x + (destination.x - startPosition.x) * adjustedProgress,
        startPosition.y + (destination.y - startPosition.y) * adjustedProgress,
      );

      // Aplica posição com otimização de performance
      piece.position.setFrom(interpolatedPosition);
    });

    // Finaliza animação quando completa
    if (rawProgress >= 1.0) {
      // Garante posicionamento exato no final
      pieceDestinations.forEach((piece, destination) {
        piece.position.setFrom(destination);
      });
      terminate();
    }
  }

  /// Método para debug e monitoramento de performance
  double get progress => (_elapsedTime / _actualDuration).clamp(0.0, 1.0);
  double get actualDuration => _actualDuration;
  int get animatingPiecesCount => pieceDestinations.length;
}

/// Ação de callback otimizada para execução imediata
class GameActionCallback extends Action {
  final void Function() _callback;

  GameActionCallback(this._callback);

  @override
  void perform(ListQueue<Action> actionQueue, Map<String, dynamic> globals) {
    _callback();
    terminate(); // Termina imediatamente após executar a função
  }
}

/// Ação especializada para animações de queda rápida (cenários especiais)
class FastFallAction extends AnimateFallsAction {
  FastFallAction({required Map<PetalPiece, Vector2> pieceDestinations})
    : super(
        pieceDestinations: pieceDestinations,
        baseDuration: 0.2, // 50% mais rápido para situações especiais
      );

  @override
  double _combinedEasing(double t) {
    // Curva mais agressiva para quedas rápidas
    return _easeOutQuart(t);
  }
}

/// Ação para animações de preenchimento do topo (mais suaves)
class TopFillAction extends AnimateFallsAction {
  TopFillAction({required Map<PetalPiece, Vector2> pieceDestinations})
    : super(
        pieceDestinations: pieceDestinations,
        baseDuration: 0.25, // Ligeiramente mais rápido que o padrão
      );

  @override
  double _combinedEasing(double t) {
    // Curva mais suave para preenchimento
    return math.sin(t * math.pi / 2); // Sine ease-out
  }
}
