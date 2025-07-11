// lib/src/ui/zen_garden_screen.dart

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/zen_garden_game.dart';

class ZenGardenScreen extends StatefulWidget {
  const ZenGardenScreen({super.key});

  @override
  State<ZenGardenScreen> createState() => _ZenGardenScreenState();
}

class _ZenGardenScreenState extends State<ZenGardenScreen> {
  // Cria uma instância do nosso jogo do jardim
  late final ZenGardenGame _game = ZenGardenGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos uma Stack para sobrepor o botão de voltar ao jogo
      body: Stack(
        children: [
          // Camada de fundo: o widget que roda o jogo Flame
          GameWidget(game: _game),

          // Camada da frente: o botão de voltar
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black.withOpacity(0.5),
              onPressed: () {
                // Ação para voltar ao menu anterior
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
