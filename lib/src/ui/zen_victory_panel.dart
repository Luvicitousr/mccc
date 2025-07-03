import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../game/candy_game.dart';
import 'game_state_manager.dart';
import 'smooth_page_transitions.dart';
import 'level_one_victory_panel.dart';

/// 🎋 Painel de vitória zen aprimorado com detecção automática de nível
/// Automaticamente exibe a tela especial para o Nível 1 ou a tela padrão para outros níveis
class ZenVictoryPanel extends StatelessWidget {
  final dynamic game; // CandyGame
  final VoidCallback? onContinue;
  final VoidCallback? onMenu;

  const ZenVictoryPanel({
    super.key,
    required this.game,
    this.onContinue,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ DETECÇÃO AUTOMÁTICA: Verifica se é o Nível 1
    final isLevelOne = game.level.levelNumber == 1;

    if (isLevelOne) {
      // Exibe tela especial do Nível 1 com ovo
      return LevelOneVictoryPanel(
        game: game,
        onContinue: onContinue,
        onMenu: onMenu,
      );
    } else {
      // Exibe tela padrão zen para outros níveis
      return StandardZenVictoryPanel(
        game: game,
        onContinue: onContinue,
        onMenu: onMenu,
      );
    }
  }
}

/// 🌸 Painel de vitória padrão para níveis 2+
class StandardZenVictoryPanel extends StatefulWidget {
  final dynamic game;
  final VoidCallback? onContinue;
  final VoidCallback? onMenu;

  const StandardZenVictoryPanel({
    super.key,
    required this.game,
    this.onContinue,
    this.onMenu,
  });

  @override
  State<StandardZenVictoryPanel> createState() =>
      _StandardZenVictoryPanelState();
}

class _StandardZenVictoryPanelState extends State<StandardZenVictoryPanel>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _petalsController;
  late AnimationController _rippleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final GameStateManager _gameStateManager = GameStateManager.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();

    HapticFeedback.lightImpact();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _petalsController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
    ));
  }

  void _startAnimations() {
    _mainController.forward();
    _petalsController.repeat();
    _rippleController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _petalsController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentStats =
        _gameStateManager.getLevelStats(widget.game.level.levelNumber);

    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: ZenColors.zenGradient,
      ),
      child: Stack(
        children: [
          _buildRippleBackground(),
          _buildFloatingPetals(),
          _buildBambooElements(),
          _buildMainContent(currentStats),
          _buildZenSandPatterns(),
        ],
      ),
    );
  }

  Widget _buildRippleBackground() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return CustomPaint(
          painter: RipplePainter(_rippleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingPetals() {
    return AnimatedBuilder(
      animation: _petalsController,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final offset = (index * 0.3) % 1.0;
            final animationValue = (_petalsController.value + offset) % 1.0;

            return Positioned(
              left: 50.0 + (index * 40.0) % MediaQuery.of(context).size.width,
              top: -20 +
                  (animationValue * (MediaQuery.of(context).size.height + 40)),
              child: Transform.rotate(
                angle: animationValue * 2 * math.pi * 0.1,
                child: Opacity(
                  opacity: 0.3 + (math.sin(animationValue * math.pi) * 0.4),
                  child: const Icon(
                    Icons.local_florist,
                    color: ZenColors.sakuraPink,
                    size: 16,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBambooElements() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BambooPainter(),
      ),
    );
  }

  Widget _buildZenSandPatterns() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(
          painter: ZenSandPainter(),
        ),
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic>? currentStats) {
    return Center(
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildVictoryCard(currentStats),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVictoryCard(Map<String, dynamic>? currentStats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: ZenColors.goldAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMainIcon(),
          const SizedBox(height: 24),
          _buildTitle(),
          const SizedBox(height: 16),
          _buildSubtitle(),
          const SizedBox(height: 32),
          _buildStats(currentStats),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMainIcon() {
    return Container(
      width: _getResponsiveSize(80),
      height: _getResponsiveSize(80),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ZenColors.bambooGreen.withOpacity(0.8),
            ZenColors.bambooGreen.withOpacity(0.4),
          ],
        ),
      ),
      child: Icon(
        Icons.spa,
        size: _getResponsiveSize(40),
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Harmonia Alcançada',
      style: ZenTypography.heading.copyWith(
        color: ZenColors.earthBrown,
        fontSize: _getResponsiveFontSize(28),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'A serenidade flui através\nda harmonia perfeita',
      style: ZenTypography.body.copyWith(
        color: ZenColors.stoneGray,
        fontSize: _getResponsiveFontSize(16),
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStats(Map<String, dynamic>? currentStats) {
    final movesUsed = widget.game.level.moves - widget.game.movesLeft.value;
    final starsEarned = _calculateStars(movesUsed);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZenColors.mistyGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ZenColors.stoneGray.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
              "Nível", "${widget.game.level.levelNumber}", Icons.layers),
          _buildStatItem("", "⭐" * starsEarned, null),
          _buildStatItem("Movimentos", "$movesUsed", Icons.touch_app),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData? icon) {
    return Column(
      children: [
        if (icon != null)
          Icon(
            icon,
            color: ZenColors.bambooGreen,
            size: 20,
          )
        else
          Text(
            value,
            style: const TextStyle(fontSize: 20),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: ZenTypography.body.copyWith(
            fontSize: 12,
            color: ZenColors.stoneGray,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(height: 4),
          Text(
            value,
            style: ZenTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: ZenColors.earthBrown,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildZenButton(
            label: "Menu",
            icon: Icons.home_outlined,
            isPrimary: false,
            onPressed: () => _handleMenuPress(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildZenButton(
            label: "Continuar",
            icon: Icons.arrow_forward_rounded,
            isPrimary: true,
            onPressed: () => _handleContinuePress(),
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
    final backgroundColor =
        isPrimary ? ZenColors.bambooGreen : Colors.transparent;
    final textColor = isPrimary ? Colors.white : ZenColors.bambooGreen;
    final borderColor = ZenColors.bambooGreen;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
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
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: ZenTypography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getResponsiveFontSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return baseSize * 0.9;
    if (screenWidth > 1024) return baseSize * 1.1;
    return baseSize;
  }

  double _getResponsiveSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return baseSize * 0.8;
    if (screenWidth > 1024) return baseSize * 1.2;
    return baseSize;
  }

  int _calculateStars(int movesUsed) {
    final totalMoves = widget.game.level.moves;
    final efficiency = (totalMoves - movesUsed) / totalMoves;

    if (efficiency >= 0.7) return 3;
    if (efficiency >= 0.4) return 2;
    return 1;
  }

  void _handleContinuePress() async {
    await _mainController.reverse();

    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      if (mounted) {
        widget.game.overlays.remove('victoryPanel');
        widget.game.resumeEngine();

        Navigator.of(context).pushReplacement(
          SmoothPageTransitions.slideFromRight(
            const LevelSelectScreen(),
          ),
        );
      }
    }
  }

  void _handleMenuPress() async {
    await _mainController.reverse();

    if (widget.onMenu != null) {
      widget.onMenu!();
    } else {
      if (mounted) {
        widget.game.overlays.remove('victoryPanel');
        widget.game.resumeEngine();

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/menu',
          (route) => false,
        );
      }
    }
  }
}

/// 🎨 Cores zen japonesas (mantidas do design original)
class ZenColors {
  static const Color sakuraPink = Color(0xFFFFB7C5);
  static const Color bambooGreen = Color(0xFF7CB342);
  static const Color mistyGray = Color(0xFFF5F5F5);
  static const Color stoneGray = Color(0xFF9E9E9E);
  static const Color waterBlue = Color(0xFF81C784);
  static const Color earthBrown = Color(0xFF8D6E63);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color redAccent = Color(0xFFE57373);

  static const LinearGradient zenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F8F8), Color(0xFFE8E8E8)],
  );
}

/// ✍️ Tipografia zen (mantida do design original)
class ZenTypography {
  static const TextStyle heading = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: 2.0,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'NotoSansJP',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.0,
    height: 1.6,
  );
}

/// 🌊 Painter para efeito ripple zen
class RipplePainter extends CustomPainter {
  final double animationValue;

  RipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.waterBlue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.7;

    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + (i * 0.3)) % 1.0;
      final radius = maxRadius * progress;
      final opacity = (1.0 - progress) * 0.3;

      paint.color = ZenColors.waterBlue.withOpacity(opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 🎋 Painter para elementos de bambu
class BambooPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.bambooGreen.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final leftPath = Path();
    leftPath.moveTo(20, size.height);
    leftPath.quadraticBezierTo(30, size.height * 0.7, 25, size.height * 0.4);
    leftPath.quadraticBezierTo(20, size.height * 0.2, 30, 0);
    canvas.drawPath(leftPath, paint);

    final rightPath = Path();
    rightPath.moveTo(size.width - 20, size.height);
    rightPath.quadraticBezierTo(
        size.width - 30, size.height * 0.7, size.width - 25, size.height * 0.4);
    rightPath.quadraticBezierTo(
        size.width - 20, size.height * 0.2, size.width - 30, 0);
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🏔️ Painter para padrões de areia zen
class ZenSandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.stoneGray.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 1; i <= 5; i++) {
      final radius = (i * 30.0);
      canvas.drawCircle(center, radius, paint);
    }

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final startX = center.dx + math.cos(angle) * 50;
      final startY = center.dy + math.sin(angle) * 50;
      final endX = center.dx + math.cos(angle) * 150;
      final endY = center.dy + math.sin(angle) * 150;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
