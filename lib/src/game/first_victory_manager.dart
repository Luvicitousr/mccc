// lib/game/first_victory_manager.dart

import 'package:shared_preferences/shared_preferences.dart';

class FirstVictoryManager {
  // Chave para salvar a informação no dispositivo
  static const String _levelOneVictoryKey = 'has_seen_level_one_victory';

  // Padrão Singleton para garantir uma única instância do gerenciador
  FirstVictoryManager._privateConstructor();
  static final FirstVictoryManager instance =
      FirstVictoryManager._privateConstructor();

  SharedPreferences? _prefs;

  // Método de inicialização para ser chamado no início do app
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Verifica se o painel de vitória do nível 1 deve ser mostrado.
  /// Retorna 'true' se NUNCA foi mostrado antes.
  bool shouldShowLevelOneVictoryPanel() {
    // Se as preferências não foram carregadas, não mostre por segurança.
    if (_prefs == null) return false;

    // Lê o valor booleano. Se a chave não existir (primeira vez), retorna 'false'.
    // A lógica é invertida: se 'getBool' for false (não viu), a função retorna true (deve mostrar).
    return !(_prefs!.getBool(_levelOneVictoryKey) ?? false);
  }

  /// Marca que o painel de vitória do nível 1 já foi visto.
  Future<void> markLevelOneVictoryPanelAsSeen() async {
    await _prefs?.setBool(_levelOneVictoryKey, true);
  }
}
