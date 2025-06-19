// lib/src/engine/petal_piece.dart
import 'package:flame/components.dart';

// Enum para os tipos de pétalas
enum PetalType {
  cherry, plum, maple, lily, orchid, peony,
  // ✅ 1. Adiciona um tipo para representar um espaço vazio.
  empty,
  wall,  // ✅ ADICIONA O NOVO TIPO DE OBSTÁCULO.
}

class PetalPiece extends SpriteComponent {
  // ✅ 2. O tipo agora pode ser modificado.
  PetalType type;

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

  // ✅ 3. Novo método para alterar o tipo e o sprite da peça.
  /// Altera o tipo da peça e atualiza seu sprite para corresponder ao novo tipo.
  Future<void> changeType(PetalType newType) async {
    type = newType;
    await _updateSprite();
  }

  // ✅ 4. Lógica de carregamento de sprite extraída para um método privado.
  Future<void> _updateSprite() async {
    // Carrega o sprite correspondente ou fica transparente se for 'empty'.
    if (type == PetalType.empty) {
      sprite = null; // Remove o sprite para tornar a peça invisível.
      return;
    }
    sprite = await Sprite.load('tiles/${type.name}_petal.png');
  }
}