// lib/src/engine/petal_piece.dart

import 'dart:ui';
import 'package:flame/components.dart';

// Enum para os tipos de pétalas
enum PetalType {
  cherry,
  plum,
  maple,
  lily,
  orchid,
  peony,
  empty,
  wall,
  caged2,
  caged1,
}

class PetalPiece extends SpriteComponent {
  PetalType type;
  final Map<PetalType, Sprite> spriteMap; // Mapa de sprites pré-carregados

  PetalPiece({
    required this.type,
    required this.spriteMap, // Recebe o mapa de sprites
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void onLoad() {
    // Agora é síncrono! Pega o sprite diretamente do mapa.
    sprite = spriteMap[type];
  }

  // Altera o tipo e o sprite da peça instantaneamente.
  void changeType(PetalType newType) {
    type = newType;
    sprite = spriteMap[type];
  }

  // Não precisamos mais dos métodos async _updateSprite
  // A lógica de renderização de segurança pode ser mantida
  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    }
  }
}
