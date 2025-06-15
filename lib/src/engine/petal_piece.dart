// lib/src/engine/petal_piece.dart
import 'package:flame/components.dart';

enum PetalType {
  cherry,
  plum,
  maple,
  lily,
  orchid,
  peony,
  special_bomb,
  special_line,
  empty,
}

class PetalPiece extends SpriteComponent {
  final PetalType type;

  // ✅ O mapa agora é público para que a CandyGame possa pré-carregar os assets.
  static final Map<PetalType, String> petalSprites = {
    // ✅ CORREÇÃO: Os caminhos são relativos à pasta 'assets/images/'.
    // Supondo que seus arquivos estejam em 'assets/images/tiles/', o caminho fica assim:
    PetalType.cherry: 'tiles/cherry_petal.png',
    PetalType.plum: 'tiles/plum_petal.png',
    PetalType.maple: 'tiles/maple_petal.png',
    PetalType.lily: 'tiles/lily_petal.png',
    PetalType.orchid: 'tiles/orchid_petal.png',
    PetalType.peony: 'tiles/peony_petal.png',
    PetalType.special_bomb: 'tiles/special_bomb.png',
    PetalType.special_line: 'tiles/special_line.png',
    PetalType.empty: 'tiles/empty.png', // Um sprite transparente de 1x1 pixel é uma boa prática
  };
  
  // Este getter usa o mapa acima para encontrar o nome do sprite para esta instância.
  String get spriteName => petalSprites[type] ?? 'tiles/empty.png';

  PetalPiece(this.type);
  
  factory PetalPiece.empty() => PetalPiece(PetalType.empty);

  // ❌ MÉTODO REMOVIDO: O método estático getSpritePathForType foi removido
  // pois era redundante e continha um erro.

  @override
  Future<void> onLoad() async {
    if (type != PetalType.empty) {
      // Esta chamada usa o Flame's Image Cache. Como pré-carregamos tudo
      // no início do jogo, esta operação será quase instantânea.
      sprite = await Sprite.load(spriteName);
    }
  }
}