import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart'; // Adicionado para acesso ao BLoC

import '../ui/smooth_page_transitions.dart';
import 'level_manager.dart';
import 'candy_game.dart';
import '../ui/game_page.dart';
import '../ui/game_state_manager.dart';
import '../engine/level_definition.dart';
import '../bloc/game_bloc.dart'; // Adicionado para despachar eventos

/// � Lançador de Jogo - Sistema Modular (VERSÃO REATORADA)
///
/// ✅ MUDANÇAS APLICADAS:
/// - Não cria mais a instância do CandyGame diretamente.
/// - Despacha um evento para o GameBloc para carregar o nível.
/// - Navega para a GamePage sem parâmetros.
/// - O método de preview foi ajustado para o novo construtor.
class GameLauncher {
  static GameLauncher? _instance;
  static GameLauncher get instance => _instance ??= GameLauncher._();

  GameLauncher._();

  /// 🎮 Inicia um nível específico
  Future<void> launchLevel(BuildContext context, int levelNumber) async {
    if (kDebugMode) {
      print("[GAME_LAUNCHER] 🚀 Iniciando nível $levelNumber");
    }

    try {
      if (!LevelManager.instance.isLevelUnlocked(levelNumber)) {
        if (kDebugMode) {
          print("[GAME_LAUNCHER] 🔒 Nível $levelNumber está bloqueado");
        }
        _showLevelLockedDialog(context, levelNumber);
        return;
      }
      
      // ✅ CORREÇÃO: Despacha um evento para o BLoC carregar o nível.
      // A GamePage irá ouvir o estado do BLoC e construir o jogo.
      context.read<GameBloc>().add(GameLevelSelected(levelNumber));

      // ✅ CORREÇÃO: Navega para a GamePage sem passar o jogo como parâmetro.
      await Navigator.of(context).push(
        SmoothPageTransitions.zenTransition(
          const GamePage(),
        ),
      );

      if (kDebugMode) {
        print("[GAME_LAUNCHER] ✅ Jogo iniciado com sucesso");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("[GAME_LAUNCHER] ❌ Erro ao iniciar nível $levelNumber: $e");
        print("[GAME_LAUNCHER] Stack trace: $stackTrace");
      }
      _showErrorDialog(context, levelNumber, e.toString());
    }
  }

  /// 🎯 Cria jogo para preview (sem iniciar)
  CandyGame createGamePreview(int levelNumber) {
    final levelDefinition = LevelManager.instance.loadLevel(levelNumber);
    
    // ✅ CORREÇÃO: Passa uma função vazia para o onGameOver,
    // já que um preview nunca chegará ao fim.
    return CandyGame(
      level: levelDefinition,
      onGameOver: () {
        // Callback vazio para o modo de preview.
      },
    );
  }

  // ... O restante da classe (launchNextLevel, restartLevel, etc.) continua igual ...

  /// 🎯 Inicia o próximo nível disponível
  Future<void> launchNextLevel(BuildContext context) async {
    final nextLevel = LevelManager.instance.getNextAvailableLevel();
    await launchLevel(context, nextLevel);
  }

  /// 🔄 Reinicia o nível atual
  Future<void> restartLevel(BuildContext context, int levelNumber) async {
    if (kDebugMode) {
      print("[GAME_LAUNCHER] 🔄 Reiniciando nível $levelNumber");
    }
    LevelManager.instance.clearCache();
    await launchLevel(context, levelNumber);
  }

  /// 🎮 Continua do último nível jogado
  Future<void> continueGame(BuildContext context) async {
    final lastLevel = LevelManager.instance.getNextAvailableLevel();
    if (kDebugMode) {
      print("[GAME_LAUNCHER] ⏭️ Continuando do nível $lastLevel");
    }
    await launchLevel(context, lastLevel);
  }

  /// 🔒 Mostra diálogo de nível bloqueado
  void _showLevelLockedDialog(BuildContext context, int levelNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Nível Bloqueado'),
          ],
        ),
        content: Text(
          'O nível $levelNumber ainda não está disponível.\n\n'
          'Complete os níveis anteriores para desbloqueá-lo!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              launchNextLevel(context);
            },
            child: const Text('Ir para Último Nível'),
          ),
        ],
      ),
    );
  }

  /// ❌ Mostra diálogo de erro
  void _showErrorDialog(BuildContext context, int levelNumber, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro ao Carregar'),
          ],
        ),
        content: Text(
          'Não foi possível carregar o nível $levelNumber.\n\n'
          'Erro: $error',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          if (kDebugMode)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                launchLevel(context, levelNumber);
              },
              child: const Text('Tentar Novamente'),
            ),
        ],
      ),
    );
  }
  
  // ... O resto da classe e as extensões continuam aqui ...

  /// 📊 Obtém informações do nível
  LevelInfo getLevelInfo(int levelNumber) {
    final levelDefinition = LevelManager.instance.loadLevel(levelNumber);
    final stats = LevelManager.instance.getLevelStats(levelNumber);
    final isUnlocked = LevelManager.instance.isLevelUnlocked(levelNumber);

    return LevelInfo(
      definition: levelDefinition,
      stats: stats,
      isUnlocked: isUnlocked,
    );
  }

  /// 🎮 Verifica se pode iniciar um nível
  bool canLaunchLevel(int levelNumber) {
    return LevelManager.instance.isLevelUnlocked(levelNumber);
  }

  /// 📊 Obtém lista de níveis disponíveis
  List<int> getAvailableLevels() {
    final maxLevel = LevelManager.instance.getNextAvailableLevel();
    return List.generate(maxLevel, (index) => index + 1);
  }

  /// 🔧 Métodos de debug

  /// 🐛 Força desbloqueio de nível (apenas debug)
  Future<void> debugUnlockLevel(int levelNumber) async {
    if (!kDebugMode) return;
    final gameState = GameStateManager.instance;
    await gameState.unlockLevel(levelNumber);
    if (kDebugMode) {
      print("[GAME_LAUNCHER] 🔓 DEBUG: Nível $levelNumber desbloqueado");
    }
  }

  /// 🐛 Completa nível automaticamente (apenas debug)
  Future<void> debugCompleteLevel(int levelNumber, {int stars = 3}) async {
    if (!kDebugMode) return;
    final gameState = GameStateManager.instance;
    await gameState.completeLevel(levelNumber, stars: stars);
    if (kDebugMode) {
      print(
          "[GAME_LAUNCHER] ⭐ DEBUG: Nível $levelNumber completado com $stars estrelas");
    }
  }

  /// 🐛 Reset de progresso (apenas debug)
  Future<void> debugResetProgress() async {
    if (!kDebugMode) return;
    final gameState = GameStateManager.instance;
    await gameState.resetProgress();
    if (kDebugMode) {
      print("[GAME_LAUNCHER] 🔄 DEBUG: Progresso resetado");
    }
  }
}

/// 📊 Informações completas de um nível
class LevelInfo {
  final LevelDefinition definition;
  final LevelStats? stats;
  final bool isUnlocked;

  LevelInfo({
    required this.definition,
    required this.stats,
    required this.isUnlocked,
  });

  /// Verifica se o nível foi completado
  bool get isCompleted => stats != null && stats!.attempts > 0;

  /// Obtém número de estrelas
  int get stars {
    if (!isCompleted) return 0;
    final bestMoves = stats!.bestMoves;
    if (bestMoves == null) return 1;
    final targetMoves = definition.moves;
    final efficiency = (targetMoves - bestMoves) / targetMoves;
    if (efficiency >= 0.7) return 3;
    if (efficiency >= 0.4) return 2;
    return 1;
  }

  /// Obtém cor baseada na dificuldade
  Color get difficultyColor => definition.difficulty.color;

  /// Obtém ícones das características especiais
  List<IconData> get featureIcons {
    return definition.specialFeatures.map((feature) => feature.icon).toList();
  }
}

/// 🔧 Extensões para facilitar o uso
extension GameLauncherContext on BuildContext {
  /// Inicia um nível específico
  Future<void> launchLevel(int levelNumber) async {
    await GameLauncher.instance.launchLevel(this, levelNumber);
  }

  /// Inicia o próximo nível
  Future<void> launchNextLevel() async {
    await GameLauncher.instance.launchNextLevel(this);
  }

  /// Continua o jogo
  Future<void> continueGame() async {
    await GameLauncher.instance.continueGame(this);
  }

  /// Reinicia um nível
  Future<void> restartLevel(int levelNumber) async {
    await GameLauncher.instance.restartLevel(this, levelNumber);
  }
}

/// 🎮 Widget para botão de nível
class LevelButton extends StatelessWidget {
  final int levelNumber;
  final VoidCallback? onPressed;
  final bool showPreview;

  const LevelButton({
    super.key,
    required this.levelNumber,
    this.onPressed,
    this.showPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final levelInfo = GameLauncher.instance.getLevelInfo(levelNumber);

    return Card(
      elevation: levelInfo.isUnlocked ? 4 : 2,
      child: InkWell(
        onTap: levelInfo.isUnlocked
            ? (onPressed ?? () => context.launchLevel(levelNumber))
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$levelNumber',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: levelInfo.isUnlocked ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                levelInfo.definition.title,
                style: TextStyle(
                  fontSize: 14,
                  color: levelInfo.isUnlocked ? Colors.black54 : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (levelInfo.isUnlocked) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < levelInfo.stars ? Icons.star : Icons.star_border,
                      size: 16,
                      color:
                          index < levelInfo.stars ? Colors.amber : Colors.grey,
                    );
                  }),
                ),
              ] else ...[
                const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
              if (levelInfo.isUnlocked &&
                  levelInfo.featureIcons.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: levelInfo.featureIcons.take(3).map((icon) {
                    return Icon(
                      icon,
                      size: 12,
                      color: levelInfo.difficultyColor,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
�