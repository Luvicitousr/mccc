import 'package:flame/components.dart';

class TileComponent extends SpriteComponent {
  final int row, col;
  TileComponent({required this.row, required this.col, required Sprite sprite})
      : super(sprite: sprite, size: Vector2.all(48.0));
}