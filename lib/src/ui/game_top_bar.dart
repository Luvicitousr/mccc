import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/candy_game.dart';
import '../engine/petal_piece.dart';

class GameTopBar extends StatelessWidget {
  final CandyGame game;

  const GameTopBar({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        return Container(
          width: availableWidth,
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsivePadding(availableWidth),
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            // ✅ CONTEXT ADICIONADO: Passa o context para o método filho
            child: _buildResponsiveContent(context, availableWidth),
          ),
        );
      },
    );
  }

  // ✅ CONTEXT ADICIONADO
  Widget _buildResponsiveContent(BuildContext context, double availableWidth) {
    if (availableWidth < 350) {
      return _buildCompactLayout(context, availableWidth);
    } else if (availableWidth < 500) {
      return _buildMediumLayout(context, availableWidth);
    } else {
      return _buildFullLayout(context, availableWidth);
    }
  }

  // ✅ CONTEXT ADICIONADO
  Widget _buildCompactLayout(BuildContext context, double availableWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildBackButton(context, availableWidth), // Passa o context
            const Spacer(),
            _buildMovesCounter(availableWidth, compact: true),
          ],
        ),
        const SizedBox(height: 8),
        _buildObjectivesRow(availableWidth, compact: true),
      ],
    );
  }

  // ✅ CONTEXT ADICIONADO
  Widget _buildMediumLayout(BuildContext context, double availableWidth) {
    return Row(
      children: [
        _buildBackButton(context, availableWidth), // Passa o context
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildObjectivesRow(availableWidth),
        ),
        const SizedBox(width: 12),
        _buildMovesCounter(availableWidth),
      ],
    );
  }

  // ✅ CONTEXT ADICIONADO
  Widget _buildFullLayout(BuildContext context, double availableWidth) {
    return Row(
      children: [
        _buildBackButton(context, availableWidth), // Passa o context
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: _buildObjectivesRow(availableWidth),
        ),
        const SizedBox(width: 16),
        _buildMovesCounter(availableWidth),
        const SizedBox(width: 8),
        _buildMenuButton(context, availableWidth), // Passa o context
      ],
    );
  }

  // ✅ CONTEXT ADICIONADO
  Widget _buildBackButton(BuildContext context, double availableWidth) {
    final size = _getResponsiveButtonSize(availableWidth);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: () {
            HapticFeedback.selectionClick();
            // Agora usa o 'context' que foi recebido como parâmetro
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: _getResponsiveIconSize(availableWidth),
          ),
        ),
      ),
    );
  }

  /// 🎯 Contador de movimentos responsivo
  Widget _buildMovesCounter(double availableWidth, {bool compact = false}) {
    return ValueListenableBuilder<int>(
      valueListenable: game.movesLeft,
      builder: (context, movesLeft, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: _getMovesColor(movesLeft).withOpacity(0.9),
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.white,
                size: _getResponsiveIconSize(availableWidth, small: compact),
              ),
              SizedBox(width: compact ? 4 : 6),
              Text(
                '$movesLeft',
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      _getResponsiveFontSize(availableWidth, compact ? 14 : 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🎯 Linha de objetivos responsiva
  Widget _buildObjectivesRow(double availableWidth, {bool compact = false}) {
    return ValueListenableBuilder<Map<PetalType, int>>(
      valueListenable: game.objectives,
      builder: (context, objectives, child) {
        final objectiveEntries = objectives.entries.toList();

        // ✅ CORREÇÃO: Limita número de objetivos baseado no espaço disponível
        final maxObjectives = _getMaxObjectives(availableWidth, compact);
        final visibleObjectives = objectiveEntries.take(maxObjectives).toList();
        final hasMore = objectiveEntries.length > maxObjectives;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Objetivos visíveis
              ...visibleObjectives.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(right: compact ? 6 : 8),
                  child: _buildObjectiveItem(
                    entry.key,
                    entry.value,
                    availableWidth,
                    compact: compact,
                  ),
                ),
              ),

              // Indicador de mais objetivos se necessário
              if (hasMore)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 8,
                    vertical: compact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(compact ? 8 : 12),
                  ),
                  child: Text(
                    '+${objectiveEntries.length - maxObjectives}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(
                          availableWidth, compact ? 10 : 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 🎯 Item de objetivo individual
  Widget _buildObjectiveItem(PetalType type, int count, double availableWidth,
      {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getObjectiveColor(type).withOpacity(0.8),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPetalIcon(type, availableWidth, compact: compact),
          SizedBox(width: compact ? 3 : 4),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize:
                  _getResponsiveFontSize(availableWidth, compact ? 11 : 13),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🌸 Ícone da pétala
  Widget _buildPetalIcon(PetalType type, double availableWidth,
      {bool compact = false}) {
    return Container(
      width: compact ? 16 : 20,
      height: compact ? 16 : 20,
      decoration: BoxDecoration(
        color: _getPetalColor(type),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Icon(
        _getPetalIcon(type),
        color: Colors.white,
        size: compact ? 10 : 12,
      ),
    );
  }

  // ✅ CONTEXT ADICIONADO
  Widget _buildMenuButton(BuildContext context, double availableWidth) {
    final size = _getResponsiveButtonSize(availableWidth) * 0.8;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: () {
            HapticFeedback.selectionClick();
            // Agora usa o 'context' que foi recebido como parâmetro
            _showGameMenu(context);
          },
          child: Icon(
            Icons.more_vert,
            color: Colors.white,
            size: _getResponsiveIconSize(availableWidth, small: true),
          ),
        ),
      ),
    );
  }

  /// ✅ MÉTODOS RESPONSIVOS

  double _getResponsivePadding(double availableWidth) {
    if (availableWidth < 350) return 8.0;
    if (availableWidth < 500) return 12.0;
    return 16.0;
  }

  double _getResponsiveButtonSize(double availableWidth) {
    if (availableWidth < 350) return 36.0;
    if (availableWidth < 500) return 40.0;
    return 44.0;
  }

  double _getResponsiveIconSize(double availableWidth, {bool small = false}) {
    final baseSize = small ? 16.0 : 20.0;
    if (availableWidth < 350) return baseSize * 0.8;
    if (availableWidth < 500) return baseSize * 0.9;
    return baseSize;
  }

  double _getResponsiveFontSize(double availableWidth, double baseSize) {
    if (availableWidth < 350) return baseSize * 0.8;
    if (availableWidth < 500) return baseSize * 0.9;
    return baseSize;
  }

  int _getMaxObjectives(double availableWidth, bool compact) {
    if (compact) {
      if (availableWidth < 350) return 2;
      return 3;
    }

    if (availableWidth < 350) return 2;
    if (availableWidth < 500) return 3;
    if (availableWidth < 700) return 4;
    return 5;
  }

  /// 🎨 MÉTODOS DE CORES E ÍCONES

  Color _getMovesColor(int movesLeft) {
    if (movesLeft <= 3) return Colors.red.shade600;
    if (movesLeft <= 7) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  Color _getObjectiveColor(PetalType type) {
    switch (type) {
      case PetalType.cherry:
        return const Color(0xFF49f752);
      case PetalType.maple:
        return Colors.purple.shade400;
      case PetalType.orchid:
        return const Color(0xFF1ef4ff);
      case PetalType.plum:
        return Colors.red.shade400;
      case PetalType.lily:
        return Colors.amber.shade400;
      case PetalType.peony:
        return const Color(0xFFff89b9);
      case PetalType.bomb:
        return const Color(0xFFFF4D00);
      case PetalType.caged1:
      case PetalType.caged2:
        return const Color(0xFF8D6E63);
      default:
        return Colors.grey.shade400;
    }
  }

  Color _getPetalColor(PetalType type) {
    switch (type) {
      case PetalType.cherry:
        return const Color(0xFF49f752);
      case PetalType.maple:
        return Colors.purple.shade400;
      case PetalType.orchid:
        return const Color(0xFF1ef4ff);
      case PetalType.plum:
        return Colors.red.shade400;
      case PetalType.lily:
        return Colors.amber.shade400;
      case PetalType.peony:
        return const Color(0xFFff89b9);
      case PetalType.bomb:
        return const Color(0xFFFF4D00);
      case PetalType.caged1:
      case PetalType.caged2:
        return const Color(0xFF8D6E63);
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getPetalIcon(PetalType type) {
    switch (type) {
      case PetalType.cherry:
        return Icons.local_florist;
      case PetalType.maple:
        return Icons.eco;
      case PetalType.orchid:
        return Icons.spa;
      case PetalType.plum:
        return Icons.nature;
      case PetalType.lily:
        return Icons.filter_vintage; // A good alternative for lily;
      case PetalType.peony:
        return Icons.flare; // ✅ CORRECTION: Using a valid icon name
      case PetalType.bomb:
        return Icons.local_fire_department;
      case PetalType.caged1:
      case PetalType.caged2:
        return Icons.egg;
      default:
        return Icons.help;
    }
  }

  /// 📱 Menu do jogo
  void _showGameMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pause),
              title: const Text('Pausar'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reiniciar'),
              onTap: () {
                Navigator.pop(context);
                // Implementar reiniciar
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Menu Principal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/menu',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
