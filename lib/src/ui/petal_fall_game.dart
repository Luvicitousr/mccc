// lib/src/ui/petal_fall_game.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'petal_component.dart';

class PetalFallGame extends FlameGame {
  late Sprite petalSprite;
  final Random _rand = Random();

  // ✅ CORREÇÃO 1: Sobrescreva o método backgroundColor para definir a cor de fundo.
  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Carrega a imagem da pétala uma única vez.
    petalSprite = await Sprite.load('sakura.png');

    // Adiciona um TimerComponent que irá gerar pétalas continuamente.
    add(
      TimerComponent(
        period: 0.3, // Gera uma nova pétala a cada 0.3 segundos.
        repeat: true,
        onTick: _spawnPetal,
      ),
    );
  }

  void _spawnPetal() {
    // Posição X inicial aleatória no topo da tela.
    final initialX = _rand.nextDouble() * size.x;

    // Tamanho aleatório para a pétala.
    final randomSize = _rand.nextDouble() * 30 + 20; // Tamanho entre 20 e 50

    final petal = PetalComponent(
      sprite: petalSprite,
      position: Vector2(initialX, -randomSize), // Começa um pouco acima da tela.
      size: Vector2.all(randomSize),
      // Parâmetros de movimento aleatórios para cada pétala.
      speed: _rand.nextDouble() * 100 + 80,         // Velocidade de queda
      rotationSpeed: _rand.nextDouble() * 2 - 1,   // Velocidade de rotação
      swayAmplitude: _rand.nextDouble() * 40 + 20, // Amplitude da oscilação
      swaySpeed: _rand.nextDouble() * 1.5 + 0.5,     // Velocidade da oscilação
    );

    add(petal);
  }
}