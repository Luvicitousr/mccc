import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Zen Garden Background Component
/// Creates a serene Japanese garden environment with:
/// - Raked sand patterns (karesansui)
/// - Carefully placed rocks
/// - Bamboo elements
/// - Atmospheric lighting and particles
class ZenGardenBackground extends Component with HasGameRef {
  late final Sprite _sandTexture;
  late final Sprite _bambooSprite;

  final List<Rect> _rockPositions = [];
  final List<Rect> _bambooPositions = [];

  // Atmospheric effects
  late final ParticleSystemComponent _windParticles;
  late final ParticleSystemComponent _mistParticles;

  // Flag para saber se os sprites foram carregados com sucesso
  bool _spritesLoaded = false;

  // Lighting effects
  late final Component _ambientLighting;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // O ParallaxComponent gerencia múltiplas camadas de imagens de fundo
    // que se movem em velocidades diferentes para criar um efeito de profundidade.
    final parallax = await gameRef.loadParallaxComponent(
      [
        // Cada ParallaxImageData é uma camada do fundo.
        // A ordem importa: a primeira é a mais distante.
        ParallaxImageData('garden_elements/sky.png'),
        ParallaxImageData('garden_elements/ground.png'),
      ],
      // Define a imagem base para o cálculo de tamanho.
      baseVelocity: Vector2.zero(), // Fundo estático por enquanto
      // Multiplicador de velocidade para cada camada (não usado com baseVelocity zero,
      // mas útil se você mover a câmera no futuro).
      velocityMultiplierDelta: Vector2(1.2, 1.2),
    );

    // Adiciona o componente de parallax ao nosso componente de fundo.
    add(parallax);

    // Load sprites (we'll create placeholder sprites for now)
    await _loadSprites();

    // Só inicializa os elementos se os sprites foram carregados
    if (_spritesLoaded) {
      _initializeGardenElements();
    }

    // Add atmospheric effects
    _addAtmosphericEffects();

    // Add ambient lighting
    _addAmbientLighting();
  }

  Future<void> _loadSprites() async {
    try {
      // For now, we'll use existing assets or create gradients
      // In a real implementation, you'd have specific Zen garden sprites
      _sandTexture = await Sprite.load(
        'garden_elements/ground.png',
      ); // Placeholder
      _bambooSprite = await Sprite.load(
        'garden_elements/bamboo.png',
      ); // Placeholder
      _spritesLoaded = true; // Marca que o carregamento foi bem-sucedido
    } catch (e) {
      print('❌ Erro ao carregar sprites para o Zen Garden: $e');

      // If sprites fail to load, we'll use gradients instead
      print('Zen garden sprites not found, using gradients: $e');
      _spritesLoaded = false; // Marca que o carregamento falhou
    }
  }

  void _initializeGardenElements() {
    final size = gameRef.size;

    // Posições para as rochas
    final rockPositions = [
      Vector2(size.x * 0.15, size.y * 0.25),
      Vector2(size.x * 0.85, size.y * 0.35),
      Vector2(size.x * 0.25, size.y * 0.75),
      Vector2(size.x * 0.75, size.y * 0.65),
    ];
    for (var pos in rockPositions) {
      // Criamos um Rect a partir da posição e o adicionamos à lista
      _rockPositions.add(
        Rect.fromCenter(center: pos.toOffset(), width: 80, height: 50),
      );
    }

    // Posições para os bambus
    final bambooPositions = [
      Vector2(size.x * -0.04, size.y * 0.5),
      Vector2(size.x * 1.06, size.y * 0.6),
    ];
    for (var pos in bambooPositions) {
      _bambooPositions.add(
        Rect.fromCenter(
          center: pos.toOffset(),
          width: size.x * 0.7,
          height: size.y * 0.7,
        ),
      );
    }
  }

  void _addAtmosphericEffects() {
    final size = gameRef.size;

    // Wind particles (gentle floating elements)
    _windParticles = ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 8.0,
        generator: (i) => AcceleratedParticle(
          speed: Vector2(
            math.Random().nextDouble() * 20 - 10,
            math.Random().nextDouble() * 10 - 5,
          ),
          acceleration: Vector2.zero(),
          position: Vector2(
            math.Random().nextDouble() * size.x,
            math.Random().nextDouble() * size.y,
          ),
          child: CircleParticle(
            radius: math.Random().nextDouble() * 2 + 1,
            paint: Paint()
              ..color = Colors.white.withOpacity(0.3)
              ..style = PaintingStyle.fill,
          ),
        ),
      ),
    );

    // Mist particles (subtle fog effect)
    _mistParticles = ParticleSystemComponent(
      particle: Particle.generate(
        count: 15,
        lifespan: 12.0,
        generator: (i) => AcceleratedParticle(
          speed: Vector2(
            math.Random().nextDouble() * 5 - 2.5,
            math.Random().nextDouble() * 3 - 1.5,
          ),
          acceleration: Vector2.zero(),
          position: Vector2(
            math.Random().nextDouble() * size.x,
            math.Random().nextDouble() * size.y,
          ),
          child: CircleParticle(
            radius: math.Random().nextDouble() * 15 + 10,
            paint: Paint()
              ..color = Colors.white.withOpacity(0.1)
              ..style = PaintingStyle.fill,
          ),
        ),
      ),
    );

    add(_windParticles);
    add(_mistParticles);
  }

  void _addAmbientLighting() {
    _ambientLighting = Component();
    add(_ambientLighting);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Só tenta renderizar se os sprites foram carregados
    if (!_spritesLoaded) {
      final size = gameRef.size;

      // Draw raked sand patterns (karesansui)
      _drawRakedSandPatterns(canvas, size);

      // Draw ambient lighting overlay
      _drawAmbientLighting(canvas, size);
      return;
    }

    // Desenha a textura de areia de fundo
    _sandTexture.render(canvas, size: gameRef.size);

    // Desenha os bambus
    for (final rect in _bambooPositions) {
      _bambooSprite.renderRect(canvas, rect);
    }

    // Desenha um efeito de vinheta para dar profundidade
    _drawVignette(canvas);
  }

  void _drawVignette(Canvas canvas) {
    final size = gameRef.size;
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
      stops: const [0.6, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(size.toRect());
    canvas.drawRect(size.toRect(), paint);
  }

  void _drawRakedSandPatterns(Canvas canvas, Vector2 size) {
    final paint = Paint()
      ..color =
          const Color(0xFFF5F5DC) // Sand color
      ..style = PaintingStyle.fill;

    // Base sand layer
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    // Raked patterns (concentric circles representing ripples)
    final patternPaint = Paint()
      ..color =
          const Color(0xFFE8E8D0) // Slightly darker sand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.x / 2, size.y / 2);
    final maxRadius = math.min(size.x, size.y) / 3;

    for (int i = 1; i <= 8; i++) {
      final radius = (maxRadius / 8) * i;
      canvas.drawCircle(center, radius, patternPaint);
    }

    // Add some straight lines for variety
    final linePaint = Paint()
      ..color = const Color(0xFFE8E8D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Horizontal lines
    for (int i = 1; i <= 5; i++) {
      final y = (size.y / 6) * i;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), linePaint);
    }
  }

  void _drawAmbientLighting(Canvas canvas, Vector2 size) {
    // Create a subtle vignette effect
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.1),
        Colors.black.withOpacity(0.2),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

/// Zen Garden Color Palette
class ZenColors {
  // Earth tones
  static const Color sandBeige = Color(0xFFF5F5DC);
  static const Color stoneGray = Color(0xFF696969);
  static const Color earthBrown = Color(0xFF8B4513);

  // Natural greens
  static const Color bambooGreen = Color(0xFF228B22);
  static const Color leafGreen = Color(0xFF32CD32);
  static const Color mossGreen = Color(0xFF6B8E23);

  // Muted tones
  static const Color softGray = Color(0xFFD3D3D3);
  static const Color warmBeige = Color(0xFFE8E8D0);
  static const Color coolGray = Color(0xFFB0C4DE);

  // Atmospheric colors
  static const Color mistWhite = Color(0xFFF8F8FF);
  static const Color shadowGray = Color(0xFF2F4F4F);
}

/// Zen Garden Gradients
class ZenGradients {
  static const LinearGradient zenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ZenColors.mistWhite,
      ZenColors.sandBeige,
      ZenColors.warmBeige,
      ZenColors.softGray,
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient sandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ZenColors.sandBeige, ZenColors.warmBeige, ZenColors.earthBrown],
  );

  static const LinearGradient mistGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ZenColors.mistWhite, Colors.transparent, ZenColors.coolGray],
  );
}
