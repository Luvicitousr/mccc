import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';

import 'level_one_victory_panel.dart';
import '../effects/bomb_creation_overlay.dart';
import '../effects/bomb_tutorial_manager.dart';
import '../effects/bomb_tutorial_overlay.dart';
import '../game/candy_game.dart';
import '../ui/intelligent_shuffle_manager.dart';
import '../bloc/game_bloc.dart';
import 'zen_victory_panel.dart';
import 'widgets/zen_exit_dialog.dart'; // Ajuste o caminho se necessário
import 'smooth_page_transitions.dart';
import 'game_top_bar.dart';
import '../game/tutorial_manager.dart'; // ✅ Importa o gerenciador
import 'zen_level_tutorial.dart'; // ✅ Importa a nova tela de tutorial
import '../game/game_launcher.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final CandyGame _game;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final gameState = context.read<GameBloc>().state;
    if (gameState is! GameReady) {
      throw StateError(
        'GamePage foi chamada com um estado de BLoC inválido: $gameState',
      );
    }

    // ✅ CORREÇÃO APLICADA AQUI
    _game = CandyGame(
      level: gameState.level,
      // 1. O parâmetro 'onGameOver' é obrigatório e foi adicionado de volta.
      //    Pode ser vazio, pois a lógica de troca de tela agora está dentro do próprio jogo.
      onGameOver: () {
        if (kDebugMode) {
          print("Callback onGameOver da GamePage foi acionado.");
        }
      },
      // ✅ PASSO 5: Forneça as funções da GamePage para o CandyGame
      onRestart: _restartGame,
      onMenu: _handleMenu,
    );

    // ✅ LÓGICA PARA EXIBIR O TUTORIAL
    // Usamos addPostFrameCallback para garantir que o context está pronto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  /// Verifica se o tutorial deve ser mostrado e o exibe como um diálogo modal.
  Future<void> _checkAndShowTutorial() async {
    final tutorialManager = TutorialManager.instance;
    final shouldShow = await tutorialManager.shouldShowTutorialForLevel(
      _game.level.levelNumber,
    );

    // A verificação 'mounted' garante que o widget ainda está na árvore.
    if (shouldShow && mounted) {
      _game.pauseEngine(); // Pausa o jogo enquanto o tutorial está visível

      showDialog(
        context: context,
        barrierDismissible: false, // O jogador deve interagir com o tutorial
        barrierColor: Colors.black.withOpacity(0.7), // Fundo escurecido
        builder: (_) => ZenLevelTutorial(
          level: _game.level,
          onStartGame: () {
            // Marca o tutorial como visto para não aparecer novamente
            tutorialManager.markTutorialAsShown(_game.level.levelNumber);
            // Fecha o diálogo
            Navigator.of(context).pop();

            // Isso garante que o diálogo já foi completamente removido.
            Future.delayed(Duration.zero, () {
              if (mounted) {
                _game.resumeEngine();
              }
            });
          },
        ),
      );
    }
  }

  Future<void> _showExitConfirmationDialog() async {
    // Pausa o motor do jogo enquanto o diálogo estiver visível
    _game.pauseEngine();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Fundo mais imersivo
      builder: (BuildContext dialogContext) {
        // Usamos nosso widget personalizado!
        return ZenExitDialog(
          onCancel: () {
            // Ação para o botão "Continuar"
            Navigator.of(dialogContext).pop();
          },
          onConfirm: () {
            // Ação para o botão "Sim, Sair"
            Navigator.of(dialogContext).pop(); // Primeiro fecha o diálogo
            _handleMenu(); // Depois executa a lógica de saída
          },
        );
      },
    );

    // Retoma o motor do jogo após o diálogo ser fechado
    _game.resumeEngine();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PASSO 1: Envolva o Scaffold com WillPopScope.
    return WillPopScope(
      onWillPop: () async {
        // ✅ 5. Chame a mesma função de diálogo
        await _showExitConfirmationDialog();
        // Retorne 'false' para impedir a ação padrão de "pop" (voltar).
        // Sua função _handleMenu já cuida da navegação.
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // O Stack não é mais necessário se a GamePage só exibe o jogo.
        body: GameWidget(
          game: _game,
          overlayBuilderMap: {
            'movesPanel': (context, game) => GameTopBar(
              game: game as CandyGame,

              // ✅ 4. Passe a função para o GameTopBar
              onBackButtonPressed: _showExitConfirmationDialog,
            ),
            'objectivesPanel': (context, game) => Container(),
            'victoryPanel': (context, game) => ZenVictoryPanel(
              game: game as CandyGame,
              onContinue: () => _handleContinue(),
              onMenu: () => _handleMenu(),
            ),
            'shuffleStatus': (context, game) {
              final candyGame = game as CandyGame;
              return ValueListenableBuilder<String>(
                valueListenable: candyGame.shuffleStatusNotifier,
                builder: (context, message, child) {
                  return ShuffleStatusWidget(
                    message: message,
                    isVisible: message.isNotEmpty,
                  );
                },
              );
            },
            'levelOneVictoryPanel': (context, game) => LevelOneVictoryPanel(
              game: game as CandyGame,
              onContinue: () => _handleContinue(),
              onMenu: () => _handleMenu(),
            ),
            'bombCreation': (context, CandyGame game) {
              if (game.bombCreationPosition == null) return Container();

              return BombCreationOverlay(
                position: Offset(
                  game.bombCreationPosition!.x,
                  game.bombCreationPosition!.y,
                ),
                onComplete: () async {
                  // ✅ LÓGICA CORRIGIDA E SIMPLIFICADA
                  game.overlays.remove('bombCreation');
                  game.bombCreationPosition = null;

                  final tutorialManager = BombTutorialManager.instance;

                  // 1. Verifica se deve mostrar o tutorial.
                  if (tutorialManager.shouldShowTutorial()) {
                    // 2. Se sim, marca IMEDIATAMENTE como visto para não mostrar de novo.
                    await tutorialManager.markTutorialAsShown();
                    // 3. Só então, adiciona o overlay do tutorial.
                    game.overlays.add('bombTutorial');
                  }
                },
              );
            },
            'bombTutorial': (context, CandyGame game) {
              // A tela do tutorial agora só precisa se preocupar em se fechar.
              return BombTutorialOverlay(
                onDismiss: () {
                  game.overlays.remove('bombTutorial');
                },
              );
            },
          },
          initialActiveOverlays: const [
            'movesPanel',
            'objectivesPanel',
            'shuffleStatus',
          ],
        ),
      ),
    );
  }

  /// Despacha o evento de reset ANTES de navegar
  void _resetBlocAndNavigate(Function navigationAction) {
    context.read<GameBloc>().add(const ResetGameEvent());
    navigationAction();
  }

  void _restartGame() {
    // 1. Pega o número do nível atual
    final currentLevelNumber = _game.level.levelNumber;

    // 2. Dispara o evento para RECARREGAR o nível, colocando o BLoC no estado 'GameReady'
    context.read<GameBloc>().add(GameLevelSelected(currentLevelNumber));

    // 3. Navega para a nova GamePage, que agora encontrará o estado correto
    Navigator.of(
      context,
    ).pushReplacement(SmoothPageTransitions.fadeTransition(const GamePage()));
  }

  void _handleContinue() {
    final currentLevel = _game.level.levelNumber;
    final nextLevel = currentLevel + 1;

    // Carrega o próximo nível
    context.read<GameBloc>().add(GameLevelSelected(nextLevel));
    Navigator.of(
      context,
    ).pushReplacement(SmoothPageTransitions.fadeTransition(const GamePage()));
  }

  void _handleMenu() {
    _resetBlocAndNavigate(() {
      Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
    });
  }
}

// Classe placeholder
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Nível')),
      body: const Center(child: Text('Tela de Seleção de Níveis')),
    );
  }
}
