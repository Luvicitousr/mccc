// lib/src/ui/game_page.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/candy_game.dart';

/// Um Widget simples que hospeda o GameWidget do nosso jogo.
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    // GameWidget é a ponte entre o Flutter e o seu jogo Flame.
    return GameWidget(game: CandyGame());
  }
}