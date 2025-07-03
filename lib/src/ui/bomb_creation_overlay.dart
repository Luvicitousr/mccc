import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🎇 Overlay de Criação da Bomba - SEM ANIMAÇÃO DE ESCALA
/// Exibe efeitos visuais quando uma bomba é criada a partir de uma combinação de 5+ peças
/// ✅ MODIFICAÇÕES APLICADAS:
/// - Remoção completa da animação de escala (_scaleAnimation)
/// - Remoção de todas as referências e dependências da escala
/// - Simplificação do código mantendo apenas rotação e brilho
class BombCreationOverlay extends StatefulWidget {
  final Offset position;
  final VoidCallback? onComplete;

  const BombCreationOverlay({
    super.key,
    required this.position,
    this.onComplete,
  });

  @override
  State<BombCreationOverlay> createState() => _BombCreationOverlayState();
}

class _BombCreationOverlayState extends State<BombCreationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // ❌ REMOVIDO: _scaleAnimation
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  // ✅ SIMPLIFICADO: Constantes de validação (removidas as relacionadas à escala)
  static const double _minAnimationValue = 0.0;
  static const double _maxAnimationValue = 1.0;
  static const double _minDuration = 0.1;
  static const double _maxDuration = 3.0;

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

      // ❌ REMOVIDO: Toda a configuração de _scaleAnimation

      // Animação de rotação com múltiplas voltas
      _rotateAnimation = Tween<double>(
        begin: 0.0,
        end: 6 * math.pi, // Três voltas completas
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      // Animação de brilho com pulsação intensa
      _glowAnimation = TweenSequence<double>([
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.4), weight: 10),
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.4, end: 1.0), weight: 10),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.6), weight: 10),
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.6, end: 1.0), weight: 10),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.8), weight: 15),
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.8, end: 1.0), weight: 15),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0), weight: 15),
      ]).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
    } catch (e) {
      print("[BOMB_CREATION] Erro ao inicializar animações: $e");
      _initializeFallbackAnimations();
    }
  }

  /// Animações de fallback (sem escala)
  void _initializeFallbackAnimations() {
    // ❌ REMOVIDO: Configuração de fallback para _scaleAnimation

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 4 * math.pi,
    ).animate(_controller);

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
      print("[BOMB_CREATION] Erro ao iniciar animação: $e");
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
          // ✅ SIMPLIFICADO: Removidas todas as referências à escala
          // ❌ REMOVIDO: final safeScale = _validateScaleValue(_scaleAnimation.value);
          final safeRotation = _validateRotationValue(_rotateAnimation.value);
          final safeGlow = _validateGlowValue(_glowAnimation.value);

          return CustomPaint(
            painter: BombCreationPainter(
              position: widget.position,
              // ❌ REMOVIDO: scale: safeScale,
              rotation: safeRotation,
              glowIntensity: safeGlow,
            ),
          );
        },
      ),
    );
  }

  // ❌ REMOVIDO: _validateScaleValue() - função completamente removida

  /// ✅ MANTIDO: Função específica para validação de brilho (0.0 - 1.0)
  double _validateGlowValue(double value) {
    if (value.isNaN || value.isInfinite) {
      return _minAnimationValue;
    }

    // Brilho deve ficar entre 0.0 e 1.0
    return value.clamp(_minAnimationValue, _maxAnimationValue);
  }

  /// ✅ MANTIDO: Validação específica para rotação (permite valores grandes)
  double _validateRotationValue(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }

    // Rotação pode ser qualquer valor finito
    return value;
  }
}

/// 🎨 Painter para efeito de criação da bomba - SEM ESCALA
class BombCreationPainter extends CustomPainter {
  final Offset position;
  // ❌ REMOVIDO: final double scale;
  final double rotation;
  final double glowIntensity;

  // ✅ SIMPLIFICADO: Constantes (removidas as relacionadas à escala)
  static const double _minGlow = 0.0;
  static const double _maxGlow = 1.0;
  // ❌ REMOVIDO: Constantes de escala (_minScale, _maxScale)

  BombCreationPainter({
    required this.position,
    // ❌ REMOVIDO: required this.scale,
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // ✅ SIMPLIFICADO: Validação sem escala
      // ❌ REMOVIDO: final safeScale = scale.clamp(_minScale, _maxScale);
      final safeGlow = glowIntensity.clamp(_minGlow, _maxGlow);
      final safeRotation = rotation.isFinite ? rotation : 0.0;

      if (safeGlow <= 0.0) {
        return; // Não desenha se brilho inválido
      }

      // Salva estado do canvas
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(safeRotation);
      // ❌ REMOVIDO: canvas.scale(safeScale);

      // Sistema de brilho em camadas (sem escala)
      _drawLayeredGlow(canvas, safeGlow);

      // Círculo central com gradiente dinâmico (sem escala)
      _drawCentralCircle(canvas, safeGlow);

      // Raios (sem escala dinâmica)
      _drawEnhancedRays(canvas, safeGlow);

      // Partículas orbitais (sem escala)
      _drawOrbitalParticles(canvas, safeGlow);

      // Anéis de energia (sem escala)
      _drawEnergyRings(canvas, safeGlow);

      // Restaura estado do canvas
      canvas.restore();
    } catch (e) {
      print("[BOMB_CREATION_PAINTER] Erro ao renderizar: $e");
      _drawFallbackEffect(canvas);
    }
  }

  /// Sistema de brilho em camadas (sem dependência de escala)
  void _drawLayeredGlow(Canvas canvas, double glowIntensity) {
    try {
      // Brilho externo (tamanho fixo)
      final outerGlowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(glowIntensity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35.0);

      canvas.drawCircle(Offset.zero, 80.0, outerGlowPaint);

      // Brilho médio
      final middleGlowPaint = Paint()
        ..color = const Color(0xFFFFE082).withOpacity(glowIntensity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);

      canvas.drawCircle(Offset.zero, 60.0, middleGlowPaint);

      // Brilho interno (mais intenso)
      final innerGlowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(glowIntensity * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

      canvas.drawCircle(Offset.zero, 40.0, innerGlowPaint);
    } catch (e) {
      print("[BOMB_CREATION_PAINTER] Erro ao desenhar brilho: $e");
    }
  }

  /// Círculo central com gradiente dinâmico (tamanho fixo)
  void _drawCentralCircle(Canvas canvas, double glowIntensity) {
    try {
      final gradient = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF).withOpacity(glowIntensity * 0.9),
          const Color(0xFFFFE082).withOpacity(glowIntensity * 0.8),
          const Color(0xFFFFD700).withOpacity(glowIntensity * 0.7),
          const Color(0xFFFF8F00).withOpacity(glowIntensity * 0.5),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );

      final circlePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset.zero, radius: 35.0),
        );

      canvas.drawCircle(Offset.zero, 35.0, circlePaint);
    } catch (e) {
      print("[BOMB_CREATION_PAINTER] Erro ao desenhar círculo central: $e");
    }
  }

  /// Raios com tamanho fixo (sem escala dinâmica)
  void _drawEnhancedRays(Canvas canvas, double glowIntensity) {
    try {
      final rayPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(glowIntensity * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0; // ✅ FIXO: Sem multiplicação por escala

      const rayCount = 16;
      const innerRadius = 35.0;
      const outerRadius = 100.0; // ✅ FIXO: Sem multiplicação por escala

      for (int i = 0; i < rayCount; i++) {
        final angle = (i * 2 * math.pi) / rayCount;
        final startX = math.cos(angle) * innerRadius;
        final startY = math.sin(angle) * innerRadius;
        final endX = math.cos(angle) * outerRadius;
        final endY = math.sin(angle) * outerRadius;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          rayPaint,
        );
      }
    } catch (e) {
      print("[BOMB_CREATION_PAINTER] Erro ao desenhar raios: $e");
    }
  }

  /// Partículas orbitais com tamanho fixo (sem escala)
  void _drawOrbitalParticles(Canvas canvas, double glowIntensity) {
    try {
      const particleCount = 12;
      const orbitRadius = 60.0; // ✅ FIXO: Sem multiplicação por escala

      for (int i = 0; i < particleCount; i++) {
        final angle = (i * 2 * math.pi) / particleCount + (rotation * 0.3);
        final x = math.cos(angle) * orbitRadius;
        final y = math.sin(angle) * orbitRadius;

        final particlePaint = Paint()
          ..color = const Color(0xFFFFE082).withOpacity(glowIntensity * 0.8);

        canvas.drawCircle(
          Offset(x, y),
          5.0, // ✅ FIXO: Sem multiplicação por escala
          particlePaint,
        );
      }
    } catch (e) {
      print("[BOMB_CREATION_PAINTER] Erro ao desenhar partículas orbitais: $e");
    }
  }

  /// Anéis de energia com tamanho fixo (sem escala)
  void _drawEnergyRings(Canvas canvas, double glowIntensity) {
    try {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(glowIntensity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Múltiplos anéis concêntricos com tamanho fixo
      for (int i = 1; i <= 3; i++) {
        final ringRadius =
            50.0 + (i * 15.0); // ✅ FIXO: Sem multiplicação por escala
        canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
      }
    } catch (e) {
      print("[BOMB_CREATION_PAINTER] Erro ao desenhar anéis de energia: $e");
    }
  }

  /// Efeito de fallback (sem escala)
  void _drawFallbackEffect(Canvas canvas) {
    try {
      canvas.save();
      canvas.translate(position.dx, position.dy);

      final fallbackPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.7);

      canvas.drawCircle(Offset.zero, 30.0, fallbackPaint);
      canvas.restore();
    } catch (e) {
      print("[BOMB_CREATION_PAINTER] Erro no fallback: $e");
    }
  }

  @override
  bool shouldRepaint(covariant BombCreationPainter oldDelegate) {
    // ❌ REMOVIDO: oldDelegate.scale != scale ||
    return oldDelegate.rotation != rotation ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}
