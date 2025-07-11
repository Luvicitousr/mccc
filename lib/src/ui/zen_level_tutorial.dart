import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../engine/level_definition.dart';
import '../engine/petal_piece.dart';
import '../game/level_manager.dart';

/// 🏮 Tela de Tutorial de Nível com Estética Zen
///
/// Apresenta os detalhes do nível ao jogador antes de começar,
/// seguindo um design minimalista e sereno.
class ZenLevelTutorial extends StatefulWidget {
  final LevelDefinition level;
  final VoidCallback onStartGame;

  const ZenLevelTutorial({
    super.key,
    required this.level,
    required this.onStartGame,
  });

  @override
  State<ZenLevelTutorial> createState() => _ZenLevelTutorialState();
}

class _ZenLevelTutorialState extends State<ZenLevelTutorial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fundo com padrão de areia
          Positioned.fill(child: CustomPaint(painter: SandPatternPainter())),
          // Conteúdo principal com animação
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildTutorialCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard() {
    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.9, 450),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: 24),
          _buildDescription(),
          const SizedBox(height: 32),
          _buildInfoRow(),
          const SizedBox(height: 32),
          _buildObjectives(),
          const SizedBox(height: 40),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.level.title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 28,
        fontWeight: FontWeight.w300,
        letterSpacing: 2,
        color: Color(0xFF4A4A4A),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.level.description,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF5D4037).withOpacity(0.8),
        height: 1.6,
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItem(
          icon: Icons.flag_outlined,
          label: 'Nível',
          value: widget.level.levelNumber.toString(),
        ),
        _buildInfoItem(
          icon: widget.level.difficultyIcon,
          label: 'Dificuldade',
          value: widget.level.difficulty.displayName,
          valueColor: widget.level.difficultyColor,
        ),
        _buildInfoItem(
          icon: Icons.swap_horiz,
          label: 'Movimentos',
          value: widget.level.moves.toString(),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8D6E63), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: valueColor ?? const Color(0xFF3E2723),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectives() {
    return Column(
      children: [
        const Text(
          'Objetivos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: widget.level.objectives.entries.map((entry) {
            return _buildObjectiveChip(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildObjectiveChip(PetalType type, int count) {
    final iconData = PetalIconMapper.getIcon(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: const Color(0xFF8D6E63), size: 20),
          const SizedBox(width: 8),
          Text(
            'x $count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Material(
      color: widget.level.difficultyColor.withOpacity(0.9),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: widget.onStartGame,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          child: const Text(
            'Começar',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Classe auxiliar para mapear PetalType para um IconData
class PetalIconMapper {
  static IconData getIcon(PetalType type) {
    switch (type) {
      case PetalType.cherry:
        return Icons.local_florist;
      case PetalType.maple:
        return Icons.eco;
      case PetalType.caged1:
      case PetalType.caged2:
        return Icons.egg;
      case PetalType.bomb:
        return Icons.local_fire_department;
      default:
        return Icons.brightness_7;
    }
  }
}

/// Pintor para o padrão de areia do fundo
class SandPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
