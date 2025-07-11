// lib/src/game/zen_garden_game.dart

import 'package:flame/game.dart';
import 'package:flame/events.dart';

// Importe os arquivos necessários
import '../ui/zen_garden_background.dart';
import '../ui/zen_garden_elements.dart';
import '../audio/zen_audio_manager.dart';

class ZenGardenGame extends FlameGame with TapDetector {
  late final ZenGardenInteractions _interactions;

  @override
  Future<void> onLoad() async {
    // Adiciona o fundo e os elementos decorativos que você criou [cite: 1]
    await add(ZenGardenBackground());
    await add(ZenGardenElements());

    // Adiciona o componente de interações e o armazena para referência [cite: 49]
    _interactions = ZenGardenInteractions();
    await add(_interactions);

    // Inicia os sons ambientes do jardim [cite: 97]
    ZenAudioManager().startAmbientSounds();
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);

    // Esta abordagem é a mais compatível.
    final touchPosition = Vector2(
      info.raw.globalPosition.dx,
      info.raw.globalPosition.dy,
    );

    // Dispara uma interação no local do toque
    _interactions.triggerInteraction(touchPosition);
  }

  // Limpa os recursos ao sair da tela
  @override
  void onRemove() {
    super.onRemove();
    // Para os sons ambientes para não vazarem para outras telas [cite: 102]
    ZenAudioManager().stopAmbientSounds();
  }
}
