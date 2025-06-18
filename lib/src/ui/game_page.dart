// lib/src/ui/game_page.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ USAREMOS O GameWidget.controlled PARA PODER PASSAR PARÂMETROS
    // E CONFIGURAR OVERLAYS DE FORMA MAIS FÁCIL.
    return GameWidget.controlled(
      // ✅ 1. O gameFactory agora é mais simples.
      gameFactory: () => CandyGame(),
      // O mapa de overlays conecta um nome de string a um construtor de widget.
      overlayBuilderMap: {
        'movesPanel': (context, game) {
          // O 'game' aqui é a instância do CandyGame criada acima.
          // Nós passamos o notificador de movimentos para o nosso painel.
          return MovesPanel(movesLeft: (game as CandyGame).movesLeft);
        },

        // ✅ 2. ADICIONE O CONSTRUTOR PARA O NOVO OVERLAY.
        'gameOverPanel': (context, game) {
          return GameOverPanel(
            // Define a ação do botão.
            onRestart: () {
              // ✅ CORREÇÃO: Verifica se o objeto 'game' é um FlameGame antes de usá-lo.
              if (game is FlameGame) {
                // Dentro deste 'if', o Dart já sabe que 'game' é um FlameGame.
                // Portanto, podemos chamar os métodos com segurança.
                game.overlays.remove('gameOverPanel');
                game.resumeEngine();
              }
              // Usa o Navigator para voltar ao menu principal.
              Navigator.of(context).pop();
            },
          );
        },

        // ✅ ADICIONE OS NOVOS OVERLAYS AQUI.
        'objectivesPanel': (context, game) {
          // Align é usado para posicionar o painel no topo central.
          return Align(
            alignment: Alignment.topCenter,
            child: ObjectivesPanel(objectives: (game as CandyGame).objectives),
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
  }
}
