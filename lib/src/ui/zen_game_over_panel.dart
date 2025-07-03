import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'i18n/app_localizations.dart';
import 'smooth_page_transitions.dart';

/// 🏮 Zen Game Over Panel - Inspirado em Jardins Zen Japoneses
///
/// Um painel de "Game Over" que transmite serenidade e aceitação
/// ao invés de derrota, seguindo princípios estéticos zen japoneses.
class ZenGameOverPanel extends StatefulWidget {
  final dynamic game;
  final VoidCallback? onRestart;
  final VoidCallback? onMenu;

  const ZenGameOverPanel({
    super.key,
    required this.game,
    this.onRestart,
    this.onMenu,
  });

  @override
  State<ZenGameOverPanel> createState() => _ZenGameOverPanelState();
}

class _ZenGameOverPanelState extends State<ZenGameOverPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Animações para elementos zen
  late Timer _rippleTimer;
  final List<RippleCircle> _ripples = [];
  final List<FallingLeaf> _leaves = [];

  // Controladores para elementos interativos
  bool _isButtonHovered = false;

  // ✅ PASSO 1: Declarar uma variável para guardar a mensagem.
  late final String _selectedZenMessage;

  @override
  void initState() {
    super.initState();

    // ✅ PASSO 2: Escolher a mensagem UMA VEZ e guardá-la.
    _selectedZenMessage = _getZenMessage();
    _initializeAnimations();
    _startAnimations();

    // Feedback tátil suave
    HapticFeedback.lightImpact();

    // Inicializa elementos zen
    _initializeZenElements();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutQuint),
    ));
  }

  void _initializeZenElements() {
    // Cria ondulações iniciais
    _createInitialRipples();

    // Configura timer para adicionar novas ondulações
    _rippleTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      _addNewRipple();
    });

    // Adiciona folhas caindo
    _createFallingLeaves();
  }

  void _createInitialRipples() {
    // Adiciona 3 ondulações iniciais com diferentes tamanhos
    _ripples.add(RippleCircle(
      position: const Offset(0.3, 0.4),
      maxRadius: 120,
      duration: 8000,
      delay: 500,
    ));

    _ripples.add(RippleCircle(
      position: const Offset(0.7, 0.6),
      maxRadius: 100,
      duration: 7000,
      delay: 1500,
    ));

    _ripples.add(RippleCircle(
      position: const Offset(0.5, 0.3),
      maxRadius: 80,
      duration: 6000,
      delay: 2500,
    ));
  }

  void _addNewRipple() {
    if (!mounted) return;

    setState(() {
      // Adiciona uma nova ondulação em posição aleatória
      final random = math.Random();

      _ripples.add(RippleCircle(
        position: Offset(
          0.2 + random.nextDouble() * 0.6,
          0.2 + random.nextDouble() * 0.6,
        ),
        maxRadius: 60 + random.nextDouble() * 80,
        duration: 5000 + random.nextInt(3000),
        delay: random.nextInt(1000),
      ));

      // Remove ondulações antigas para evitar acúmulo
      if (_ripples.length > 5) {
        _ripples.removeAt(0);
      }
    });
  }

  void _createFallingLeaves() {
    // Cria 8 folhas caindo com diferentes propriedades
    final random = math.Random();

    for (int i = 0; i < 8; i++) {
      _leaves.add(FallingLeaf(
        initialPosition: Offset(
          0.1 + random.nextDouble() * 0.8,
          -0.2 - random.nextDouble() * 0.3,
        ),
        fallSpeed: 0.03 + random.nextDouble() * 0.02,
        swayAmplitude: 0.05 + random.nextDouble() * 0.05,
        swayFrequency: 1.0 + random.nextDouble() * 2.0,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.05,
        scale: 0.5 + random.nextDouble() * 0.5,
        type: LeafType.values[random.nextInt(LeafType.values.length)],
      ));
    }
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          return Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5F5F5), // Cinza muito claro
                  Color(0xFFF0F0F0), // Cinza claro
                  Color(0xFFE8E8E8), // Cinza suave
                ],
              ),
            ),
            child: Stack(
              children: [
                // Camada 1: Padrão de areia rastejada (karesansui)
                CustomPaint(
                  painter: SandPatternPainter(),
                  size: Size(screenWidth, screenHeight),
                ),

                // Camada 2: Ondulações zen
                CustomPaint(
                  painter: RipplesPainter(_ripples),
                  size: Size(screenWidth, screenHeight),
                ),

                // Camada 3: Folhas caindo
                CustomPaint(
                  painter:
                      FallingLeavesPainter(_leaves, screenWidth, screenHeight),
                  size: Size(screenWidth, screenHeight),
                ),

                // Camada 4: Conteúdo principal
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child:
                            _buildMainContent(l10n, screenWidth, screenHeight),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(
      AppLocalizations l10n, double screenWidth, double screenHeight) {
    return Center(
      child: Container(
        width: math.min(screenWidth * 0.85, 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título caligráfico
            _buildCalligraphicTitle(l10n),

            const SizedBox(height: 32),

            // Pedra zen
            _buildZenStone(),

            const SizedBox(height: 32),

            // Mensagem zen
            _buildZenMessage(l10n),

            const SizedBox(height: 40),

            // Botões de ação
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCalligraphicTitle(AppLocalizations l10n) {
    return Column(
      children: [
        // Texto caligráfico
        Text(
          l10n.gameOver,
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: 8,
            color: Color(0xFF333333),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        // Linha zen
        Container(
          width: 120,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFF8D6E63).withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZenStone() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF9E9E9E), // Cinza médio
            Color(0xFF757575), // Cinza escuro
          ],
          stops: [0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFBDBDBD).withOpacity(0.8), // Cinza claro
                const Color(0xFF9E9E9E).withOpacity(0.5), // Cinza médio
              ],
              stops: const [0.2, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZenMessage(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          _selectedZenMessage, // Usa a mensagem que foi guardada.
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: Color(0xFF5D4037),
            height: 1.8,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.continueJourney,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8D6E63),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildZenButton(
            label: l10n.menu,
            icon: Icons.home_outlined,
            isPrimary: false,
            onPressed: () => _handleMenuPress(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildZenButton(
            label: l10n.restart,
            icon: Icons.refresh_rounded,
            isPrimary: true,
            onPressed: () => _handleRestartPress(),
          ),
        ),
      ],
    );
  }

  Widget _buildZenButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF7CB342) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isPrimary ? const Color(0xFF7CB342) : const Color(0xFF8D6E63),
            width: 1.5,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF7CB342).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : const Color(0xFF8D6E63),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : const Color(0xFF8D6E63),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getZenMessage() {
    // Lista de mensagens zen para momentos de "game over"
    final zenMessages = [
      "Na derrota, encontramos sementes de crescimento.",
      "Cada fim é um novo começo no caminho zen.",
      "A água flui, as pedras permanecem. Ambas têm seu propósito.",
      "Aceite o momento presente como um presente.",
      "O caminho da harmonia continua além dos obstáculos.",
      "Como a lua entre nuvens, a vitória aparecerá novamente.",
      "Mesmo o bambu mais forte se curva antes de quebrar.",
      "Na quietude da derrota, encontramos nossa verdadeira força.",
    ];

    // Escolhe uma mensagem aleatória
    final random = math.Random();
    return zenMessages[random.nextInt(zenMessages.length)];
  }

  void _handleRestartPress() async {
    // Animação de saída
    await _animationController.reverse();

    if (widget.onRestart != null) {
      widget.onRestart!();
    } else {
      if (mounted) {
        // Implementação padrão se callback não for fornecido
        widget.game?.overlays.remove('gameOverPanel');
        widget.game?.resumeEngine();

        // Reinicia o nível atual
        Navigator.of(context).pushReplacement(
          SmoothPageTransitions.fadeTransition(
            const GameScreen(),
          ),
        );
      }
    }
  }

  void _handleMenuPress() async {
    // Animação de saída
    await _animationController.reverse();

    if (widget.onMenu != null) {
      widget.onMenu!();
    } else {
      if (mounted) {
        // Implementação padrão se callback não for fornecido
        widget.game?.overlays.remove('gameOverPanel');
        widget.game?.resumeEngine();

        // Volta para o menu principal
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/menu',
          (route) => false,
        );
      }
    }
  }
}

/// 🏞️ Painter para padrão de areia rastejada (karesansui)
class SandPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Padrão de ondas concêntricas
    for (int i = 0; i < 15; i++) {
      final path = Path();
      final y = size.height * 0.1 + (i * size.height * 0.06);

      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 10) {
        final waveY = y + math.sin(x * 0.03) * 3;
        path.lineTo(x, waveY);
      }

      canvas.drawPath(path, paint);
    }

    // Padrão circular em torno de pedras imaginárias
    final center1 = Offset(size.width * 0.3, size.height * 0.4);
    final center2 = Offset(size.width * 0.7, size.height * 0.6);

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        center1,
        i * 15.0,
        paint..color = const Color(0xFFBDBDBD).withOpacity(0.1 + (i * 0.02)),
      );

      canvas.drawCircle(
        center2,
        i * 12.0,
        paint..color = const Color(0xFFBDBDBD).withOpacity(0.1 + (i * 0.02)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🌊 Painter para ondulações zen
class RipplesPainter extends CustomPainter {
  final List<RippleCircle> ripples;

  RipplesPainter(this.ripples);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final ripple in ripples) {
      // Calcula progresso baseado no tempo
      final elapsedTime = now - ripple.startTime;

      // Aplica delay
      if (elapsedTime < ripple.delay) continue;

      final activeTime = elapsedTime - ripple.delay;
      final progress = (activeTime / ripple.duration).clamp(0.0, 1.0);

      // Calcula raio atual
      final currentRadius = ripple.maxRadius * progress;

      // Calcula opacidade (diminui conforme expande)
      final opacity = (1.0 - progress) * 0.3;

      // Desenha círculo
      final paint = Paint()
        ..color = const Color(0xFF8D6E63).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final center = Offset(
        size.width * ripple.position.dx,
        size.height * ripple.position.dy,
      );

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplesPainter oldDelegate) => true;
}

/// 🍂 Painter para folhas caindo
class FallingLeavesPainter extends CustomPainter {
  final List<FallingLeaf> leaves;
  final double screenWidth;
  final double screenHeight;

  FallingLeavesPainter(this.leaves, this.screenWidth, this.screenHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

    for (final leaf in leaves) {
      // Atualiza posição baseada no tempo
      final time = now * leaf.fallSpeed;
      final x = leaf.initialPosition.dx * screenWidth +
          math.sin(time * leaf.swayFrequency) *
              leaf.swayAmplitude *
              screenWidth;

      // Movimento vertical com aceleração suave
      final fallProgress = (time % 3.0) / 3.0;
      final easeInFall = fallProgress * fallProgress;
      final y = (leaf.initialPosition.dy + easeInFall) * screenHeight;

      // Rotação
      final rotation = leaf.initialRotation + (time * leaf.rotationSpeed);

      // Desenha folha
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(leaf.scale);

      _drawLeaf(canvas, leaf.type);

      canvas.restore();

      // Reseta folha se saiu da tela
      if (y > screenHeight * 1.1) {
        leaf.initialPosition = Offset(
          math.Random().nextDouble(),
          -0.2 - math.Random().nextDouble() * 0.3,
        );
        leaf.initialRotation = math.Random().nextDouble() * math.pi * 2;
      }
    }
  }

  void _drawLeaf(Canvas canvas, LeafType type) {
    final paint = Paint()
      ..color = _getLeafColor(type)
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (type) {
      case LeafType.maple:
        _drawMapleLeaf(path);
        break;
      case LeafType.ginkgo:
        _drawGinkgoLeaf(path);
        break;
      case LeafType.bamboo:
        _drawBambooLeaf(path);
        break;
      case LeafType.cherry:
        _drawCherryPetal(path);
        break;
    }

    canvas.drawPath(path, paint);

    // Adiciona nervuras para detalhe
    final detailPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    if (type != LeafType.cherry) {
      final detailPath = Path();
      detailPath.moveTo(0, 0);
      detailPath.lineTo(0, 10);
      canvas.drawPath(detailPath, detailPaint);
    }
  }

  void _drawMapleLeaf(Path path) {
    path.moveTo(0, -10);
    path.lineTo(8, -2);
    path.lineTo(10, -8);
    path.lineTo(6, 0);
    path.lineTo(10, 8);
    path.lineTo(0, 4);
    path.lineTo(-10, 8);
    path.lineTo(-6, 0);
    path.lineTo(-10, -8);
    path.lineTo(-8, -2);
    path.close();
  }

  void _drawGinkgoLeaf(Path path) {
    path.moveTo(0, -10);
    path.quadraticBezierTo(10, -5, 10, 5);
    path.quadraticBezierTo(5, 10, 0, 10);
    path.quadraticBezierTo(-5, 10, -10, 5);
    path.quadraticBezierTo(-10, -5, 0, -10);
    path.close();
  }

  void _drawBambooLeaf(Path path) {
    path.moveTo(0, -12);
    path.quadraticBezierTo(6, -6, 6, 0);
    path.quadraticBezierTo(6, 6, 0, 12);
    path.quadraticBezierTo(-6, 6, -6, 0);
    path.quadraticBezierTo(-6, -6, 0, -12);
    path.close();
  }

  void _drawCherryPetal(Path path) {
    path.moveTo(0, -8);
    path.quadraticBezierTo(8, -6, 8, 0);
    path.quadraticBezierTo(8, 6, 0, 8);
    path.quadraticBezierTo(-8, 6, -8, 0);
    path.quadraticBezierTo(-8, -6, 0, -8);
    path.close();
  }

  Color _getLeafColor(LeafType type) {
    switch (type) {
      case LeafType.maple:
        return const Color(0xFFE57373).withOpacity(0.7); // Vermelho suave
      case LeafType.ginkgo:
        return const Color(0xFFFFD54F).withOpacity(0.7); // Amarelo suave
      case LeafType.bamboo:
        return const Color(0xFFA5D6A7).withOpacity(0.7); // Verde suave
      case LeafType.cherry:
        return const Color(0xFFF8BBD0).withOpacity(0.7); // Rosa suave
    }
  }

  @override
  bool shouldRepaint(covariant FallingLeavesPainter oldDelegate) => true;
}

/// 🌊 Classe para ondulação zen
class RippleCircle {
  final Offset position; // Posição relativa (0-1)
  final double maxRadius; // Raio máximo em pixels
  final int duration; // Duração em milissegundos
  final int delay; // Atraso inicial em milissegundos
  final int startTime; // Tempo de início

  RippleCircle({
    required this.position,
    required this.maxRadius,
    required this.duration,
    this.delay = 0,
  }) : startTime = DateTime.now().millisecondsSinceEpoch;
}

/// 🍂 Classe para folha caindo
class FallingLeaf {
  Offset initialPosition; // Posição inicial relativa (0-1)
  final double fallSpeed; // Velocidade de queda
  final double swayAmplitude; // Amplitude de oscilação
  final double swayFrequency; // Frequência de oscilação
  final double rotationSpeed; // Velocidade de rotação
  final double scale; // Escala da folha
  double initialRotation; // Rotação inicial
  final LeafType type; // Tipo de folha

  FallingLeaf({
    required this.initialPosition,
    required this.fallSpeed,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.rotationSpeed,
    required this.scale,
    required this.type,
  }) : initialRotation = math.Random().nextDouble() * math.pi * 2;
}

/// 🍂 Tipos de folhas
enum LeafType {
  maple,
  ginkgo,
  bamboo,
  cherry,
}

/// 🎮 Tela de jogo placeholder
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogo'),
      ),
      body: const Center(
        child: Text('Tela do jogo'),
      ),
    );
  }
}
