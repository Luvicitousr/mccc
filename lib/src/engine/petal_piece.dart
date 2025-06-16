// lib/src/engine/petal_piece.dart
import 'package:flame/components.dart';

// Enum para os tipos de pétalas
enum PetalType {
  cherry, plum, maple, lily, orchid, peony,
  // Adicione outros tipos se necessário
}

class PetalPiece extends SpriteComponent {
  final PetalType type;

  PetalPiece({
    required this.type,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    // Carrega o sprite com base no nome do enum
    sprite = await Sprite.load('tiles/${type.name}_petal.png');
  }
}