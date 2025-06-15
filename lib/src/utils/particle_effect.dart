// lib/src/utils/particle_effect.dart
import 'dart:math';
import 'package:flame/particles.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart'; // ✅ IMPORT QUE ESTAVA FALTANDO
import 'package:flutter/material.dart';
import '../engine/petal_piece.dart';

// Componente que gerencia a explosão de partículas para um conjunto de peças.
class MatchParticleEffect extends Component {
  final List<PetalPiece> matchedPieces;
  final int cascadeLevel; // ✅ Novo parâmetro

  static final Map<PetalType, Color> _petalColors = {
    PetalType.cherry: const Color(0xFFFFB7C5),
    PetalType.plum: const Color(0xFFB8E986),
    PetalType.maple: const Color(0xFFFFD700),
    PetalType.lily: Colors.white,
    PetalType.orchid: const Color(0xFFD870D6),
    PetalType.peony: const Color(0xFFFF69B4),
    PetalType.empty: Colors.transparent,
  };

  MatchParticleEffect({required this.matchedPieces, this.cascadeLevel = 1});

  @override
  Future<void> onLoad() async {
    for (final piece in matchedPieces) {
      if (piece.type == PetalType.empty) continue;

      final pieceColor = _petalColors[piece.type] ?? Colors.white;

      final particleComponent = ParticleSystemComponent(
        particle: Particle.generate(
          // ✅ Mais partículas para cascatas maiores!
          count: 10 + (cascadeLevel * 5),
          lifespan: 0.6 + (cascadeLevel * 0.1), // ✅ Partículas duram mais
          generator: (i) => AcceleratedParticle(
            speed: Vector2(
              Random().nextDouble() * 200 - 100,
              Random().nextDouble() * -300,
            ),
            acceleration: Vector2(0, 400),
            child: CircleParticle(
              radius: 2.5,
              paint: Paint()..color = pieceColor,
            ),
          ),
        ),
        position: piece.position + (piece.size / 2),
      );

      add(particleComponent);
    }

    await Future.delayed(const Duration(milliseconds: 600));
    removeFromParent();
  }
}

// Animação especial para pétala especial
class SpecialPetalAnimation extends PositionComponent {
  SpecialPetalAnimation({required PositionComponent petal}) {
    position = petal.position;
    size = petal.size;
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    // ✅ Agora o SequenceEffect e outros serão encontrados graças ao import
    await add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.5),
          EffectController(duration: 0.3, reverseDuration: 0.2),
        ),
        OpacityEffect.fadeOut(EffectController(duration: 0.2)),
      ]),
    );
    removeFromParent();
  }
}
