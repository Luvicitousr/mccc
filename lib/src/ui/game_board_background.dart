import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameBoardBackground extends Component with HasGameRef {
  // Variável para guardar nosso sprite de fundo
  late final Sprite _backgroundSprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Carrega a imagem da sua pasta de assets
    _backgroundSprite = await Sprite.load(
      'game_background.jpg',
    ); // <-- MUDE AQUI o nome do seu arquivo
  }

  @override
  void render(Canvas canvas) {
    _backgroundSprite.render(
      canvas,
      size:
          gameRef.size, // ✅ 'gameRef.size' corrige o erro de "size" indefinido
    );
  }
}
