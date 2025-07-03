import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 💥 Overlay de Explosão da Bomba - VERSÃO CORRIGIDA
/// Exibe efeitos visuais adicionais durante a explosão da bomba
/// ✅ CORREÇÕES APLICADAS:
/// - Validação rigorosa de valores de animação
/// - Prevenção de valores fora do range [0.0, 1.0]
/// - Error handling robusto
class BombExplosionOverlay extends StatefulWidget {
  final Offset center;
  final double radius;
  final VoidCallback? onComplete;

  const BombExplosionOverlay({
    super.key,
    required this.center,
    required this.radius,
    this.onComplete,
  });

  @override
  State<BombExplosionOverlay> createState() => _BombExplosionOverlayState();
}

class _BombExplosionOverlayState extends State<BombExplosionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expansionAnimation;
  late Animation<double> _opacityAnimation;

  // ✅ CORREÇÃO: Constantes de validação
  static const double _minAnimationValue = 0.0;
  static const double _maxAnimationValue = 1.0;
  static const double _minRadius = 1.0;
  static const double _maxRadius = 1000.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    try {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      // ✅ CORREÇÃO: Animação de expansão validada
      _expansionAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ));

      // ✅ CORREÇÃO: Animação de opacidade validada
      _opacityAnimation = Tween<double>(
        begin: 0.7,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ));
    } catch (e) {
      print("[BOMB_EXPLOSION] Erro ao inicializar animações: $e");
      _initializeFallbackAnimations();
    }
  }

  /// ✅ CORREÇÃO: Animações de fallback seguras
  void _initializeFallbackAnimations() {
    _expansionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(_controller);
  }

  void _startAnimation() {
    try {
      _controller.forward().then((_) {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    } catch (e) {
      print("[BOMB_EXPLOSION] Erro ao iniciar animação: $e");
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // ✅ CORREÇÃO: Validação de valores de animação
          final safeExpansion =
              _validateAnimationValue(_expansionAnimation.value);
          final safeOpacity = _validateAnimationValue(_opacityAnimation.value);
          final safeRadius = _validateRadius(widget.radius * safeExpansion);

          return CustomPaint(
            painter: BombExplosionPainter(
              center: widget.center,
              radius: safeRadius,
              opacity: safeOpacity,
            ),
          );
        },
      ),
    );
  }

  /// ✅ CORREÇÃO: Função de validação de valores de animação
  double _validateAnimationValue(double value) {
    if (value.isNaN || value.isInfinite) {
      return _minAnimationValue;
    }
    return value.clamp(_minAnimationValue, _maxAnimationValue);
  }

  /// ✅ CORREÇÃO: Função de validação de raio
  double _validateRadius(double radius) {
    if (radius.isNaN || radius.isInfinite) {
      return _minRadius;
    }
    return radius.clamp(_minRadius, _maxRadius);
  }
}

/// 🎨 Painter para efeito de explosão - VERSÃO CORRIGIDA
class BombExplosionPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double opacity;

  // ✅ CORREÇÃO: Constantes de validação
  static const double _minOpacity = 0.0;
  static const double _maxOpacity = 1.0;
  static const double _minRadius = 0.0;
  static const double _maxRadius = 1000.0;

  BombExplosionPainter({
    required this.center,
    required this.radius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // ✅ CORREÇÃO: Validação de parâmetros
      final safeOpacity = opacity.clamp(_minOpacity, _maxOpacity);
      final safeRadius = radius.clamp(_minRadius, _maxRadius);

      if (safeOpacity <= 0.0 || safeRadius <= 0.0) {
        return; // Não desenha se valores inválidos
      }

      // ✅ CORREÇÃO: Efeito de brilho central com validação
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(safeOpacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);

      canvas.drawCircle(center, safeRadius * 0.5, glowPaint);

      // ✅ CORREÇÃO: Onda expansiva principal com validação
      final wavePaint = Paint()
        ..color = const Color(0xFFFFE082).withOpacity(safeOpacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(center, safeRadius, wavePaint);

      // ✅ CORREÇÃO: Ondas secundárias com validação
      final secondaryWavePaint = Paint()
        ..color = const Color(0xFFFFB7C5).withOpacity(safeOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, safeRadius * 0.7, secondaryWavePaint);

      // ✅ CORREÇÃO: Partículas radiais com validação
      _drawRadialParticles(canvas, safeRadius, safeOpacity);
    } catch (e) {
      print("[BOMB_EXPLOSION_PAINTER] Erro ao renderizar: $e");
      _drawFallbackEffect(canvas);
    }
  }

  /// ✅ CORREÇÃO: Desenho de partículas radiais com validação
  void _drawRadialParticles(Canvas canvas, double radius, double opacity) {
    try {
      final random = math.Random(42); // Seed fixo para consistência
      const particleCount = 16;

      for (int i = 0; i < particleCount; i++) {
        final angle = (i * 2 * math.pi) / particleCount;
        final distance = radius * (0.3 + random.nextDouble() * 0.7);
        final particleRadius = 3.0 + random.nextDouble() * 5.0;

        final x = center.dx + math.cos(angle) * distance;
        final y = center.dy + math.sin(angle) * distance;

        final particlePaint = Paint()
          ..color = const Color(0xFFFFD700).withOpacity(opacity * 0.8);

        canvas.drawCircle(Offset(x, y), particleRadius, particlePaint);
      }
    } catch (e) {
      print("[BOMB_EXPLOSION_PAINTER] Erro ao desenhar partículas: $e");
    }
  }

  /// ✅ CORREÇÃO: Efeito de fallback em caso de erro
  void _drawFallbackEffect(Canvas canvas) {
    try {
      final fallbackPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.3);

      canvas.drawCircle(center, 50.0, fallbackPaint);
    } catch (e) {
      print("[BOMB_EXPLOSION_PAINTER] Erro no fallback: $e");
    }
  }

  @override
  bool shouldRepaint(covariant BombExplosionPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.opacity != opacity ||
        oldDelegate.center != center;
  }
}
