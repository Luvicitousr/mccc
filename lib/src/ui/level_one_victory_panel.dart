import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../game/candy_game.dart';
import '../game/game_state_manager.dart';
import 'smooth_page_transitions.dart';

/// 🥚 Painel de vitória específico para o Nível 1 - VERSÃO CORRIGIDA PARA OVERFLOW
/// ✅ CORREÇÕES APLICADAS:
/// - Corrigido RenderFlex overflow de 4.9 pixels
/// - Layout completamente responsivo
/// - Melhor organização dos elementos
/// - Prevenção de overflow em diferentes tamanhos de tela
class LevelOneVictoryPanel extends StatefulWidget {
  final dynamic game; // CandyGame
  final VoidCallback? onContinue;
  final VoidCallback? onMenu;

  const LevelOneVictoryPanel({
    super.key,
    required this.game,
    this.onContinue,
    this.onMenu,
  });

  @override
  State<LevelOneVictoryPanel> createState() => _LevelOneVictoryPanelState();
}

class _LevelOneVictoryPanelState extends State<LevelOneVictoryPanel>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _eggController;
  late AnimationController _sparkleController;
  late AnimationController _petalsController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _eggBounceAnimation;
  late Animation<double> _eggGlowAnimation;
  late Animation<double> _sparkleAnimation;

  final GameStateManager _gameStateManager = GameStateManager.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();

    // Feedback tátil especial para primeira vitória
    HapticFeedback.heavyImpact();
  }

  void _initializeAnimations() {
    // Animação principal de entrada
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animação específica do ovo
    _eggController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animação dos brilhos
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animação das pétalas
    _petalsController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // Configurar animações principais
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
          ),
        );

    // Animações específicas do ovo
    _eggBounceAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _eggController, curve: Curves.elasticOut),
    );

    _eggGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _eggController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _mainController.forward();

    // Inicia animação do ovo após um delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _eggController.forward();
        _sparkleController.repeat(reverse: true);
        _petalsController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _eggController.dispose();
    _sparkleController.dispose();
    _petalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ CORREÇÃO PRINCIPAL: Layout responsivo baseado nas dimensões disponíveis
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        return Container(
          width: availableWidth,
          height: availableHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF8E1), // Dourado muito claro
                Color(0xFFFFF3C4), // Dourado suave
                Color(0xFFFFE082), // Dourado médio
              ],
            ),
          ),
          child: Stack(
            children: [
              // Pétalas flutuantes especiais
              _buildSpecialFloatingPetals(availableWidth, availableHeight),

              // Brilhos de fundo
              _buildBackgroundSparkles(availableWidth, availableHeight),

              // Conteúdo principal
              _buildResponsiveMainContent(availableWidth, availableHeight),

              // Efeitos de partículas douradas
              _buildGoldenParticles(availableWidth, availableHeight),
            ],
          ),
        );
      },
    );
  }

  /// ✅ CORREÇÃO: Pétalas responsivas
  Widget _buildSpecialFloatingPetals(double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: _petalsController,
      builder: (context, child) {
        return Stack(
          children: List.generate(12, (index) {
            final offset = (index * 0.25) % 1.0;
            final animationValue = (_petalsController.value + offset) % 1.0;

            return Positioned(
              left: (50.0 + (index * 60.0)) % screenWidth,
              top: -30 + (animationValue * (screenHeight + 60)),
              child: Transform.rotate(
                angle: animationValue * 2 * math.pi * 0.15,
                child: Opacity(
                  opacity: 0.4 + (math.sin(animationValue * math.pi) * 0.3),
                  child: Icon(
                    index % 3 == 0
                        ? Icons.local_florist
                        : index % 3 == 1
                        ? Icons.star
                        : Icons.auto_awesome,
                    color: index % 2 == 0
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFFFB7C5),
                    size: _getResponsiveSize(screenWidth, 16 + (index % 3) * 4),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// ✅ CORREÇÃO: Brilhos responsivos
  Widget _buildBackgroundSparkles(double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final progress = (_sparkleAnimation.value + (index * 0.2)) % 1.0;

            return Positioned(
              left: (index * screenWidth / 8) + (progress * 50),
              top:
                  screenHeight * 0.2 + (math.sin(progress * math.pi * 2) * 100),
              child: Opacity(
                opacity: 0.6 * (1.0 - progress),
                child: Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFFFFD700),
                  size: _getResponsiveSize(screenWidth, 20 + (progress * 10)),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// ✅ CORREÇÃO: Partículas responsivas
  Widget _buildGoldenParticles(double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(15, (index) {
            final progress = (_sparkleAnimation.value + (index * 0.15)) % 1.0;
            final angle = (index * 2 * math.pi / 15) + (progress * math.pi);

            final centerX = screenWidth / 2;
            final centerY = screenHeight / 2;
            final radius = _getResponsiveSize(
              screenWidth,
              150 + (progress * 100),
            );

            final x = centerX + math.cos(angle) * radius;
            final y = centerY + math.sin(angle) * radius;

            return Positioned(
              left: x - 5,
              top: y - 5,
              child: Opacity(
                opacity: 0.8 * (1.0 - progress),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// ✅ CORREÇÃO PRINCIPAL: Conteúdo principal responsivo
  Widget _buildResponsiveMainContent(
    double availableWidth,
    double availableHeight,
  ) {
    return SafeArea(
      child: Center(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildResponsiveVictoryCard(
                    availableWidth,
                    availableHeight,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// ✅ CORREÇÃO: Card de vitória responsivo que previne overflow
  Widget _buildResponsiveVictoryCard(
    double availableWidth,
    double availableHeight,
  ) {
    // Calcula margens responsivas
    final horizontalMargin = _getResponsiveMargin(availableWidth);
    final verticalMargin = _getResponsiveMargin(availableHeight);

    return Container(
      width: availableWidth - (horizontalMargin * 2),
      height: math.min(
        availableHeight - (verticalMargin * 2),
        availableHeight * 0.9,
      ),
      margin: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(_getResponsivePadding(availableWidth)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 5,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.6),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título especial
              _buildSpecialTitle(availableWidth),

              SizedBox(height: _getResponsiveSpacing(availableWidth, 20)),

              // Ovo principal - FOCAL POINT
              _buildEggReward(availableWidth),

              SizedBox(height: _getResponsiveSpacing(availableWidth, 24)),

              // Mensagem de recompensa
              _buildRewardMessage(availableWidth),

              SizedBox(height: _getResponsiveSpacing(availableWidth, 20)),

              // Subtítulo motivacional
              _buildMotivationalSubtitle(availableWidth),

              SizedBox(height: _getResponsiveSpacing(availableWidth, 32)),

              // Estatísticas do primeiro nível
              _buildFirstLevelStats(availableWidth),

              SizedBox(height: _getResponsiveSpacing(availableWidth, 32)),

              // Botões de ação
              _buildActionButtons(availableWidth),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ CORREÇÃO: Métodos responsivos
  double _getResponsiveMargin(double availableSpace) {
    if (availableSpace < 400) return 16.0;
    if (availableSpace < 600) return 24.0;
    return 32.0;
  }

  double _getResponsivePadding(double availableWidth) {
    if (availableWidth < 300) return 16.0;
    if (availableWidth < 400) return 20.0;
    return 28.0;
  }

  double _getResponsiveSpacing(double availableWidth, double baseSpacing) {
    if (availableWidth < 300) return baseSpacing * 0.7;
    if (availableWidth < 400) return baseSpacing * 0.85;
    return baseSpacing;
  }

  double _getResponsiveFontSize(double availableWidth, double baseFontSize) {
    if (availableWidth < 300) return baseFontSize * 0.8;
    if (availableWidth < 400) return baseFontSize * 0.9;
    if (availableWidth > 800) return baseFontSize * 1.1;
    return baseFontSize;
  }

  double _getResponsiveSize(double availableWidth, double baseSize) {
    if (availableWidth < 300) return baseSize * 0.7;
    if (availableWidth < 400) return baseSize * 0.85;
    if (availableWidth > 800) return baseSize * 1.2;
    return baseSize;
  }

  Widget _buildSpecialTitle(double availableWidth) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              color: const Color(0xFFFFD700),
              size: _getResponsiveSize(availableWidth, 28),
            ),
            SizedBox(width: _getResponsiveSpacing(availableWidth, 8)),
            Flexible(
              child: Text(
                'PARABÉNS',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(availableWidth, 24),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6F00),
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ),
            SizedBox(width: _getResponsiveSpacing(availableWidth, 8)),
            Icon(
              Icons.celebration,
              color: const Color(0xFFFFD700),
              size: _getResponsiveSize(availableWidth, 28),
            ),
          ],
        ),
        SizedBox(height: _getResponsiveSpacing(availableWidth, 8)),
        Container(
          height: 3,
          width: _getResponsiveSize(availableWidth, 120),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildEggReward(double availableWidth) {
    final imageSize = _getResponsiveSize(availableWidth, 140);

    return AnimatedBuilder(
      animation: _eggController,
      builder: (context, child) {
        return Column(
          children: [
            // Container com brilho para o ovo
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.3),
                    const Color(0xFFFFD700).withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFFD700,
                    ).withOpacity(0.4 * _eggGlowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Transform.scale(
                scale: _eggBounceAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/caged2_petal.png',
                      width: imageSize * 0.6,
                      height: imageSize * 0.6,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback para ícone se a imagem não carregar
                        return Icon(
                          Icons.egg,
                          size: imageSize * 0.6,
                          color: const Color(0xFFFFD700),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Brilhos ao redor do ovo
            AnimatedBuilder(
              animation: _sparkleAnimation,
              builder: (context, child) {
                return Stack(
                  children: List.generate(6, (index) {
                    final angle =
                        (index * math.pi * 2 / 6) +
                        (_sparkleAnimation.value * math.pi * 2);
                    final radius = _getResponsiveSize(availableWidth, 80);
                    final x = math.cos(angle) * radius;
                    final y = math.sin(angle) * radius;

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Opacity(
                        opacity: 0.7 * _sparkleAnimation.value,
                        child: Icon(
                          Icons.auto_awesome,
                          color: const Color(0xFFFFD700),
                          size: _getResponsiveSize(
                            availableWidth,
                            16 + (_sparkleAnimation.value * 8),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRewardMessage(double availableWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsivePadding(availableWidth),
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '🎉 VOCÊ GANHOU UM OVO! 🎉',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(availableWidth, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE65100),
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
          SizedBox(height: _getResponsiveSpacing(availableWidth, 8)),
          Text(
            'Sua recompensa especial!',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(availableWidth, 16),
              color: const Color(0xFFFF8F00),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalSubtitle(double availableWidth) {
    return Text(
      'Sua jornada zen começou com sabedoria.\nContinue jogando para coletar mais ovos especiais!',
      style: TextStyle(
        fontSize: _getResponsiveFontSize(availableWidth, 16),
        color: const Color(0xFF6D4C41),
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildFirstLevelStats(double availableWidth) {
    // Pega os dados do jogo atual
    final score = widget.game.currentScore.value;
    final movesUsed = widget.game.level.moves - widget.game.movesLeft.value;

    // ✅ Pega as estrelas salvas do GameStateManager
    final starsEarned =
        GameStateManager.instance.levelStars[widget.game.level.levelNumber - 1];

    // ✅ 1. BUSCA AS ESTATÍSTICAS SALVAS PARA OBTER O RECORDE
    final levelStats = GameStateManager.instance.getLevelStats(
      widget.game.level.levelNumber,
    );
    final bestMoves = levelStats?['best_moves'] as int?;

    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(availableWidth)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ✅ 2. ATUALIZA A COLUNA DE MOVIMENTOS PARA MOSTRAR O RECORDE
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mostra o recorde apenas se ele existir
                if (bestMoves != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Recorde de Movimentos: $bestMoves",
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(availableWidth, 11),
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: _buildStatItem(
              "Nível",
              "1",
              Icons.looks_one,
              const Color(0xFF2196F3),
              availableWidth,
            ),
          ),
          Flexible(
            child: _buildStatItem(
              "Estrelas",
              "⭐" * starsEarned,
              null,
              const Color(0xFFFFD700),
              availableWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData? icon,
    Color color,
    double availableWidth,
  ) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: color, size: _getResponsiveSize(availableWidth, 24))
        else
          Text(
            value,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(availableWidth, 24),
            ),
            overflow: TextOverflow.visible,
          ),
        SizedBox(height: _getResponsiveSpacing(availableWidth, 8)),
        Text(
          label,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(availableWidth, 12),
            color: const Color(0xFF6D4C41),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
        ),
        if (icon != null) ...[
          SizedBox(height: _getResponsiveSpacing(availableWidth, 4)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: _getResponsiveFontSize(availableWidth, 16),
            ),
            overflow: TextOverflow.visible,
          ),
        ],
      ],
    );
  }

  /// ✅ CORREÇÃO: Botões de ação responsivos
  Widget _buildActionButtons(double availableWidth) {
    return Row(
      children: [
        Expanded(
          child: _buildSpecialButton(
            label: "Menu",
            icon: Icons.home_outlined,
            isPrimary: false,
            onPressed: () => _handleMenuPress(),
            availableWidth: availableWidth,
          ),
        ),
        SizedBox(width: _getResponsiveSpacing(availableWidth, 16)),
        Expanded(
          flex: 2,
          child: _buildSpecialButton(
            label: "Continuar Jornada",
            icon: Icons.arrow_forward_rounded,
            isPrimary: true,
            onPressed: () => _handleContinuePress(),
            availableWidth: availableWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
    required double availableWidth,
  }) {
    final backgroundColor = isPrimary
        ? const Color(0xFFFF8F00)
        : Colors.transparent;
    final textColor = isPrimary ? Colors.white : const Color(0xFFFF8F00);
    final borderColor = const Color(0xFFFF8F00);

    return Container(
      height: _getResponsiveSize(availableWidth, 52),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: 2),
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
              )
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFFFF8F00).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: textColor,
                size: _getResponsiveSize(availableWidth, 22),
              ),
              SizedBox(width: _getResponsiveSpacing(availableWidth, 8)),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: _getResponsiveFontSize(availableWidth, 16),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinuePress() async {
    // ✅ ADICIONE ESTA LINHA PARA SALVAR O PROGRESSO DO OVO
    GameStateManager.instance.unlockZenGardenEgg();
    // Animação de saída especial
    await _mainController.reverse();

    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      if (mounted) {
        widget.game.overlays.remove('levelOneVictoryPanel');
        widget.game.resumeEngine();

        Navigator.of(context).pushReplacement(
          SmoothPageTransitions.slideFromRight(const LevelSelectScreen()),
        );
      }
    }
  }

  void _handleMenuPress() async {
    // ✅ ADICIONE ESTA LINHA PARA SALVAR O PROGRESSO DO OVO
    GameStateManager.instance.unlockZenGardenEgg();
    await _mainController.reverse();

    if (widget.onMenu != null) {
      widget.onMenu!();
    } else {
      if (mounted) {
        widget.game.overlays.remove('victoryPanel');
        widget.game.resumeEngine();

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/menu', (route) => false);
      }
    }
  }
}

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Nível'),
        backgroundColor: const Color(0xFFFF8F00),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
          ),
        ),
        child: const Center(
          child: Text(
            'Seleção de Níveis\n(Em desenvolvimento)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Color(0xFF6D4C41)),
          ),
        ),
      ),
    );
  }
}
