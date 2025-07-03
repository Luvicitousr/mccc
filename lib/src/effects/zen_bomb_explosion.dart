import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'dart:math' as math;

/// 💥 Sistema de Explosão Zen para Peças Bomb - VERSÃO CORRIGIDA
/// ✅ CORREÇÕES APLICADAS:
/// - Validação rigorosa de parâmetros
/// - Prevenção de valores fora do range
/// - Sincronização melhorada
/// - Error handling robusto
class ZenBombExplosion extends Component with HasGameRef {
  final Vector2 explosionCenter;
  final double maxRadius;
  final VoidCallback? onComplete;

  late final List<ZenExplosionRing> _rings;
  late final List<ZenPetal> _petals;
  late final List<ZenSparkle> _sparkles;

  bool _isComplete = false;
  double _elapsedTime = 0.0;

  // ✅ CORREÇÃO: Configurações validadas
  static const Duration explosionDuration = Duration(milliseconds: 1200);
  static const int ringCount = 3;
  static const int petalCount = 12;
  static const int sparkleCount = 8;

  // ✅ CORREÇÃO: Constantes de validação
  static const double _minRadius = 10.0;
  static const double _maxRadius = 500.0;
  static const double _minDuration = 0.5;
  static const double _maxDuration = 3.0;

  ZenBombExplosion({
    required this.explosionCenter,
    required this.maxRadius,
    this.onComplete,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ CORREÇÃO: Validação de parâmetros
    final validRadius = maxRadius.clamp(_minRadius, _maxRadius);

    _initializeExplosionElements(validRadius);
    _startExplosionSequence();
  }

  void _initializeExplosionElements(double validRadius) {
    _rings = [];
    _petals = [];
    _sparkles = [];

    try {
      // ✅ CORREÇÃO: Criação segura de anéis
      for (int i = 0; i < ringCount; i++) {
        final ring = ZenExplosionRing(
          center: explosionCenter,
          maxRadius: validRadius,
          delay: Duration(milliseconds: i * 150),
          ringIndex: i,
        );
        _rings.add(ring);
        add(ring);
      }

      // ✅ CORREÇÃO: Criação segura de pétalas
      for (int i = 0; i < petalCount; i++) {
        final angle = (i * 2 * math.pi) / petalCount;
        final petal = ZenPetal(
          startPosition: explosionCenter,
          angle: angle,
          maxDistance: validRadius * 1.2,
          delay: Duration(milliseconds: 200 + (i * 50)),
        );
        _petals.add(petal);
        add(petal);
      }

      // ✅ CORREÇÃO: Criação segura de brilhos
      for (int i = 0; i < sparkleCount; i++) {
        final sparkle = ZenSparkle(
          center: explosionCenter,
          maxRadius: validRadius * 0.8,
          delay: Duration(milliseconds: 100 + (i * 100)),
          sparkleIndex: i,
        );
        _sparkles.add(sparkle);
        add(sparkle);
      }
    } catch (e) {
      print("[ZEN_EXPLOSION] Erro ao inicializar elementos: $e");
    }
  }

  void _startExplosionSequence() {
    // ✅ CORREÇÃO: Flash inicial validado
    add(
      OpacityEffect.to(
        0.3,
        EffectController(duration: 0.1),
        onComplete: () {
          add(
            OpacityEffect.to(
              1.0,
              EffectController(duration: 0.2),
            ),
          );
        },
      ),
    );

    // ✅ CORREÇÃO: Remoção segura com callback
    add(
      RemoveEffect(
        delay: explosionDuration.inMilliseconds / 1000.0,
        onComplete: () {
          _isComplete = true;
          try {
            onComplete?.call();
          } catch (e) {
            print("[ZEN_EXPLOSION] Erro no callback de conclusão: $e");
          }
        },
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ CORREÇÃO: Validação de delta time
    final validDt = dt.clamp(0.001, 0.1);
    _elapsedTime += validDt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // ✅ CORREÇÃO: Renderização segura
    final durationSeconds = explosionDuration.inMilliseconds / 1000.0;
    if (_elapsedTime < durationSeconds) {
      _renderZenBlur(canvas, durationSeconds);
    }
  }

  void _renderZenBlur(Canvas canvas, double durationSeconds) {
    try {
      // ✅ CORREÇÃO: Cálculo seguro de progresso
      final progress = (_elapsedTime / durationSeconds).clamp(0.0, 1.0);
      final validRadius = maxRadius.clamp(_minRadius, _maxRadius);

      final paint = Paint()
        ..color = const Color(0xFFFFE082).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

      canvas.drawCircle(
        explosionCenter.toOffset(),
        validRadius * progress,
        paint,
      );
    } catch (e) {
      print("[ZEN_EXPLOSION] Erro ao renderizar blur: $e");
    }
  }

  bool get isComplete => _isComplete;
}

/// 🌊 Anel de Expansão Zen - VERSÃO CORRIGIDA
class ZenExplosionRing extends Component {
  final Vector2 center;
  final double maxRadius;
  final Duration delay;
  final int ringIndex;

  late double _currentRadius;
  late double _opacity;
  bool _hasStarted = false;
  double _delayTimer = 0.0;

  // ✅ CORREÇÃO: Cores zen validadas
  static const List<Color> zenColors = [
    Color(0xFF81C784), // Verde água
    Color(0xFFFFB7C5), // Rosa cerejeira
    Color(0xFFFFE082), // Dourado suave
  ];

  ZenExplosionRing({
    required this.center,
    required this.maxRadius,
    required this.delay,
    required this.ringIndex,
  });

  @override
  void onLoad() {
    _currentRadius = 0.0;
    _opacity = 0.8;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ CORREÇÃO: Validação de delta time
    final validDt = dt.clamp(0.001, 0.1);

    if (!_hasStarted) {
      _delayTimer += validDt;
      if (_delayTimer >= delay.inMilliseconds / 1000.0) {
        _hasStarted = true;
      }
      return;
    }

    // ✅ CORREÇÃO: Expansão validada
    final expansionSpeed = math.max(50.0, maxRadius * 2.0);
    _currentRadius += expansionSpeed * validDt;

    // ✅ CORREÇÃO: Fade out seguro
    if (_currentRadius > maxRadius * 0.5) {
      final fadeProgress =
          ((_currentRadius - maxRadius * 0.5) / (maxRadius * 0.5))
              .clamp(0.0, 1.0);
      _opacity = (0.8 * (1.0 - fadeProgress)).clamp(0.0, 1.0);
    }

    // ✅ CORREÇÃO: Remoção segura
    if (_currentRadius >= maxRadius) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_hasStarted || _currentRadius <= 0) return;

    try {
      final paint = Paint()
        ..color = zenColors[ringIndex % zenColors.length].withOpacity(_opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(
        center.toOffset(),
        _currentRadius,
        paint,
      );
    } catch (e) {
      print("[ZEN_RING] Erro ao renderizar: $e");
    }
  }
}

/// 🌸 Pétala Flutuante Zen - VERSÃO CORRIGIDA
class ZenPetal extends Component {
  final Vector2 startPosition;
  final double angle;
  final double maxDistance;
  final Duration delay;

  late Vector2 _currentPosition;
  late double _currentDistance;
  late double _rotation;
  late double _opacity;
  bool _hasStarted = false;
  double _delayTimer = 0.0;

  ZenPetal({
    required this.startPosition,
    required this.angle,
    required this.maxDistance,
    required this.delay,
  });

  @override
  void onLoad() {
    _currentPosition = startPosition.clone();
    _currentDistance = 0.0;
    _rotation = 0.0;
    _opacity = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ CORREÇÃO: Validação de delta time
    final validDt = dt.clamp(0.001, 0.1);

    if (!_hasStarted) {
      _delayTimer += validDt;
      if (_delayTimer >= delay.inMilliseconds / 1000.0) {
        _hasStarted = true;
        _opacity = 0.6;
      }
      return;
    }

    // ✅ CORREÇÃO: Movimento validado
    final speed = math.max(50.0, maxDistance * 1.5);
    _currentDistance += speed * validDt;

    // ✅ CORREÇÃO: Posição segura
    final baseX = startPosition.x + math.cos(angle) * _currentDistance;
    final baseY = startPosition.y + math.sin(angle) * _currentDistance;

    // ✅ CORREÇÃO: Flutuação controlada
    final time = _delayTimer + (_currentDistance / maxDistance) * 2 * math.pi;
    final floatX = math.sin(time * 2) * 10;
    final floatY = math.cos(time * 1.5) * 8;

    _currentPosition = Vector2(baseX + floatX, baseY + floatY);

    // ✅ CORREÇÃO: Rotação suave
    _rotation += validDt * 2.0;

    // ✅ CORREÇÃO: Fade out validado
    if (_currentDistance > maxDistance * 0.6) {
      final fadeProgress =
          ((_currentDistance - maxDistance * 0.6) / (maxDistance * 0.4))
              .clamp(0.0, 1.0);
      _opacity = (0.6 * (1.0 - fadeProgress)).clamp(0.0, 1.0);
    }

    // ✅ CORREÇÃO: Remoção segura
    if (_currentDistance >= maxDistance) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_hasStarted || _opacity <= 0) return;

    try {
      canvas.save();
      canvas.translate(_currentPosition.x, _currentPosition.y);
      canvas.rotate(_rotation);

      final paint = Paint()
        ..color = const Color(0xFFFFB7C5).withOpacity(_opacity);

      // ✅ CORREÇÃO: Desenho seguro da pétala
      final path = Path();
      path.moveTo(0, -8);
      path.quadraticBezierTo(6, -4, 0, 0);
      path.quadraticBezierTo(-6, -4, 0, -8);

      canvas.drawPath(path, paint);
      canvas.restore();
    } catch (e) {
      print("[ZEN_PETAL] Erro ao renderizar: $e");
    }
  }
}

/// ✨ Brilho Zen - VERSÃO CORRIGIDA
class ZenSparkle extends Component {
  final Vector2 center;
  final double maxRadius;
  final Duration delay;
  final int sparkleIndex;

  late Vector2 _position;
  late double _scale;
  late double _opacity;
  bool _hasStarted = false;
  double _delayTimer = 0.0;
  double _lifeTime = 0.0;

  static const double sparkleLifeDuration = 0.8;

  ZenSparkle({
    required this.center,
    required this.maxRadius,
    required this.delay,
    required this.sparkleIndex,
  });

  @override
  void onLoad() {
    // ✅ CORREÇÃO: Posição aleatória segura
    final random = math.Random();
    final distance = random.nextDouble() * maxRadius;
    final angle = random.nextDouble() * 2 * math.pi;

    _position = Vector2(
      center.x + math.cos(angle) * distance,
      center.y + math.sin(angle) * distance,
    );

    _scale = 0.0;
    _opacity = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ CORREÇÃO: Validação de delta time
    final validDt = dt.clamp(0.001, 0.1);

    if (!_hasStarted) {
      _delayTimer += validDt;
      if (_delayTimer >= delay.inMilliseconds / 1000.0) {
        _hasStarted = true;
      }
      return;
    }

    _lifeTime += validDt;
    final progress = (_lifeTime / sparkleLifeDuration).clamp(0.0, 1.0);

    if (progress <= 1.0) {
      // ✅ CORREÇÃO: Crescimento e fade validados
      if (progress < 0.3) {
        _scale = (progress / 0.3).clamp(0.0, 1.0);
        _opacity = (progress / 0.3).clamp(0.0, 1.0);
      } else {
        _scale = 1.0;
        _opacity = (1.0 - ((progress - 0.3) / 0.7)).clamp(0.0, 1.0);
      }
    } else {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_hasStarted || _opacity <= 0) return;

    try {
      canvas.save();
      canvas.translate(_position.x, _position.y);
      canvas.scale(_scale);

      final paint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(_opacity);

      // ✅ CORREÇÃO: Desenho seguro da estrela
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi) / 4;
        final radius = i % 2 == 0 ? 6.0 : 3.0;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    } catch (e) {
      print("[ZEN_SPARKLE] Erro ao renderizar: $e");
    }
  }
}
