// lib/src/ui/game_page.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Importa o BLoC
import '../bloc/game_bloc.dart'; // Importa nosso BLoC
import '../engine/level_definition.dart'; // Importa a definição
import '../game/candy_game.dart';
// Importe o novo painel de UI
import 'moves_panel.dart';
// Importe o novo painel de Game Over.
import 'game_over_panel.dart';
// Importe os novos painéis
import 'objectives_panel.dart';
import 'game_won_panel.dart';

/// Um Widget simples que hospeda o GameWidget do nosso jogo.
class GamePage extends StatelessWidget {
  // ✅ Pode voltar a ser StatelessWidget
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ O BlocBuilder ouve as mudanças no GameBloc.
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        // Quando o estado muda, este builder é chamado novamente.
        if (state is GamePlayState) {
          // Usamos a 'key' do estado para forçar o Flutter a criar uma
          // nova instância do FutureBuilder e do GameWidget, reiniciando o nível.
          return LevelLoader(key: state.key);
        }
        // Estado de fallback (não deve acontecer neste caso).
        return const Center(child: Text('Erro de Estado'));
      },
    );
  }
}

// Widget auxiliar para manter a lógica de carregamento do nível
class LevelLoader extends StatefulWidget {
  const LevelLoader({super.key});

  @override
  State<LevelLoader> createState() => _LevelLoaderState();
}

class _LevelLoaderState extends State<LevelLoader> {
  late final Future<LevelDefinition> _levelFuture;

  @override
  void initState() {
    super.initState();
    _levelFuture = LevelDefinition.load('level_1.json');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LevelDefinition>(
      future: _levelFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final level = snapshot.data!;
        return GameWidget.controlled(
          gameFactory: () => CandyGame(level: level),
          // O mapa de overlays conecta um nome de string a um construtor de widget.
          overlayBuilderMap: {
            'noMovesOverlay': (context, game) {
              return Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Text(
                    'Sem movimentos...\nEmbaralhando!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            'movesPanel': (context, game) {
              // O 'game' aqui é a instância do CandyGame criada acima.
              // Nós passamos o notificador de movimentos para o nosso painel.
              return MovesPanel(movesLeft: (game as CandyGame).movesLeft);
            },

            // ✅ 2. ADICIONE O CONSTRUTOR PARA O NOVO OVERLAY.
            'gameOverPanel': (context, game) {
              return GameOverPanel(
                // Define a ação do botão.
                onTryAgain: () {
                  // ✅ CORREÇÃO: Verifica se o objeto 'game' é um FlameGame antes de usá-lo.
                  if (game is FlameGame) {
                    // Dentro deste 'if', o Dart já sabe que 'game' é um FlameGame.
                    // Portanto, podemos chamar os métodos com segurança.
                    game.overlays.remove('gameOverPanel');
                    game.resumeEngine();
                  }
                  // ✅ Dispara o evento de reset no GameBloc!
                  context.read<GameBloc>().add(ResetGameEvent());
                },
              );
            },

            // ✅ ADICIONE OS NOVOS OVERLAYS AQUI.
            'objectivesPanel': (context, game) {
              // Align é usado para posicionar o painel no topo central.
              return Align(
                alignment: Alignment.topCenter,
                child: ObjectivesPanel(
                  objectives: (game as CandyGame).objectives,
                ),
              );
            },
            'gameWonPanel': (context, game) {
              return GameWonPanel(
                onRestart: () {
                  if (game is FlameGame) {
                    game.overlays.remove('gameWonPanel');
                    game.resumeEngine();
                  }
                  Navigator.of(context).pop();
                },
              );
            },
          },
        );
      },
    );
  }
}
