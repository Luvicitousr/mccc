import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../engine/petal_piece.dart';
import '../engine/level_definition.dart';
import '../game/enhanced_move_validation_system.dart';

/// 🎲 Gerenciador Inteligente de Shuffle
///
/// Responsável por:
/// 1. Detectar quando não há jogadas válidas
/// 2. Executar shuffle com animação
/// 3. Notificar o jogador sobre o processo
/// 4. Garantir que o resultado tenha jogadas válidas
class IntelligentShuffleManager {
  final LevelDefinition level;
  final List<PetalPiece> pieces;
  final VoidCallback? onShuffleComplete;
  final Function(String)? onStatusUpdate;

  bool _isShuffling = false;
  Timer? _shuffleTimer;

  IntelligentShuffleManager({
    required this.level,
    required this.pieces,
    this.onShuffleComplete,
    this.onStatusUpdate,
  });

  /// 🎯 Verifica se há jogadas válidas e executa shuffle se necessário
  Future<bool> checkAndShuffleIfNeeded() async {
    if (_isShuffling) {
      if (kDebugMode) {
        print(
            "[SHUFFLE_MANAGER] ⏸️ Shuffle já em andamento, ignorando solicitação");
      }
      return false;
    }

    final validationSystem = EnhancedMoveValidationSystem(
      level: level,
      pieces: pieces,
    );

    // Verifica se há jogadas válidas
    if (validationSystem.hasValidMovesAvailable()) {
      if (kDebugMode) {
        print(
            "[SHUFFLE_MANAGER] ✅ Jogadas válidas encontradas, shuffle não necessário");
      }
      return false;
    }

    if (kDebugMode) {
      print(
          "[SHUFFLE_MANAGER] 🚨 Nenhuma jogada válida encontrada, iniciando shuffle...");
    }

    // Executa o shuffle com animação
    return await _executeShuffleWithAnimation(validationSystem);
  }

  /// 🎬 Executa shuffle com animação e feedback visual
  Future<bool> _executeShuffleWithAnimation(
      EnhancedMoveValidationSystem validationSystem) async {
    _isShuffling = true;

    try {
      // Notifica início do shuffle
      _updateStatus("🎲 Embaralhando peças...");

      // Animação de preparação (peças tremulam)
      await _animateShufflePreparation();

      // Executa o shuffle inteligente
      _updateStatus("🔄 Reorganizando tabuleiro...");
      final shuffleResult = await validationSystem.executeIntelligentShuffle();

      if (shuffleResult.success) {
        // Animação de conclusão
        _updateStatus("✅ Novas jogadas disponíveis!");
        await _animateShuffleCompletion();

        if (kDebugMode) {
          print(
              "[SHUFFLE_MANAGER] ✅ Shuffle concluído com sucesso: ${shuffleResult.message}");
        }

        // Notifica conclusão
        onShuffleComplete?.call();

        return true;
      } else {
        _updateStatus("❌ Falha no embaralhamento");

        if (kDebugMode) {
          print(
              "[SHUFFLE_MANAGER] ❌ Falha no shuffle: ${shuffleResult.message}");
        }

        return false;
      }
    } catch (e) {
      _updateStatus("❌ Erro durante embaralhamento");

      if (kDebugMode) {
        print("[SHUFFLE_MANAGER] ❌ Erro durante shuffle: $e");
      }

      return false;
    } finally {
      _isShuffling = false;

      // Limpa status após delay
      Timer(const Duration(seconds: 2), () {
        _updateStatus("");
      });
    }
  }

  /// 🎭 Animação de preparação para o shuffle
  Future<void> _animateShufflePreparation() async {
    if (kDebugMode) {
      print("[SHUFFLE_MANAGER] 🎭 Iniciando animação de preparação...");
    }

    // Simula animação de tremulação das peças
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 200));

      // Aqui você pode adicionar lógica para fazer as peças tremularem
      // Por exemplo, alterando ligeiramente suas posições
      _animatePieceShake();
    }
  }

  /// 🎉 Animação de conclusão do shuffle
  Future<void> _animateShuffleCompletion() async {
    if (kDebugMode) {
      print("[SHUFFLE_MANAGER] 🎉 Iniciando animação de conclusão...");
    }

    // Simula animação de brilho ou destaque nas peças
    await Future.delayed(const Duration(milliseconds: 500));

    // Aqui você pode adicionar efeitos visuais de conclusão
    _animatePieceHighlight();
  }

  /// 📳 Simula tremulação das peças
  void _animatePieceShake() {
    // Implementação futura: fazer peças tremularem ligeiramente
    // Pode usar Transform.translate com valores pequenos e aleatórios

    if (kDebugMode) {
      print("[SHUFFLE_MANAGER] 📳 Animando tremulação das peças...");
    }
  }

  /// ✨ Simula destaque das peças
  void _animatePieceHighlight() {
    // Implementação futura: destacar peças com brilho ou mudança de cor temporária

    if (kDebugMode) {
      print("[SHUFFLE_MANAGER] ✨ Animando destaque das peças...");
    }
  }

  /// 📢 Atualiza status para o jogador
  void _updateStatus(String message) {
    onStatusUpdate?.call(message);

    if (kDebugMode && message.isNotEmpty) {
      print("[SHUFFLE_MANAGER] 📢 Status: $message");
    }
  }

  /// 🧹 Limpa recursos
  void dispose() {
    _shuffleTimer?.cancel();
    _isShuffling = false;
  }

  /// 📊 Getters para estado atual
  bool get isShuffling => _isShuffling;

  /// 🎯 Força um shuffle (para debug/teste)
  Future<bool> forceShuffle() async {
    if (kDebugMode) {
      print("[SHUFFLE_MANAGER] 🔧 Shuffle forçado solicitado");
    }

    final validationSystem = EnhancedMoveValidationSystem(
      level: level,
      pieces: pieces,
    );

    return await _executeShuffleWithAnimation(validationSystem);
  }
}

/// 🎨 Widget para exibir status do shuffle
class ShuffleStatusWidget extends StatefulWidget {
  final String message;
  final bool isVisible;

  const ShuffleStatusWidget({
    super.key,
    required this.message,
    required this.isVisible,
  });

  @override
  State<ShuffleStatusWidget> createState() => _ShuffleStatusWidgetState();
}

class _ShuffleStatusWidgetState extends State<ShuffleStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void didUpdateWidget(ShuffleStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && widget.message.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
