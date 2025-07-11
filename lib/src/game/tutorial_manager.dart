import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 🎓 Gerenciador de Tutoriais
///
/// Controla quais tutoriais de nível já foram exibidos ao jogador,
/// garantindo que eles apareçam apenas na primeira vez.
/// Usa SharedPreferences para persistência de dados.
class TutorialManager {
  static TutorialManager? _instance;
  static TutorialManager get instance => _instance ??= TutorialManager._();
  TutorialManager._();

  late SharedPreferences _prefs;

  // Chave base para os tutoriais no SharedPreferences.
  static const String _tutorialKeyPrefix = 'tutorial_shown_for_level_';

  /// Inicializa o gerenciador, carregando a instância do SharedPreferences.
  /// Deve ser chamado uma vez na inicialização do aplicativo.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print("[TUTORIAL_MANAGER] Gerenciador de tutoriais inicializado.");
    }
  }

  /// Verifica se o tutorial para um determinado nível deve ser exibido.
  /// Retorna `true` se o tutorial ainda não foi marcado como visto.
  Future<bool> shouldShowTutorialForLevel(int levelNumber) async {
    // Por padrão, retorna 'true' se a chave não existir,
    // garantindo que o tutorial seja mostrado na primeira vez.
    final key = '$_tutorialKeyPrefix$levelNumber';
    final hasBeenShown = _prefs.getBool(key) ?? false;
    if (kDebugMode) {
      print(
        "[TUTORIAL_MANAGER] Verificando tutorial para nível $levelNumber. Já mostrado: $hasBeenShown",
      );
    }
    return !hasBeenShown;
  }

  /// Marca o tutorial de um nível como exibido.
  /// Isso impede que ele seja mostrado novamente.
  Future<void> markTutorialAsShown(int levelNumber) async {
    final key = '$_tutorialKeyPrefix$levelNumber';
    await _prefs.setBool(key, true);
    if (kDebugMode) {
      print(
        "[TUTORIAL_MANAGER] Tutorial para nível $levelNumber marcado como visto.",
      );
    }
  }

  /// [DEBUG] Reseta o estado de um tutorial, fazendo com que ele apareça novamente.
  /// Útil para testes.
  Future<void> resetTutorialFlagForDebug(int levelNumber) async {
    if (kDebugMode) {
      final key = '$_tutorialKeyPrefix$levelNumber';
      await _prefs.remove(key);
      print(
        "[TUTORIAL_MANAGER] [DEBUG] Flag do tutorial para nível $levelNumber resetada.",
      );
    }
  }

  /// [DEBUG] Reseta todas as flags de tutorial.
  Future<void> resetAllTutorialFlagsForDebug() async {
    if (kDebugMode) {
      final keys = _prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith(_tutorialKeyPrefix)) {
          await _prefs.remove(key);
        }
      }
      print(
        "[TUTORIAL_MANAGER] [DEBUG] Todas as flags de tutorial foram resetadas.",
      );
    }
  }
}
