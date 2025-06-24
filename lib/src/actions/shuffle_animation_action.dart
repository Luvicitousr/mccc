// lib/src/actions/shuffle_animation_action.dart

import 'dart:math';
import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import '../engine/action_manager.dart';
import '../engine/petal_piece.dart';
import '../game/candy_game.dart';

/// Ação responsável por embaralhar o tabuleiro quando não há movimentos válidos
/// Versão corrigida que previne erros de inicialização múltipla
class ShuffleAnimationAction extends Action {
  final CandyGame game;

  // 🔧 CORREÇÃO CRÍTICA: Usar nullable ao invés de late para prevenir erro de inicialização
  double? _startTime;
  bool _isInitialized = false;
  bool _shuffleCompleted = false;

  // Configurações da animação
  static const double animationDuration = 2.0; // 2 segundos de animação
  static const double shuffleDelay =
      0.5; // Delay antes de iniciar o embaralhamento

  ShuffleAnimationAction({required this.game});

  @override
  void onStart(Map<String, dynamic> globals) {
    // 🔧 CORREÇÃO: Verificação para prevenir inicialização múltipla
    if (_isInitialized) {
      if (kDebugMode) {
        print("[SHUFFLE] ⚠️ Tentativa de inicialização múltipla bloqueada");
      }
      return;
    }

    _isInitialized = true;
    _startTime = 0.0;
    _shuffleCompleted = false;

    if (kDebugMode) {
      print("[SHUFFLE] 🎲 Iniciando animação de embaralhamento...");
      print("[SHUFFLE] 📊 Duração total: ${animationDuration}s");
    }
  }

  @override
  void perform(ListQueue<Action> actionQueue, Map<String, dynamic> globals) {
    // 🔧 CORREÇÃO: Verificação de segurança para inicialização
    if (!_isInitialized || _startTime == null) {
      if (kDebugMode) {
        print("[SHUFFLE] ❌ Erro: Ação não inicializada corretamente");
      }
      terminate();
      return;
    }

    final double dt = globals['dt'] as double? ?? (1 / 60);
    _startTime = _startTime! + dt;

    // Fase 1: Delay inicial (0.5s)
    if (_startTime! < shuffleDelay) {
      _showShuffleWarning();
      return;
    }

    // Fase 2: Animação de embaralhamento (1.5s)
    if (_startTime! < animationDuration && !_shuffleCompleted) {
      _performShuffleAnimation();
      return;
    }

    // Fase 3: Finalização
    if (!_shuffleCompleted) {
      _completeShuffle();
      _shuffleCompleted = true;
    }

    // Termina a ação após completar o embaralhamento
    if (_startTime! >= animationDuration) {
      if (kDebugMode) {
        print("[SHUFFLE] ✅ Embaralhamento concluído com sucesso");
      }
      terminate();
    }
  }

  /// Mostra aviso visual de que o embaralhamento vai começar
  void _showShuffleWarning() {
    // Implementação futura: efeitos visuais de aviso
    // - Piscar bordas do tabuleiro
    // - Mostrar texto "Embaralhando..."
    // - Efeitos de partículas

    if (kDebugMode) {
      final progress = (_startTime! / shuffleDelay * 100).round();
      print("[SHUFFLE] ⏳ Preparando embaralhamento... $progress%");
    }
  }

  /// Executa a animação visual do embaralhamento
  void _performShuffleAnimation() {
    final animationProgress =
        (_startTime! - shuffleDelay) / (animationDuration - shuffleDelay);

    // Implementação futura: animações visuais
    // - Rotação das peças
    // - Efeitos de fade in/out
    // - Movimento suave das peças
    // - Partículas de "magia"

    if (kDebugMode) {
      final progress = (animationProgress * 100).round();
      if (progress % 20 == 0) {
        // Log a cada 20% para não spam
        print("[SHUFFLE] 🎭 Animando embaralhamento... $progress%");
      }
    }
  }

  /// Executa o embaralhamento real do tabuleiro
  void _completeShuffle() {
    if (kDebugMode) {
      print("[SHUFFLE] 🔄 Executando embaralhamento do tabuleiro...");
    }

    try {
      // Coleta todas as peças não-vazias e não-paredes
      final List<PetalPiece> shuffleablePieces = [];
      final List<int> shuffleableIndices = [];

      for (int i = 0; i < game.pieces.length; i++) {
        final piece = game.pieces[i];
        if (piece.type != PetalType.empty &&
            piece.type != PetalType.wall &&
            piece.type != PetalType.caged1 &&
            piece.type != PetalType.caged2) {
          shuffleablePieces.add(piece);
          shuffleableIndices.add(i);
        }
      }

      if (shuffleablePieces.isEmpty) {
        if (kDebugMode) {
          print("[SHUFFLE] ⚠️ Nenhuma peça disponível para embaralhar");
        }
        return;
      }

      // 🔧 CORREÇÃO: Embaralhamento seguro com verificação de limites
      final random = Random();
      final List<PetalType> shuffledTypes = shuffleablePieces
          .map((piece) => piece.type)
          .toList();

      // Embaralha os tipos usando algoritmo Fisher-Yates
      for (int i = shuffledTypes.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final temp = shuffledTypes[i];
        shuffledTypes[i] = shuffledTypes[j];
        shuffledTypes[j] = temp;
      }

      // Aplica os tipos embaralhados às peças
      for (int i = 0; i < shuffleableIndices.length; i++) {
        final pieceIndex = shuffleableIndices[i];
        if (pieceIndex >= 0 && pieceIndex < game.pieces.length) {
          game.pieces[pieceIndex].changeType(shuffledTypes[i]);
        }
      }

      if (kDebugMode) {
        print("[SHUFFLE] ✅ ${shuffleablePieces.length} peças embaralhadas");
        print("[SHUFFLE] 🎯 Verificando se há movimentos válidos...");
      }

      // Verifica se o embaralhamento criou movimentos válidos
      if (!game.hasValidMovesAvailable()) {
        if (kDebugMode) {
          print(
            "[SHUFFLE] ⚠️ Embaralhamento não criou movimentos válidos, tentando novamente...",
          );
        }
        _completeShuffle(); // Tenta embaralhar novamente
      } else {
        if (kDebugMode) {
          print(
            "[SHUFFLE] ✅ Movimentos válidos encontrados após embaralhamento",
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("[SHUFFLE] ❌ Erro durante embaralhamento: $e");
        print("[SHUFFLE] Stack trace: $stackTrace");
      }
      // Em caso de erro, força término da ação
      terminate();
    }
  }

  /// Método de limpeza quando a ação termina
  @override
  void terminate() {
    if (kDebugMode) {
      print("[SHUFFLE] 🏁 Finalizando ação de embaralhamento");
    }

    // Reset das variáveis para permitir nova execução se necessário
    _isInitialized = false;
    _startTime = null;
    _shuffleCompleted = false;

    super.terminate();
  }

  /// Getters para debug e monitoramento
  double get progress => _startTime != null
      ? (_startTime! / animationDuration).clamp(0.0, 1.0)
      : 0.0;
  bool get isAnimating => _isInitialized && !_shuffleCompleted;
  bool get isCompleted => _shuffleCompleted;
}

/// Extensão para adicionar métodos de embaralhamento ao CandyGame
extension ShuffleGameExtension on CandyGame {
  /// Força um embaralhamento imediato (para debug/testes)
  void forceShuffleBoard() {
    if (kDebugMode) {
      print("[GAME] 🎲 Embaralhamento forçado solicitado");
    }

    final shuffleAction = ShuffleAnimationAction(game: this);
    actionManager.push(shuffleAction);
  }

  /// Verifica se um embaralhamento está em andamento
  bool get isShuffling {
    return actionManager.isRunning() &&
        actionManager.toString().contains('ShuffleAnimationAction');
  }
}
