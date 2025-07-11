import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_state_manager.dart'; // ✅ 1. IMPORTE O GERENCIADOR

/// Zen Garden Decorative Elements
/// Adds wooden structures, pathways, and meditation spots to the garden
class ZenGardenElements extends Component with HasGameRef {
  // Variáveis para guardar cada um dos seus sprites
  late final Sprite _bamboosSprite;
  late final Sprite _lanternSprite;
  late final Sprite _stoneSprite;
  late final Sprite _sakuraBranchRightSprite;
  late final Sprite _sakuraBranchLeftSprite;

  // ✅ 2. ADICIONE AS VARIÁVEIS PARA O OVO
  late final Sprite _eggSprite;
  bool _isEggVisible = false;
  final List<Vector2> _bridgePositions = [];
  final List<Vector2> _pathwayPositions = [];
  final List<Vector2> _meditationSpotPositions = [];
  final List<Vector2> _lanternPositions = [];

  // Animation controllers for subtle movements
  double _time = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Carrega cada uma das suas novas imagens
    _bamboosSprite = await Sprite.load('garden_elements/bamboos.png');
    _lanternSprite = await Sprite.load('garden_elements/lantern.png');
    _stoneSprite = await Sprite.load('garden_elements/stone.png');
    _sakuraBranchRightSprite = await Sprite.load(
      'garden_elements/sakura_branch_right.png',
    );
    _sakuraBranchLeftSprite = await Sprite.load(
      'garden_elements/sakura_branch_left.png',
    );

    // ✅ 3. CARREGUE O SPRITE DO OVO E VERIFIQUE O ESTADO
    try {
      _eggSprite = await Sprite.load('garden_elements/egg_sprite.png');
    } catch (e) {
      print("Erro ao carregar o sprite do ovo: $e. Usando um placeholder.");
      // Cria um sprite de fallback caso a imagem não exista
      _eggSprite = await Sprite.load('folha.png');
    }

    // Verifica no GameStateManager se o ovo deve ser exibido
    _isEggVisible = GameStateManager.instance.isZenGardenEggUnlocked();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Você pode ajustar as posições e tamanhos para encaixar no seu design.

    final screenSize = gameRef.size;

    // Renderiza a lanterna
    _lanternSprite.render(
      canvas,
      position: Vector2(screenSize.x * 0.45, screenSize.y * 0.5),
      size: Vector2(
        76.8 / 0.2,
        140.8 / 0.2,
      ), // Ajuste o tamanho conforme necessário
      anchor: Anchor.center,
    );

    // Renderiza os bambus no canto inferior esquerdo
    _bamboosSprite.render(
      canvas,
      position: Vector2(0, screenSize.y),
      size: Vector2(76.8 / 0.2, 140.8 / 0.2), // Ajuste o tamanho
      anchor: Anchor.bottomLeft,
    );

    // Renderiza o galho de sakura no canto superior direito
    _sakuraBranchRightSprite.render(
      canvas,
      position: Vector2(screenSize.x, 0),
      size: Vector2(76.8 / 0.5, 140.8 / 0.5), // Ajuste o tamanho
      anchor: Anchor.topRight,
    );

    _sakuraBranchLeftSprite.render(
      canvas,
      position: Vector2(screenSize.x * 0.34, 0),
      size: Vector2(76.8 / 0.5, 140.8 / 0.5), // Ajuste o tamanho
      anchor: Anchor.topRight,
    );

    // Renderiza as pedras na parte inferior direita
    _stoneSprite.render(
      canvas,
      position: Vector2(screenSize.x, screenSize.y),
      size: Vector2(76.8 / 0.2, 140.8 / 0.2), // Ajuste o tamanho
      anchor: Anchor.bottomRight,
    );

    // ✅ 4. RENDERIZE O OVO SE ELE ESTIVER VISÍVEL
    if (_isEggVisible) {
      // Desenha o ovo em uma posição de destaque no jardim
      _eggSprite.render(
        canvas,
        position: Vector2(
          screenSize.x * 0.5,
          screenSize.y * 0.65,
        ), // Posição central, um pouco para baixo
        size: Vector2(120, 120), // Tamanho do ovo
        anchor: Anchor.center,
      );
    }
  }
}

/// Zen Garden Interactive Elements
/// Handles interaction with garden elements
class ZenGardenInteractions extends Component with HasGameRef {
  final List<Vector2> _interactiveSpots = [];
  bool _isInteracting = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeInteractiveSpots();
  }

  void _initializeInteractiveSpots() {
    final size = gameRef.size;

    // Define areas where players can interact
    _interactiveSpots.addAll([
      Vector2(size.x * 0.15, size.y * 0.25), // Meditation spot 1
      Vector2(size.x * 0.85, size.y * 0.35), // Meditation spot 2
      Vector2(size.x * 0.25, size.y * 0.75), // Meditation spot 3
      Vector2(size.x * 0.75, size.y * 0.65), // Meditation spot 4
      Vector2(size.x * 0.5, size.y * 0.5), // Center garden
    ]);
  }

  /// Check if a position is near an interactive spot
  bool isNearInteractiveSpot(Vector2 position) {
    const interactionRadius = 50.0;

    for (final spot in _interactiveSpots) {
      if (position.distanceTo(spot) < interactionRadius) {
        return true;
      }
    }
    return false;
  }

  /// Get the closest interactive spot to a position
  Vector2? getClosestInteractiveSpot(Vector2 position) {
    Vector2? closest;
    double closestDistance = double.infinity;

    for (final spot in _interactiveSpots) {
      final distance = position.distanceTo(spot);
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = spot;
      }
    }

    return closest;
  }

  /// Trigger interaction at a specific spot
  void triggerInteraction(Vector2 position) {
    if (_isInteracting) return;

    final closestSpot = getClosestInteractiveSpot(position);
    if (closestSpot != null) {
      _isInteracting = true;

      // Play meditation bell sound
      // ZenSoundEffect.meditationBell.play();

      // Add visual feedback
      _showInteractionEffect(closestSpot);

      // Reset interaction state after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isInteracting = false;
      });
    }
  }

  void _showInteractionEffect(Vector2 position) {
    // Add a ripple effect or particle system at the interaction point
    // This would be implemented with Flame's particle system
    print('Interaction triggered at: $position');
  }
}

/// Zen Garden Level Design Helper
/// Provides utilities for creating balanced level layouts
class ZenGardenLevelDesign {
  /// Create a balanced layout with strategic placement
  static List<List<int>> createBalancedLayout({
    required int width,
    required int height,
    double obstacleDensity = 0.15,
    double meditationSpotDensity = 0.1,
  }) {
    final layout = List.generate(
      height,
      (y) => List.generate(width, (x) => 1), // Start with all playable spaces
    );

    // Add strategic obstacles
    _addStrategicObstacles(layout, obstacleDensity);

    // Add meditation spots (special spaces)
    _addMeditationSpots(layout, meditationSpotDensity);

    return layout;
  }

  static void _addStrategicObstacles(List<List<int>> layout, double density) {
    final random = math.Random();
    final totalSpaces = layout.length * layout[0].length;
    final obstacleCount = (totalSpaces * density).round();

    for (int i = 0; i < obstacleCount; i++) {
      int attempts = 0;
      while (attempts < 10) {
        final x = random.nextInt(layout[0].length);
        final y = random.nextInt(layout.length);

        // Don't block the center area
        final centerX = layout[0].length ~/ 2;
        final centerY = layout.length ~/ 2;
        final distanceFromCenter = math.sqrt(
          math.pow(x - centerX, 2) + math.pow(y - centerY, 2),
        );

        if (distanceFromCenter > 2 && layout[y][x] == 1) {
          layout[y][x] = 0; // Wall/obstacle
          break;
        }
        attempts++;
      }
    }
  }

  static void _addMeditationSpots(List<List<int>> layout, double density) {
    final random = math.Random();
    final totalSpaces = layout.length * layout[0].length;
    final spotCount = (totalSpaces * density).round();

    for (int i = 0; i < spotCount; i++) {
      int attempts = 0;
      while (attempts < 10) {
        final x = random.nextInt(layout[0].length);
        final y = random.nextInt(layout.length);

        if (layout[y][x] == 1) {
          layout[y][x] = 3; // Meditation spot (special type)
          break;
        }
        attempts++;
      }
    }
  }

  /// Validate that the layout has sufficient playable space
  static bool validateLayout(List<List<int>> layout) {
    int playableSpaces = 0;
    int totalSpaces = 0;

    for (final row in layout) {
      for (final cell in row) {
        totalSpaces++;
        if (cell == 1 || cell == 3) {
          // Playable or meditation spot
          playableSpaces++;
        }
      }
    }

    final playableRatio = playableSpaces / totalSpaces;
    return playableRatio >= 0.6; // At least 60% should be playable
  }
}
