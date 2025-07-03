import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// ✨ Sistema de Partículas para Explosão da Bomba
/// Implementa efeitos visuais zen japoneses para a explosão
class BombParticleSystem extends Component {
  final Vector2 position;
  final double radius;
  final Duration duration;

  BombParticleSystem({
    required this.position,
    required this.radius,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Cria diferentes camadas de partículas
    _createWaveParticles();
    _createPetalParticles();
    _createSparkleParticles();
    _createSmokeParticles();

    // Remove componente após duração
    add(
      RemoveEffect(
        delay: duration.inMilliseconds / 1000.0,
      ),
    );
  }

  /// 🌊 Cria partículas de onda expansiva
  void _createWaveParticles() {
    final random = math.Random();

    // Onda principal
    final mainWave = CircleComponent(
      radius: 5,
      paint: Paint()
        ..color = const Color(0xFFFFE082).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
      position: position.clone(),
      anchor: Anchor.center,
    );

    mainWave.add(
      ScaleEffect.by(
        Vector2.all(radius / 5),
        EffectController(
          duration: 0.8,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    mainWave.add(
      OpacityEffect.fadeOut(
        EffectController(
          duration: 0.8,
          curve: Curves.easeIn,
        ),
      ),
    );

    add(mainWave);

    // Ondas secundárias
    for (int i = 0; i < 3; i++) {
      final delay = 0.2 + (i * 0.15);
      final scale = 0.7 + (random.nextDouble() * 0.3);

      final secondaryWave = CircleComponent(
        radius: 3,
        paint: Paint()
          ..color = const Color(0xFFFFB7C5).withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
        position: position.clone(),
        anchor: Anchor.center,
      );

      secondaryWave.add(
        ScaleEffect.by(
          Vector2.all(radius * scale / 3),
          EffectController(
            startDelay: delay,
            duration: 0.7,
            curve: Curves.easeOutQuart,
          ),
        ),
      );

      secondaryWave.add(
        OpacityEffect.fadeOut(
          EffectController(
            startDelay: delay,
            duration: 0.7,
            curve: Curves.easeIn,
          ),
        ),
      );

      add(secondaryWave);
    }
  }

  /// 🌸 Cria partículas de pétalas usando ParticleSystemComponent
  void _createPetalParticles() {
    final random = math.Random();
    final count = 12 + random.nextInt(8);

    final petalParticles = <Particle>[];

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = radius * (0.3 + random.nextDouble() * 0.7);
      final delay = random.nextDouble() * 0.3;
      final duration = 0.8 + random.nextDouble() * 0.7;
      final size = 4.0 + random.nextDouble() * 8.0;

      final targetX = math.cos(angle) * distance;
      final targetY = math.sin(angle) * distance;

      final color = i % 3 == 0
          ? const Color(0xFFFFB7C5) // Rosa cerejeira
          : i % 3 == 1
              ? const Color(0xFFFFE082) // Dourado suave
              : const Color(0xFF81C784); // Verde água

      petalParticles.add(
        MovingParticle(
          from: Vector2.zero(),
          to: Vector2(targetX, targetY),
          child: _createPetalParticle(
            size: size,
            angle: angle,
            color: color,
          ),
          lifespan: duration,
          curve: Curves.easeOutQuart,
        ),
      );
    }

    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: petalParticles.length,
          generator: (i) => petalParticles[i],
        ),
        position: position,
      ),
    );
  }

  /// ✨ Cria partículas de brilho
  void _createSparkleParticles() {
    final random = math.Random();
    final count = 20 + random.nextInt(10);

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = radius * (0.1 + random.nextDouble() * 0.9);
      final delay = random.nextDouble() * 0.5;
      final duration = 0.3 + random.nextDouble() * 0.7;
      final size = 2.0 + random.nextDouble() * 4.0;

      final targetX = position.x + math.cos(angle) * distance;
      final targetY = position.y + math.sin(angle) * distance;

      final sparkle = CircleComponent(
        radius: size,
        paint: Paint()..color = const Color(0xFFFFD700).withOpacity(0.8),
        position: position.clone(),
        anchor: Anchor.center,
      );

      sparkle.add(
        MoveToEffect(
          Vector2(targetX, targetY),
          EffectController(
            startDelay: delay,
            duration: duration,
            curve: Curves.easeOutQuart,
          ),
        ),
      );

      sparkle.add(
        ScaleEffect.by(
          Vector2.all(0.1),
          EffectController(
            startDelay: delay + (duration * 0.7),
            duration: duration * 0.3,
          ),
        ),
      );

      sparkle.add(
        OpacityEffect.fadeOut(
          EffectController(
            startDelay: delay + (duration * 0.5),
            duration: duration * 0.5,
          ),
        ),
      );

      add(sparkle);
    }
  }

  /// 💨 Cria partículas de fumaça suave
  void _createSmokeParticles() {
    final random = math.Random();
    final count = 8 + random.nextInt(6);

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = radius * (0.2 + random.nextDouble() * 0.5);
      final delay = 0.1 + random.nextDouble() * 0.3;
      final duration = 1.0 + random.nextDouble() * 1.0;
      final size = 15.0 + random.nextDouble() * 25.0;

      final targetX = position.x + math.cos(angle) * distance;
      final targetY = position.y + math.sin(angle) * distance;

      final smoke = CircleComponent(
        radius: size,
        paint: Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        position: position.clone(),
        anchor: Anchor.center,
      );

      smoke.add(
        MoveToEffect(
          Vector2(targetX, targetY),
          EffectController(
            startDelay: delay,
            duration: duration,
            curve: Curves.easeOutQuart,
          ),
        ),
      );

      smoke.add(
        ScaleEffect.by(
          Vector2.all(1.5),
          EffectController(
            startDelay: delay,
            duration: duration,
            curve: Curves.easeOut,
          ),
        ),
      );

      smoke.add(
        OpacityEffect.fadeOut(
          EffectController(
            startDelay: delay + (duration * 0.3),
            duration: duration * 0.7,
          ),
        ),
      );

      add(smoke);
    }
  }

  /// 🌸 Cria partícula de pétala
  Particle _createPetalParticle({
    required double size,
    required double angle,
    required Color color,
  }) {
    return ComputedParticle(
      renderer: (canvas, particle) {
        final paint = Paint()
          ..color = color.withOpacity(particle.progress < 0.1
              ? particle.progress * 10 * 0.8
              : 0.8 * (1 - ((particle.progress - 0.1) / 0.9)));

        canvas.save();
        canvas.rotate(angle);

        // Desenha pétala simples
        final path = Path();
        path.moveTo(0, -size);
        path.quadraticBezierTo(size * 0.8, -size * 0.5, 0, 0);
        path.quadraticBezierTo(-size * 0.8, -size * 0.5, 0, -size);

        canvas.drawPath(path, paint);
        canvas.restore();
      },
      lifespan: 1.0,
    );
  }
}
