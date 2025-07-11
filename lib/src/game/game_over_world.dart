import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math; // ✅ CORREÇÃO: Importar a biblioteca de matemática
import 'candy_game.dart'; // Importe para ter a referência do jogo

// ✅ CORREÇÃO 1: Adicionar as importações que faltam.
import 'package:flame/particles.dart';
import 'package:flame/text.dart';
import 'custom_button.dart';

class GameOverWorld extends Component with HasGameRef<CandyGame> {
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  GameOverWorld({required this.onRestart, required this.onMenu});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // ✅ ADICIONE ESTES PRINTS PARA DEPURAÇÃO
    print('--- DEBUG: GameOverWorld.onLoad() iniciado.');

    print('--- DEBUG: Carregando game_over_background.jpg...');

    // 1. FUNDO (Substitua a animação de água por algo mais leve por enquanto)
    // Uma imagem estática ou uma animação de sprites é muito mais leve.
    final background = await Sprite.load('game_over_background.png'); // Exemplo
    print('--- DEBUG: Background CARREGADO com sucesso.');

    print('--- DEBUG: Carregando folha.png...');
    final leafSprite = await Sprite.load('folha.png');
    print('--- DEBUG: Folha CARREGADA com sucesso.');
    add(SpriteComponent(sprite: background, size: gameRef.size, priority: -1));

    // 2. TEXTO "FIM DE JOGO"
    final titleStyle = TextPaint(
      style: const TextStyle(
        fontSize: 64.0,
        fontFamily: 'NotoSans', // Use sua fonte
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    // 3. BOTÕES (Usando componentes do Flame)
    final buttonSize = Vector2(200.0, 50.0);

    // Botão Reiniciar
    add(
      CustomButton(
        text: 'Reiniciar',
        onPressed: onRestart,
        color: Colors.green,
        size: buttonSize,
        anchor: Anchor.center,
        position: Vector2(gameRef.size.x / 2.0, gameRef.size.y * 0.6),
      ),
    );

    // Botão Menu
    add(
      CustomButton(
        text: 'Menu',
        onPressed: onMenu,
        color: Colors.blue,
        size: buttonSize,
        anchor: Anchor.center,
        position: Vector2(gameRef.size.x / 2.0, gameRef.size.y * 0.7),
      ),
    );

    // 4. EFEITO DE FOLHAS (Usando o sistema de partículas do Flame - MUITO mais performático)
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 30,
          lifespan: 12.0, // Aumenta o tempo de vida para a queda mais lenta
          generator: (i) {
            // Gera uma posição e velocidade aleatórias para cada folha
            final initialX = gameRef.size.x * math.Random().nextDouble();

            // ✅ Define uma velocidade de queda mais lenta e aleatória, como no exemplo
            final fallSpeed = 60.0 + math.Random().nextDouble() * 50.0;

            return _FallingLeafParticle(
              sprite: leafSprite,
              initialPosition: Vector2(initialX, -20.0),

              // Passa a altura da tela para a partícula saber quando começar o fade
              screenHeight: gameRef.size.y,

              // Passa a velocidade de queda para a partícula
              speed: fallSpeed,
            );
          },
        ),
      ),
    );
  }
}

/// Esta classe usa `ComputedParticle` para nos dar controle total
/// sobre a renderização e o movimento da folha em cada frame.
class _FallingLeafParticle extends Particle {
  final Sprite sprite;
  final Vector2 initialPosition;
  final double screenHeight; // Precisa saber a altura da tela
  final double speed; // Agora usa uma velocidade de queda constante

  final double _rotationSpeed;
  final double _swayAmplitude;
  final double _swayFrequency;

  // Variáveis internas para controlar a posição e rotação
  double _x;
  double _y;
  double _rotation = 0;

  // ✅ PASSO 1: Adicione uma variável para controlar o tempo.
  double _elapsedTime = 0.0;

  // Variáveis de Estado para o Fade-Out
  bool _isFading = false;
  final double _fadeDuration = 2.0; // Quanto tempo o fade dura
  double _fadeTimer = 0.0;
  final Paint _paint = Paint(); // Usa um único objeto Paint para eficiência

  _FallingLeafParticle({
    required this.sprite,
    required this.initialPosition,
    required this.screenHeight,
    required this.speed, // Recebe a velocidade como parâmetro
    double? lifespan,
  }) : _x = initialPosition.x,
       _y = initialPosition.y,

       // Inicializa valores aleatórios para cada folha
       _rotationSpeed = (math.Random().nextDouble() - 0.5) * 4.0,
       _swayAmplitude = 30.0 + math.Random().nextDouble() * 30.0,
       _swayFrequency = 2.0 + math.Random().nextDouble() * 2.0,
       super(lifespan: lifespan);

  @override
  void update(double dt) {
    // Chama o update da classe pai para controlar o tempo de vida (age)
    super.update(dt);

    // ✅ PASSO 2: Incremente nosso próprio contador de tempo.
    _elapsedTime += dt;

    // A posição vertical agora é atualizada pela velocidade constante, sem gravidade
    _y += speed * dt;
    _x =
        initialPosition.x +
        math.sin(_elapsedTime * _swayFrequency) * _swayAmplitude;
    _rotation += _rotationSpeed * dt;

    // Começa a desaparecer quando a folha atinge 75% da parte inferior da tela
    if (!_isFading && _y > screenHeight * 0.75) {
      _isFading = true;
    }

    if (_isFading) {
      _fadeTimer += dt;
      // Calcula a opacidade com base no tempo de fade
      final opacity = (1.0 - (_fadeTimer / _fadeDuration)).clamp(0.0, 1.0);
      _paint.color = Colors.white.withOpacity(opacity);
    }
  }

  @override
  void render(Canvas c) {
    c.save();

    // Calcula a posição final para renderização, incluindo a oscilação
    final swayOffset = math.sin(_elapsedTime * _swayFrequency) * _swayAmplitude;
    // Move o canvas para a posição calculada
    c.translate(_x + swayOffset, _y);
    c.rotate(_rotation);
    // Desenha o sprite no centro da posição
    sprite.render(
      c,
      size: Vector2.all(32.0),
      anchor: Anchor.center,

      // Usa o objeto Paint que agora contém a opacidade correta
      overridePaint: _paint,
    );
    c.restore();
  }
}
