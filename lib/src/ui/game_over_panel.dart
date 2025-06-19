// lib/src/ui/game_over_panel.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Um painel que é exibido quando o jogo acaba.
class GameOverPanel extends StatelessWidget {
  /// Um callback para ser executado quando o jogador decidir
  /// sair da tela de game over.
  final VoidCallback onTryAgain;

  const GameOverPanel({
    super.key,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    // BackdropFilter é usado para aplicar um efeito de desfoque
    // no que está atrás deste widget.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Você Perdeu!',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seus movimentos acabaram.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onTryAgain,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text(
                    'Tentar Novamente',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}