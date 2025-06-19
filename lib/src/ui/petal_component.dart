// lib/src/ui/petal_component.dart
import 'dart:math';
import 'package:flame/components.dart';
// Importe o seu jogo para poder referenciá-lo no mixin.
import 'package:meu_candy_crush_clone/src/ui/petal_fall_game.dart';

// ✅ 1. ADICIONE O MIXIN 'HasGameRef<PetalFallGame>'
class PetalComponent extends SpriteComponent with HasGameReference<PetalFallGame> {
  final double speed;
  final double rotationSpeed;
  final double swayAmplitude;
  final double swaySpeed;

  late double _initialX;
  double _time = 0;

  PetalComponent({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    required this.speed,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swaySpeed,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.center, // Importante para a rotação ser no centro.
        );

  @override
  void onMount() {
    super.onMount();
    _initialX = position.x; // Guarda a posição X inicial.
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Movimento vertical (queda)
    position.y += speed * dt;

    // Rotação
    angle += rotationSpeed * dt;

    // Movimento errático (oscilação lateral usando uma função seno)
    position.x = _initialX + sin(_time * swaySpeed) * swayAmplitude;

    // Se a pétala saiu da parte de baixo da tela, remove-a do jogo.
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
}