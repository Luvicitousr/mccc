import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../game/game_state_manager.dart';
import 'smooth_page_transitions.dart';
import 'zen_settings_screen.dart';
import '../game/game_launcher.dart';
import 'i18n/app_localizations.dart'; // ✅ NOVO: Import do sistema de localização
import 'i18n/language_manager.dart'; // ✅ NOVO: Import do gerenciador de idiomas
import '../bloc/game_bloc.dart'; // ✅ 2. Importe o seu BLoC
import '../ui/game_page.dart'; // ✅ 3. Importe a GamePage

/// 🏮 Zen Level Selection Screen - VERSÃO CORRIGIDA COM I18N
/// ✅ CORREÇÕES APLICADAS:
/// - Removido texto em japonês
/// - Corrigido RenderFlex overflow
/// - Melhorado layout responsivo
/// - Implementado sistema de internacionalização
/// - Integração com GameLauncher para iniciar níveis
/// - Botão de configurações acessível
class ZenLevelSelectionScreen extends StatefulWidget {
  const ZenLevelSelectionScreen({super.key});

  @override
  State<ZenLevelSelectionScreen> createState() =>
      _ZenLevelSelectionScreenState();
}

class _ZenLevelSelectionScreenState extends State<ZenLevelSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _rippleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int? _selectedLevel;
  int? _hoveredLevel;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _mainController.forward();
    _particleController.repeat();
    _rippleController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageManager = context.watch<LanguageManager>();

    // ✅ CORREÇÃO: Adicione o BlocListener aqui.
    return BlocListener<GameBloc, GameState>(
      // ✅ CORREÇÃO: Adicione a condição 'listenWhen' aqui.
      listenWhen: (previousState, currentState) {
        // Esta condição diz ao listener para SÓ reagir se o estado anterior NÃO ERA 'GameReady'.
        // Isso garante que ele só vai disparar a navegação ao sair da tela de seleção (que está no estado 'GameInitial'),
        // e não quando você já está em jogo (no estado 'GameReady') e indo para o próximo nível.
        return previousState is! GameReady && currentState is GameReady;
      },
      listener: (context, state) {
        // Se o estado for 'GameReady', navegue para a tela do jogo.
        if (state is GameReady) {
          Navigator.of(
            context,
          ).push(SmoothPageTransitions.fadeTransition(const GamePage()));
        }
      },
      child: Directionality(
        textDirection: languageManager.isRTL
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: ZenGradients.gardenBackground,
            ),
            child: Stack(
              children: [
                _buildInkWashBackground(),
                _buildFloatingParticles(),
                _buildRippleEffects(),
                _buildSandPatterns(),
                _buildMainContent(l10n),
                _buildNavigationBar(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInkWashBackground() {
    return Positioned.fill(child: CustomPaint(painter: InkWashPainter()));
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(12, (index) {
            final progress = (_particleController.value + (index * 0.15)) % 1.0;
            final screenSize = MediaQuery.of(context).size;

            return Positioned(
              left:
                  (index * screenSize.width / 12) +
                  (math.sin(progress * math.pi * 2) * 30),
              top: -20 + (progress * (screenSize.height + 40)),
              child: Transform.rotate(
                angle: progress * math.pi * 2 * 0.3,
                child: Opacity(
                  opacity: 0.4 * (1.0 - (progress - 0.8).clamp(0.0, 0.2) * 5),
                  child: _buildParticle(index),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final isCherry = index % 3 == 0;
    final size = 8.0 + (index % 3) * 4.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCherry
            ? ZenColors.cherryBlossom.withOpacity(0.8)
            : ZenColors.bambooLeaf.withOpacity(0.6),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRippleEffects() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return CustomPaint(
          painter: RippleEffectPainter(_rippleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildSandPatterns() {
    return Positioned.fill(child: CustomPaint(painter: SandPatternPainter()));
  }

  /// ✅ CORREÇÃO: Conteúdo principal com i18n
  Widget _buildMainContent(AppLocalizations l10n) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(l10n),
                  Expanded(child: _buildLevelGrid()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ✅ CORREÇÃO: Header com i18n
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            l10n.levelSelectionTitle,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(28),
              fontWeight: FontWeight.w300,
              color: ZenColors.inkBlack,
              letterSpacing: 3.0,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.levelSelectionSubtitle,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(16),
              fontWeight: FontWeight.w400,
              color: ZenColors.stoneGray,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: _getResponsiveSize(120),
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ZenColors.bambooGreen.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGrid() {
    return Consumer<GameStateManager>(
      builder: (context, gameState, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsivePadding(),
            vertical: 16,
          ),
          child: _buildResponsiveFlowingPath(gameState),
        );
      },
    );
  }

  Widget _buildResponsiveFlowingPath(GameStateManager gameState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (_getResponsivePadding() * 2);

    int levelsPerRow;
    if (availableWidth < 400) {
      levelsPerRow = 2;
    } else if (availableWidth < 600) {
      levelsPerRow = 3;
    } else {
      levelsPerRow = 4;
    }

    const totalLevels = 30;

    return Column(
      children: List.generate(
        (totalLevels / levelsPerRow).ceil(),
        (rowIndex) =>
            _buildResponsiveLevelRow(gameState, rowIndex, levelsPerRow),
      ),
    );
  }

  Widget _buildResponsiveLevelRow(
    GameStateManager gameState,
    int rowIndex,
    int levelsPerRow,
  ) {
    final isEvenRow = rowIndex % 2 == 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(levelsPerRow, (colIndex) {
          final levelNumber = rowIndex * levelsPerRow + colIndex + 1;
          if (levelNumber > 30) return const SizedBox.shrink();

          return Flexible(child: _buildLevelVignette(gameState, levelNumber));
        }),
      ),
    );
  }

  Widget _buildLevelVignette(GameStateManager gameState, int levelNumber) {
    final isUnlocked = gameState.isLevelUnlocked(levelNumber);
    final isCompleted = levelNumber <= gameState.levelCompleted.length
        ? gameState.levelCompleted[levelNumber - 1]
        : false;
    final stars = levelNumber <= gameState.levelStars.length
        ? gameState.levelStars[levelNumber - 1]
        : 0;

    return GestureDetector(
      onTap: isUnlocked ? () => _selectLevel(levelNumber) : null,
      onTapDown: isUnlocked ? (_) => _onLevelHover(levelNumber) : null,
      onTapCancel: () => _onLevelHoverEnd(),
      child: MouseRegion(
        onEnter: isUnlocked ? (_) => _onLevelHover(levelNumber) : null,
        onExit: (_) => _onLevelHoverEnd(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_hoveredLevel == levelNumber ? 1.05 : 1.0),
          child: _buildGardenVignette(
            levelNumber: levelNumber,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            stars: stars,
            isHovered: _hoveredLevel == levelNumber,
          ),
        ),
      ),
    );
  }

  Widget _buildGardenVignette({
    required int levelNumber,
    required bool isUnlocked,
    required bool isCompleted,
    required int stars,
    required bool isHovered,
  }) {
    final vignetteSize = _getResponsiveVignetteSize();

    return Container(
      width: vignetteSize,
      height: vignetteSize * 1.2,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isHovered
                ? ZenColors.bambooGreen.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: isHovered ? 12 : 6,
            spreadRadius: isHovered ? 2 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            _buildGardenBackground(levelNumber, isUnlocked),
            _buildVignetteContent(levelNumber, isUnlocked, isCompleted, stars),
            if (isHovered) _buildHoverRipple(),
          ],
        ),
      ),
    );
  }

  Widget _buildGardenBackground(int levelNumber, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? _getGardenGradient(levelNumber)
            : ZenGradients.lockedGarden,
      ),
      child: CustomPaint(
        painter: GardenScenePainter(
          levelNumber: levelNumber,
          isUnlocked: isUnlocked,
        ),
        size: Size.infinite,
      ),
    );
  }

  LinearGradient _getGardenGradient(int levelNumber) {
    final gradients = [
      ZenGradients.springGarden,
      ZenGradients.summerGarden,
      ZenGradients.autumnGarden,
      ZenGradients.winterGarden,
    ];
    return gradients[levelNumber % gradients.length];
  }

  Widget _buildVignetteContent(
    int levelNumber,
    bool isUnlocked,
    bool isCompleted,
    int stars,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$levelNumber',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(14),
                fontWeight: FontWeight.w600,
                color: isUnlocked ? ZenColors.inkBlack : Colors.grey.shade600,
              ),
            ),
          ),

          if (isUnlocked) _buildStarsDisplay(stars) else _buildLockIcon(l10n),
        ],
      ),
    );
  }

  Widget _buildStarsDisplay(int stars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          size: _getResponsiveSize(14),
          color: index < stars
              ? ZenColors.goldStar
              : Colors.white.withOpacity(0.5),
        );
      }),
    );
  }

  /// ✅ CORREÇÃO: Ícone de bloqueio com i18n
  Widget _buildLockIcon(AppLocalizations l10n) {
    return Tooltip(
      message: l10n.locked,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.lock,
          size: _getResponsiveSize(14),
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildHoverRipple() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            center: Alignment.center,
            colors: [
              ZenColors.bambooGreen.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ CORREÇÃO: Barra de navegação com i18n
  Widget _buildNavigationBar(AppLocalizations l10n) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildNavButton(
                icon: Icons.arrow_back_ios_rounded,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.back,
              ),
              const Spacer(),
              _buildNavButton(
                icon: Icons.settings,
                onPressed: () => _openSettings(),
                tooltip: l10n.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 24, color: ZenColors.inkBlack),
            ),
          ),
        ),
      ),
    );
  }

  double _getResponsiveFontSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) return baseSize * 0.8;
    if (screenWidth < 600) return baseSize * 0.9;
    if (screenWidth > 800) return baseSize * 1.1;
    return baseSize;
  }

  double _getResponsiveSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) return baseSize * 0.8;
    if (screenWidth < 600) return baseSize * 0.9;
    if (screenWidth > 800) return baseSize * 1.1;
    return baseSize;
  }

  double _getResponsivePadding() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) return 16.0;
    if (screenWidth < 600) return 20.0;
    return 24.0;
  }

  double _getResponsiveVignetteSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (_getResponsivePadding() * 2);

    if (availableWidth < 400) {
      return (availableWidth - 40) / 2;
    } else if (availableWidth < 600) {
      return (availableWidth - 60) / 3;
    } else {
      return (availableWidth - 80) / 4;
    }
  }

  void _onLevelHover(int levelNumber) {
    setState(() {
      _hoveredLevel = levelNumber;
    });
    HapticFeedback.selectionClick();
  }

  void _onLevelHoverEnd() {
    setState(() {
      _hoveredLevel = null;
    });
  }

  void _selectLevel(int levelNumber) {
    setState(() {
      _selectedLevel = levelNumber;
    });

    HapticFeedback.mediumImpact();

    // A navegação será tratada pelo BlocListener.
    context.read<GameBloc>().add(GameLevelSelected(levelNumber));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(SmoothPageTransitions.slideFromRight(const ZenSettingsScreen()));
  }
}

/// 🎨 Painter para efeito de tinta
class InkWashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.3, size.height * 0.2),
        size.width * 0.8,
        [
          ZenColors.inkBlack.withOpacity(0.03),
          ZenColors.stoneGray.withOpacity(0.02),
          Colors.transparent,
        ],
        [0.0, 0.6, 1.0],
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🌊 Painter para efeito de ondulação
class RippleEffectPainter extends CustomPainter {
  final double animationValue;

  RippleEffectPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.waterBlue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center1 = Offset(size.width * 0.2, size.height * 0.7);
    final center2 = Offset(size.width * 0.8, size.height * 0.3);

    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + (i * 0.3)) % 1.0;
      final radius = 100 * progress;
      final opacity = (1.0 - progress) * 0.3;

      paint.color = ZenColors.waterBlue.withOpacity(opacity);
      canvas.drawCircle(center1, radius, paint);
      canvas.drawCircle(center2, radius * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RippleEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// 🏜️ Painter para padrão de areia
class SandPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.sandBeige.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 8; i++) {
      final y = size.height * 0.1 + (i * size.height * 0.1);
      final path = Path();

      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 20) {
        final waveY = y + math.sin(x * 0.02) * 5;
        path.lineTo(x, waveY);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🏞️ Painter para cena de jardim
class GardenScenePainter extends CustomPainter {
  final int levelNumber;
  final bool isUnlocked;

  GardenScenePainter({required this.levelNumber, required this.isUnlocked});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isUnlocked) {
      _drawLockedScene(canvas, size);
      return;
    }

    switch (levelNumber % 4) {
      case 0:
        _drawCherryBlossomScene(canvas, size);
        break;
      case 1:
        _drawBambooScene(canvas, size);
        break;
      case 2:
        _drawRockGardenScene(canvas, size);
        break;
      case 3:
        _drawPondScene(canvas, size);
        break;
    }
  }

  void _drawLockedScene(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withOpacity(0.3);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawCherryBlossomScene(Canvas canvas, Size size) {
    final paint = Paint()..color = ZenColors.cherryBlossom.withOpacity(0.6);

    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.2 + i * 0.15);
      final y = size.height * (0.3 + math.sin(i) * 0.2);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  void _drawBambooScene(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.bambooGreen.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.3 + i * 0.2);
      canvas.drawLine(
        Offset(x, size.height * 0.8),
        Offset(x, size.height * 0.2),
        paint,
      );
    }
  }

  void _drawRockGardenScene(Canvas canvas, Size size) {
    final paint = Paint()..color = ZenColors.stoneGray.withOpacity(0.5);

    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.2 + i * 0.2);
      final y = size.height * 0.6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 8, height: 6),
        paint,
      );
    }
  }

  void _drawPondScene(Canvas canvas, Size size) {
    final paint = Paint()..color = ZenColors.waterBlue.withOpacity(0.4);

    for (int i = 0; i < 3; i++) {
      final radius = 15.0 + i * 8;
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.6),
        radius,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GardenScenePainter oldDelegate) {
    return oldDelegate.levelNumber != levelNumber ||
        oldDelegate.isUnlocked != isUnlocked;
  }
}

/// 🎨 Paleta de cores zen
class ZenColors {
  static const Color inkBlack = Color(0xFF2C2C2C);
  static const Color stoneGray = Color(0xFF8E8E8E);
  static const Color bambooGreen = Color(0xFF7CB342);
  static const Color cherryBlossom = Color(0xFFFFB7C5);
  static const Color bambooLeaf = Color(0xFF9CCC65);
  static const Color waterBlue = Color(0xFF81C784);
  static const Color sandBeige = Color(0xFFF5F5DC);
  static const Color goldStar = Color(0xFFFFD700);
  static const Color mistWhite = Color(0xFFF8F8F8);
}

/// 🌅 Gradientes zen
class ZenGradients {
  static const LinearGradient gardenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8F8F8),
      Color(0xFFE8F5E8),
      Color(0xFFFFF8DC),
      Color(0xFFE6F3FF),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient springGarden = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F5E8), Color(0xFFFFB7C5)],
  );

  static const LinearGradient summerGarden = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF81C784), Color(0xFF7CB342)],
  );

  static const LinearGradient autumnGarden = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
  );

  static const LinearGradient winterGarden = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6F3FF), Color(0xFFF0F8FF)],
  );

  static const LinearGradient lockedGarden = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
  );
}
