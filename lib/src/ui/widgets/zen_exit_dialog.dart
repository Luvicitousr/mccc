// lib/ui/widgets/zen_exit_dialog.dart

import 'package:flutter/material.dart';

// O ideal é ter um arquivo de tema compartilhado.
class ZenColors {
  static const Color inkBlack = Color(0xFF2C2C2C);
  static const Color stoneGray = Color(0xFF8E8E8E);
  static const Color bambooGreen = Color(0xFF7CB342);
  static const Color sandBeige = Color(0xFFF5F5DC);
  static const Color mistWhite = Color(0xFFF8F8F8);
}

class ZenExitDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ZenExitDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ZenExitDialog> createState() => _ZenExitDialogState();
}

class _ZenExitDialogState extends State<ZenExitDialog> {
  int? _hoveredButtonIndex;

  @override
  Widget build(BuildContext context) {
    // O widget Dialog garante o comportamento modal (fundo escurecido, etc.)
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ZenColors.mistWhite.withOpacity(0.95),
                ZenColors.sandBeige.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            // Usamos um Stack para sobrepor o conteúdo à textura de areia
            child: Stack(
              children: [
                // Camada 1: Textura de areia
                Positioned.fill(
                  child: CustomPaint(painter: SandPatternPainter()),
                ),
                // Camada 2: Conteúdo
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildHeader(), _buildContent(), _buildActions()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        'Sair do Jogo?',
        style: TextStyle(
          fontFamily: 'NotoSans', // Substitua pela sua fonte
          fontWeight: FontWeight.w300, // Hierarquia sutil
          fontSize: 22,
          color: ZenColors.inkBlack,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        'Tem certeza de que deseja voltar ao menu principal? Todo o progresso neste nível será perdido.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'NotoSans', // Substitua pela sua fonte
          fontWeight: FontWeight.w400,
          fontSize: 15,
          color: ZenColors.stoneGray,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDialogButton(
            index: 0,
            text: 'Continuar',
            onTap: widget.onCancel,
            isPrimary: false,
          ),
          const SizedBox(width: 16),
          _buildDialogButton(
            index: 1,
            text: 'Sim, sair',
            onTap: widget.onConfirm,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButton({
    required int index,
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final bool isHovered = _hoveredButtonIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredButtonIndex = index),
      onExit: (_) => setState(() => _hoveredButtonIndex = null),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? ZenColors.bambooGreen.withOpacity(isHovered ? 0.9 : 0.75)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : ZenColors.stoneGray.withOpacity(isHovered ? 0.8 : 0.4),
              width: 1.5,
            ),
            // Sombra sutil para profundidade
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: isPrimary
                          ? ZenColors.bambooGreen.withOpacity(0.3)
                          : ZenColors.stoneGray.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
              color: isPrimary ? Colors.white : ZenColors.inkBlack,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// Painter para a textura de areia rastejada (karesansui)
class SandPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.stoneGray.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    for (double i = -size.height * 0.5; i < size.height * 1.5; i += 10) {
      path.moveTo(-size.width * 0.2, i);
      for (double j = -size.width * 0.2; j < size.width * 1.2; j++) {
        // Normalizamos o valor de 'j' para o intervalo [0, 1] antes de usá-lo na curva.
        final double totalWidth = size.width * 1.4; // O alcance total de 'j'
        final double currentPosition =
            j + (size.width * 0.2); // A posição atual no alcance
        final double normalizedT =
            currentPosition / totalWidth; // O valor 't' normalizado

        // Usamos o valor normalizado para a transformação da curva.
        final sinWave = Curves.easeInOut.transform(normalizedT) * 15;
        path.lineTo(j, i + sinWave);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SandPatternPainter oldDelegate) => false;
}
