import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'bomb_creation_overlay.dart';
import 'bomb_explosion_overlay.dart';
import 'bomb_tutorial_overlay.dart';
import 'bomb_tutorial_manager.dart';

/// 🎮 Gerenciador de Efeitos da Bomba - VERSÃO COM TUTORIAL IMEDIATO
/// ✅ NOVA FUNCIONALIDADE: Tutorial exibido imediatamente após criação da bomba
/// - Tutorial aparece assim que a animação de criação termina
/// - Bloqueia interação até o tutorial ser concluído
/// - Controle inteligente de quando mostrar tutorial
class BombEffectsManager {
  final BuildContext context;
  final Function(Widget) addOverlay;
  final Function(Widget) removeOverlay;

  // Controle de estado
  final List<Widget> _activeOverlays = [];

  // ✅ NOVO: Gerenciador de tutorial persistente
  final BombTutorialManager _tutorialManager = BombTutorialManager.instance;

  // ✅ NOVO: Controle de bloqueio de interação
  bool _isInteractionBlocked = false;

  BombEffectsManager({
    required this.context,
    required this.addOverlay,
    required this.removeOverlay,
  }) {
    // Inicializa o gerenciador de tutorial
    _initializeTutorialManager();
  }

  /// 🚀 Inicializa o gerenciador de tutorial
  Future<void> _initializeTutorialManager() async {
    try {
      await _tutorialManager.initialize();

      if (kDebugMode) {
        final status = await _tutorialManager.getDebugStatus();
        print("[BOMB_EFFECTS] Status do tutorial: $status");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] Erro ao inicializar gerenciador de tutorial: $e");
      }
    }
  }

  /// 🎯 Processa criação de bomba com tutorial imediato
  ///
  /// ✅ NOVA IMPLEMENTAÇÃO: Tutorial exibido imediatamente após animação
  /// Este método deve ser chamado quando uma bomba é criada
  /// a partir de uma combinação de 5+ peças
  Future<void> processBombCreationWithImmediateTutorial(Offset position) async {
    try {
      if (kDebugMode) {
        print(
            "[BOMB_EFFECTS] 🎯 Processando criação de bomba com tutorial imediato");
      }

      // 1. Verifica se deve mostrar tutorial ANTES da animação
      final shouldShowTutorial = await _tutorialManager.processBombEncounter();

      if (kDebugMode) {
        print("[BOMB_EFFECTS] 🤔 Deve mostrar tutorial: $shouldShowTutorial");
      }

      // 2. Exibe efeito de criação da bomba
      await _showBombCreationWithCallback(position, () async {
        // ✅ CALLBACK EXECUTADO QUANDO ANIMAÇÃO TERMINA
        if (shouldShowTutorial) {
          if (kDebugMode) {
            print(
                "[BOMB_EFFECTS] 🎓 Exibindo tutorial imediatamente após criação");
          }

          // 3. Bloqueia interação do jogo
          _blockGameInteraction();

          // 4. Mostra tutorial imediatamente
          await _showImmediateTutorial();

          // 5. Desbloqueia interação após tutorial
          _unblockGameInteraction();
        }
      });

      if (kDebugMode) {
        print("[BOMB_EFFECTS] ✅ Criação de bomba processada com tutorial");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao processar criação de bomba: $e");
      }

      // Garante que a interação seja desbloqueada em caso de erro
      _unblockGameInteraction();
    }
  }

  /// 🎇 Exibe efeito de criação da bomba com callback
  Future<void> _showBombCreationWithCallback(
      Offset position, VoidCallback onComplete) async {
    try {
      late final BombCreationOverlay creation;

      creation = BombCreationOverlay(
        position: position,
        onComplete: () {
          // Remove overlay
          _removeOverlay(creation);

          // ✅ EXECUTA CALLBACK QUANDO ANIMAÇÃO TERMINA
          onComplete();
        },
      );

      _addOverlay(creation);

      if (kDebugMode) {
        print("[BOMB_EFFECTS] 🎇 Efeito de criação da bomba iniciado");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao exibir criação: $e");
      }

      // Executa callback mesmo em caso de erro
      onComplete();
    }
  }

  /// 🎓 Mostra tutorial imediato com bloqueio de interação
  Future<void> _showImmediateTutorial() async {
    try {
      // Cria uma barreira que bloqueia toda interação
      late final Widget tutorialBarrier;

      tutorialBarrier = _buildTutorialBarrier(() async {
        // Remove barreira quando tutorial é fechado
        _removeOverlay(tutorialBarrier);

        // Marca tutorial como completado
        await _tutorialManager.completeTutorial();

        if (kDebugMode) {
          print("[BOMB_EFFECTS] 🎓 Tutorial imediato concluído");
        }
      });

      // Adiciona barreira que cobre toda a tela
      _addOverlay(tutorialBarrier);

      if (kDebugMode) {
        print("[BOMB_EFFECTS] 🛡️ Tutorial imediato exibido com bloqueio");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao mostrar tutorial imediato: $e");
      }
    }
  }

  /// 🛡️ Constrói barreira de tutorial que bloqueia toda interação
  Widget _buildTutorialBarrier(VoidCallback onDismiss) {
    return Positioned.fill(
      child: Container(
        // ✅ BARREIRA COMPLETA: Cobre toda a tela
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent, // Transparente mas captura toques
        child: Stack(
          children: [
            // Fundo que absorve todos os toques
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // Absorve toques sem fazer nada
                onPanStart: (_) {}, // Absorve gestos
                onPanUpdate: (_) {}, // Absorve gestos
                onPanEnd: (_) {}, // Absorve gestos
                child: Container(
                  color: Colors.black.withOpacity(
                      0.01), // Quase transparente mas captura toques
                ),
              ),
            ),

            // Tutorial sobreposto
            BombTutorialOverlay(
              onDismiss: onDismiss,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔒 Bloqueia interação do jogo
  void _blockGameInteraction() {
    _isInteractionBlocked = true;

    if (kDebugMode) {
      print("[BOMB_EFFECTS] 🔒 Interação do jogo bloqueada para tutorial");
    }
  }

  /// 🔓 Desbloqueia interação do jogo
  void _unblockGameInteraction() {
    _isInteractionBlocked = false;

    if (kDebugMode) {
      print("[BOMB_EFFECTS] 🔓 Interação do jogo desbloqueada");
    }
  }

  /// 🎯 Método legado mantido para compatibilidade
  ///
  /// ⚠️ DEPRECIADO: Use processBombCreationWithImmediateTutorial() ao invés deste método
  @Deprecated(
      'Use processBombCreationWithImmediateTutorial() para controle automático do tutorial')
  Future<void> processBombCreation(Offset position) async {
    if (kDebugMode) {
      print(
          "[BOMB_EFFECTS] ⚠️ Método processBombCreation() está depreciado. Use processBombCreationWithImmediateTutorial()");
    }

    // Chama o novo método para manter compatibilidade
    await processBombCreationWithImmediateTutorial(position);
  }

  /// 🎯 Exibe tutorial da bomba (MÉTODO LEGADO - mantido para compatibilidade)
  ///
  /// ⚠️ DEPRECIADO: Use processBombCreationWithImmediateTutorial() ao invés deste método
  @Deprecated(
      'Use processBombCreationWithImmediateTutorial() para controle automático do tutorial')
  void showBombTutorial() {
    if (kDebugMode) {
      print(
          "[BOMB_EFFECTS] ⚠️ Método showBombTutorial() está depreciado. Use processBombCreationWithImmediateTutorial()");
    }

    // Chama o novo método para manter compatibilidade
    processBombCreationWithImmediateTutorial(Offset.zero);
  }

  /// 💥 Exibe efeito de explosão da bomba
  void showBombExplosion(Offset center, double radius) {
    try {
      // Validação de parâmetros
      final validRadius = radius.clamp(10.0, 500.0);

      late final BombExplosionOverlay explosion;

      explosion = BombExplosionOverlay(
        center: center,
        radius: validRadius,
        onComplete: () => _removeOverlay(explosion),
      );

      _addOverlay(explosion);

      if (kDebugMode) {
        print("[BOMB_EFFECTS] 💥 Efeito de explosão exibido");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao exibir explosão: $e");
      }
    }
  }

  /// 🎇 Exibe efeito de criação da bomba (método interno legado)
  void showBombCreation(Offset position) {
    try {
      late final BombCreationOverlay creation;

      creation = BombCreationOverlay(
        position: position,
        onComplete: () => _removeOverlay(creation),
      );

      _addOverlay(creation);

      if (kDebugMode) {
        print(
            "[BOMB_EFFECTS] 🎇 Efeito de criação da bomba exibido (método legado)");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao exibir criação: $e");
      }
    }
  }

  /// ✨ Exibe efeito de reação em cadeia
  void showChainReaction(List<Offset> bombPositions) {
    try {
      // Implementação futura: efeito visual de conexão entre bombas
      if (kDebugMode) {
        print(
            "[BOMB_EFFECTS] ✨ Efeito de reação em cadeia para ${bombPositions.length} bombas");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao exibir reação em cadeia: $e");
      }
    }
  }

  /// 🧹 Limpa todos os efeitos ativos
  void clearAllEffects() {
    try {
      final overlays = List<Widget>.from(_activeOverlays);
      for (final overlay in overlays) {
        _removeOverlay(overlay);
      }

      // ✅ NOVO: Desbloqueia interação ao limpar efeitos
      _unblockGameInteraction();

      if (kDebugMode) {
        print("[BOMB_EFFECTS] 🧹 Todos os efeitos foram limpos");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao limpar efeitos: $e");
      }
      // Força limpeza da lista em caso de erro
      _activeOverlays.clear();
      _unblockGameInteraction();
    }
  }

  /// ➕ Adiciona overlay à tela
  void _addOverlay(Widget overlay) {
    try {
      _activeOverlays.add(overlay);
      addOverlay(overlay);
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao adicionar overlay: $e");
      }
    }
  }

  /// ➖ Remove overlay da tela
  void _removeOverlay(Widget overlay) {
    try {
      _activeOverlays.remove(overlay);
      removeOverlay(overlay);
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_EFFECTS] ❌ Erro ao remover overlay: $e");
      }
    }
  }

  /// 🔧 Métodos de debug (apenas em modo debug)

  /// Reset do tutorial para testes
  Future<void> resetTutorialForDebug() async {
    if (!kDebugMode) return;

    await _tutorialManager.resetTutorialFlags();
    print("[BOMB_EFFECTS] 🔄 Tutorial resetado para debug");
  }

  /// Status do tutorial para debug
  Future<Map<String, dynamic>> getTutorialDebugStatus() async {
    if (!kDebugMode) return {};

    return await _tutorialManager.getDebugStatus();
  }

  /// 📊 Getters para estado
  int get activeOverlaysCount => _activeOverlays.length;
  bool get isInteractionBlocked => _isInteractionBlocked;

  /// ✅ NOVO: Getter para status do tutorial
  Future<bool> get hasTutorialBeenShown =>
      _tutorialManager.hasTutorialBeenShown();
  Future<bool> get shouldShowTutorial => _tutorialManager.shouldShowTutorial();
}
