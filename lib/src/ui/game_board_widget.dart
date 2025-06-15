// lib/src/ui/game_board_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';

class GameBoardWidget extends StatelessWidget {
  static const String overlayKey = 'GameBoardOverlay';

  const GameBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          // ✅ Variáveis para guardar os valores, com um padrão seguro.
          final String score = '0'; // TODO: Implementar a pontuação no estado.
          String multiplier = 'x1';

          // ✅ VERIFICAÇÃO DE TIPO: Só acessa 'state.board' se o estado for do tipo correto.
          if (state is GameStateUpdated) {
            multiplier = 'x${state.board.multiplier}';
          }

          // A UI agora usa as variáveis seguras.
          return Positioned(
            top: 60.0, // Aumentado um pouco para dar mais espaço
            left: 20.0,
            right: 20.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScoreboard('Pontos', score, Colors.amber),
                const SizedBox(height: 16),
                _buildScoreboard('Multiplicador', multiplier, Colors.lightBlueAccent),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget auxiliar para criar um placar estilizado (sem alterações)
  Widget _buildScoreboard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Um pouco mais opaco para legibilidade
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.8), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black)],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}