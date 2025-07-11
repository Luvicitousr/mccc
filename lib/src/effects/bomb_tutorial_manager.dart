import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bomb_tutorial_overlay.dart';

/// 🎓 Gerenciador de Tutorial da Bomba com Flag Persistente
///
/// Responsável por:
/// 1. Armazenar flag booleana no armazenamento do dispositivo
/// 2. Verificar flag quando jogador encontra bomba pela primeira vez
/// 3. Exibir tutorial apenas se flag for false/não definida
/// 4. Definir flag como true após mostrar tutorial uma vez
/// 5. Persistir flag entre sessões do app
/// 6. Resetar apenas se app for desinstalado
class BombTutorialManager {

  // A única chave que precisamos para controlar o tutorial.
  static const String _tutorialShownKey = 'bomb_tutorial_has_been_shown';

  // Padrão Singleton para garantir uma única instância.
  BombTutorialManager._privateConstructor();
  static final BombTutorialManager instance = BombTutorialManager._privateConstructor();

  SharedPreferences? _prefs;

  // 1. Método de inicialização. Deve ser chamado no main.dart.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      final hasBeenShown = _prefs?.getBool(_tutorialShownKey) ?? false;
      print("[BombTutorialManager] Inicializado. Tutorial já foi mostrado? $hasBeenShown");
    }
  }

  // 2. Um único método para verificar se o tutorial deve ser exibido.
  // Retorna 'true' se o tutorial nunca foi mostrado antes.
  bool shouldShowTutorial() {
    if (_prefs == null) {
      if (kDebugMode) {
        print("[BombTutorialManager] SharedPreferences não inicializado. Tutorial não será mostrado.");
      }
      return false;
    }
    // A condição é simples: mostre o tutorial se a flag for 'false' ou nula.
    return !(_prefs!.getBool(_tutorialShownKey) ?? false);
  }

  // 3. Um único método para marcar o tutorial como visto permanentemente.
  Future<void> markTutorialAsShown() async {
    if (_prefs == null) return;

    await _prefs!.setBool(_tutorialShownKey, true);
    if (kDebugMode) {
      print("[BombTutorialManager] ✅ Tutorial marcado como visto permanentemente.");
    }
  }

  // 4. (Opcional) Função de debug para resetar a flag durante os testes.
  Future<void> resetForDebug() async {
    if (kDebugMode && _prefs != null) {
      await _prefs!.remove(_tutorialShownKey);
      print("[BombTutorialManager] 🔄 Flag do tutorial resetada para testes.");
    }
  }
  static const String _firstBombEncounteredKey = 'first_bomb_encountered';

  bool _isInitialized = false;

  /// 🔍 Verifica se o tutorial já foi mostrado
  Future<bool> hasTutorialBeenShown() async {
    await _ensureInitialized();

    try {
      final shown = _prefs?.getBool(_tutorialShownKey) ?? false;
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Tutorial já foi mostrado: $shown");
      }
      return shown;
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Erro ao verificar flag do tutorial: $e");
      }
      return false; // Assume que não foi mostrado em caso de erro
    }
  }

  /// 🎯 Verifica se a primeira bomba já foi encontrada
  Future<bool> hasFirstBombBeenEncountered() async {
    await _ensureInitialized();

    try {
      final encountered = _prefs?.getBool(_firstBombEncounteredKey) ?? false;
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Primeira bomba já encontrada: $encountered");
      }
      return encountered;
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Erro ao verificar flag da primeira bomba: $e");
      }
      return false;
    }
  }

  /// 🎯 Marca que a primeira bomba foi encontrada
  Future<void> markFirstBombEncountered() async {
    await _ensureInitialized();

    try {
      await _prefs?.setBool(_firstBombEncounteredKey, true);
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] 🎯 Primeira bomba marcada como encontrada");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Erro ao marcar primeira bomba: $e");
      }
    }
  }

  /// 🎬 Processa encontro com bomba e decide se mostra tutorial
  ///
  /// Este método deve ser chamado quando:
  /// - Uma bomba é criada a partir de combinação de 5+ peças
  /// - O jogador encontra uma bomba pela primeira vez
  Future<bool> processBombEncounter() async {
    try {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] 💣 Processando encontro com bomba...");
      }

      // Verifica se deve mostrar tutorial
      final shouldShow = await shouldShowTutorial();

      if (shouldShow) {
        // Marca que a primeira bomba foi encontrada
        await markFirstBombEncountered();

        if (kDebugMode) {
          print("[BOMB_TUTORIAL] 🎓 Tutorial será exibido!");
        }

        return true; // Deve mostrar tutorial
      } else {
        // Apenas marca que encontrou bomba (se ainda não marcou)
        final alreadyEncountered = await hasFirstBombBeenEncountered();
        if (!alreadyEncountered) {
          await markFirstBombEncountered();
        }

        if (kDebugMode) {
          print(
              "[BOMB_TUTORIAL] ⏭️ Tutorial não será exibido (já foi mostrado ou condições não atendidas)");
        }

        return false; // Não deve mostrar tutorial
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Erro ao processar encontro com bomba: $e");
      }
      return false;
    }
  }

  /// 🎯 Completa o processo do tutorial
  ///
  /// Deve ser chamado quando o tutorial é fechado/completado
  Future<void> completeTutorial() async {
    try {
      await markTutorialAsShown();

      if (kDebugMode) {
        print("[BOMB_TUTORIAL] 🎉 Tutorial completado e marcado como mostrado");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Erro ao completar tutorial: $e");
      }
    }
  }

  /// 🔧 Reset para debug/teste (NÃO usar em produção)
  Future<void> resetTutorialFlags() async {
    if (!kDebugMode) {
      print("[BOMB_TUTORIAL] ⚠️ Reset só é permitido em modo debug");
      return;
    }

    await _ensureInitialized();

    try {
      await _prefs?.remove(_tutorialShownKey);
      await _prefs?.remove(_firstBombEncounteredKey);

      if (kDebugMode) {
        print("[BOMB_TUTORIAL] 🔄 Flags do tutorial resetadas (DEBUG)");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Erro ao resetar flags: $e");
      }
    }
  }

  /// 📊 Obtém status detalhado para debug
  Future<Map<String, dynamic>> getDebugStatus() async {
    if (!kDebugMode) return {};

    try {
      return {
        'tutorial_shown': await hasTutorialBeenShown(),
        'first_bomb_encountered': await hasFirstBombBeenEncountered(),
        'should_show_tutorial': await shouldShowTutorial(),
        'is_initialized': _isInitialized,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🔒 Garante que o gerenciador está inicializado
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      throw Exception('BombTutorialManager não pôde ser inicializado');
    }
  }
}

/// 🎭 Extensão para integração com BombEffectsManager
extension BombTutorialIntegration on BombTutorialManager {
  /// 🎬 Mostra tutorial com callback de conclusão
  Future<void> showTutorialWithCallback({
    required Function(BombTutorialOverlay) addOverlay,
    required Function(BombTutorialOverlay) removeOverlay,
  }) async {
    try {
      late final BombTutorialOverlay tutorial;

      tutorial = BombTutorialOverlay(
        onDismiss: () async {
          // Remove overlay
          removeOverlay(tutorial);

          // Marca tutorial como completado
          await completeTutorial();

          if (kDebugMode) {
            print("[BOMB_TUTORIAL] Tutorial fechado e marcado como completado");
          }
        },
      );

      // Adiciona overlay
      addOverlay(tutorial);

      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Tutorial exibido com callback de conclusão");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[BOMB_TUTORIAL] Erro ao mostrar tutorial: $e");
      }
    }
  }
}
