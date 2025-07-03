import 'package:flutter/material.dart';
import '../game/candy_game.dart';
import 'zen_game_over_panel.dart';

/// 🎮 Integração do Game Over com o Jogo
///
/// Este módulo integra o painel de Game Over zen
/// com o sistema de jogo existente.
class GameOverIntegration {
  /// Registra o painel de Game Over no mapa de overlays do jogo
  static Map<String, Widget Function(BuildContext, dynamic)>
      registerOverlays() {
    return {
      'gameOverPanel': (context, game) => ZenGameOverPanel(
            game: game,
            onRestart: () => _handleRestart(context, game),
            onMenu: () => _handleMenu(context, game),
          ),
    };
  }

  /// Manipula a ação de reiniciar o jogo
  static void _handleRestart(BuildContext context, CandyGame game) {
    // Remove o overlay
    game.overlays.remove('gameOverPanel');

    // Reinicia o jogo
    game.resumeEngine();

    // Implementação de reinício (a ser expandida conforme necessário)
    Navigator.of(context).pushReplacementNamed('/game');
  }

  /// Manipula a ação de voltar ao menu
  static void _handleMenu(BuildContext context, CandyGame game) {
    // Remove o overlay
    game.overlays.remove('gameOverPanel');

    // Limpa o estado do jogo
    game.resumeEngine();

    // Volta para o menu principal
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/menu',
      (route) => false,
    );
  }

  /// Mostra o painel de Game Over
  static void showGameOver(CandyGame game) {

    // Adiciona o overlay de Game Over
    game.overlays.add('gameOverPanel');
  }
}
