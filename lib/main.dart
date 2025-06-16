// lib/main.dart
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'src/game/candy_game.dart';

void main() {
  // ✅ O jogo agora é criado e executado diretamente.
  final game = CandyGame();
  runApp(
    GameWidget(game: game),
  );
}