import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 📚 Overlay de Tutorial da Bomba - VERSÃO CORRIGIDA PARA OVERFLOW
/// ✅ CORREÇÕES APLICADAS:
/// - Corrigido RenderFlex overflow de 31 pixels
/// - Layout responsivo implementado
/// - Melhor organização dos elementos
/// - Prevenção de overflow em diferentes tamanhos de tela
class BombTutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const BombTutorialOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  State<BombTutorialOverlay> createState() => _BombTutorialOverlayState();
}

class _BombTutorialOverlayState extends State<BombTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();

    // Feedback tátil especial para primeira vez
    HapticFeedback.heavyImpact();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
    ));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: InkWell(
        onTap: () {}, // Previne fechamento acidental
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: _buildResponsiveTutorialContent(),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ CORREÇÃO PRINCIPAL: Container responsivo que previne overflow
  Widget _buildResponsiveTutorialContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ CORREÇÃO: Calcula dimensões disponíveis
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // ✅ CORREÇÃO: Margem responsiva baseada no tamanho da tela
        final horizontalMargin = _getResponsiveMargin(availableWidth);
        final verticalMargin = _getResponsiveMargin(availableHeight);

        return Container(
          width: availableWidth - (horizontalMargin * 2),
          height: availableHeight - (verticalMargin * 2),
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: verticalMargin,
          ),
          child: SingleChildScrollView(
            child:
                _buildTutorialContent(availableWidth - (horizontalMargin * 2)),
          ),
        );
      },
    );
  }

  /// ✅ CORREÇÃO: Margem responsiva
  double _getResponsiveMargin(double availableSpace) {
    if (availableSpace < 400) return 16.0;
    if (availableSpace < 600) return 24.0;
    return 32.0;
  }

  /// ✅ CORREÇÃO: Conteúdo com largura controlada
  Widget _buildTutorialContent(double maxWidth) {
    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(maxWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header especial para primeira vez
          _buildSpecialHeader(maxWidth),

          SizedBox(height: _getResponsiveSpacing(maxWidth, 24)),

          // Imagem da bomba com animação
          _buildAnimatedBombImage(maxWidth),

          SizedBox(height: _getResponsiveSpacing(maxWidth, 24)),

          // Título principal
          _buildMainTitle(maxWidth),

          SizedBox(height: _getResponsiveSpacing(maxWidth, 16)),

          // Descrição principal
          _buildMainDescription(maxWidth),

          SizedBox(height: _getResponsiveSpacing(maxWidth, 20)),

          // Seção de instruções
          _buildInstructionsSection(maxWidth),

          SizedBox(height: _getResponsiveSpacing(maxWidth, 20)),

          // Seção de dicas
          _buildTipsSection(maxWidth),

          SizedBox(height: _getResponsiveSpacing(maxWidth, 28)),

          // Botão de ação
          _buildActionButton(maxWidth),
        ],
      ),
    );
  }

  /// ✅ CORREÇÃO: Padding responsivo
  double _getResponsivePadding(double maxWidth) {
    if (maxWidth < 300) return 16.0;
    if (maxWidth < 400) return 20.0;
    return 28.0;
  }

  /// ✅ CORREÇÃO: Espaçamento responsivo
  double _getResponsiveSpacing(double maxWidth, double baseSpacing) {
    if (maxWidth < 300) return baseSpacing * 0.7;
    if (maxWidth < 400) return baseSpacing * 0.85;
    return baseSpacing;
  }

  /// ✅ CORREÇÃO: Tamanho de fonte responsivo
  double _getResponsiveFontSize(double maxWidth, double baseFontSize) {
    if (maxWidth < 300) return baseFontSize * 0.8;
    if (maxWidth < 400) return baseFontSize * 0.9;
    return baseFontSize;
  }

  Widget _buildSpecialHeader(double maxWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsivePadding(maxWidth),
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8F00).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: _getResponsiveFontSize(maxWidth, 24),
          ),
          SizedBox(width: _getResponsiveSpacing(maxWidth, 12)),
          Flexible(
            child: Text(
              'PEÇA ESPECIAL!',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(maxWidth, 16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(maxWidth, 12)),
          Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: _getResponsiveFontSize(maxWidth, 24),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBombImage(double maxWidth) {
    final imageSize = _getResponsiveImageSize(maxWidth);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
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
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/bomb_petal.png',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF6F00),
                          const Color(0xFFFF8F00),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      size: imageSize * 0.6,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Reinicia a animação
        if (mounted) setState(() {});
      },
    );
  }

  /// ✅ CORREÇÃO: Tamanho de imagem responsivo
  double _getResponsiveImageSize(double maxWidth) {
    if (maxWidth < 300) return 80.0;
    if (maxWidth < 400) return 90.0;
    return 100.0;
  }

  Widget _buildMainTitle(double maxWidth) {
    return Text(
      'BOMBA ZEN DESCOBERTA',
      style: TextStyle(
        fontSize: _getResponsiveFontSize(maxWidth, 24),
        fontWeight: FontWeight.bold,
        color: const Color(0xFF795548),
        letterSpacing: 1.5,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildMainDescription(double maxWidth) {
    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(maxWidth)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        'Parabéns! Você criou sua primeira Bomba Zen. Esta peça especial pode ser ativada trocando-a com qualquer peça adjacente para criar uma poderosa explosão!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _getResponsiveFontSize(maxWidth, 16),
          color: const Color(0xFF795548),
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(double maxWidth) {
    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(maxWidth)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9C27B0).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app,
                color: const Color(0xFF9C27B0),
                size: _getResponsiveFontSize(maxWidth, 24),
              ),
              SizedBox(width: _getResponsiveSpacing(maxWidth, 12)),
              Flexible(
                child: Text(
                  'COMO USAR:',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(maxWidth, 18),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9C27B0),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(maxWidth, 12)),
          _buildInstructionStep(
            '1.',
            'Toque e arraste a bomba para uma peça adjacente',
            Icons.swipe,
            maxWidth,
          ),
          SizedBox(height: _getResponsiveSpacing(maxWidth, 8)),
          _buildInstructionStep(
            '2.',
            'A bomba explode uma grande área ao redor',
            Icons.blur_on,
            maxWidth,
          ),
          SizedBox(height: _getResponsiveSpacing(maxWidth, 8)),
          _buildInstructionStep(
            '3.',
            'Remove todas as peças na área de explosão',
            Icons.clear_all,
            maxWidth,
          ),
        ],
      ),
    );
  }

  /// ✅ CORREÇÃO: Step com layout flexível
  Widget _buildInstructionStep(
      String number, String text, IconData icon, double maxWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9C27B0),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveFontSize(maxWidth, 14),
              ),
            ),
          ),
        ),
        SizedBox(width: _getResponsiveSpacing(maxWidth, 12)),
        Icon(
          icon,
          color: const Color(0xFF9C27B0),
          size: _getResponsiveFontSize(maxWidth, 20),
        ),
        SizedBox(width: _getResponsiveSpacing(maxWidth, 8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(maxWidth, 14),
              color: const Color(0xFF795548),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(double maxWidth) {
    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(maxWidth)),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: const Color(0xFF4CAF50),
                size: _getResponsiveFontSize(maxWidth, 24),
              ),
              SizedBox(width: _getResponsiveSpacing(maxWidth, 12)),
              Flexible(
                child: Text(
                  'DICAS ESPECIAIS:',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(maxWidth, 18),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(maxWidth, 12)),
          _buildTipItem(
            '💥 Bombas podem detonar outras bombas em reação em cadeia',
            Icons.link,
            maxWidth,
          ),
          SizedBox(height: _getResponsiveSpacing(maxWidth, 6)),
          _buildTipItem(
            '🔓 Bombas destroem jaulas e paredes especiais',
            Icons.lock_open,
            maxWidth,
          ),
          SizedBox(height: _getResponsiveSpacing(maxWidth, 6)),
          _buildTipItem(
            '⭐ Crie bombas combinando 5 ou mais peças iguais',
            Icons.star,
            maxWidth,
          ),
        ],
      ),
    );
  }

  /// ✅ CORREÇÃO: Tip item com layout flexível
  Widget _buildTipItem(String text, IconData icon, double maxWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: _getResponsiveFontSize(maxWidth, 18),
        ),
        SizedBox(width: _getResponsiveSpacing(maxWidth, 12)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(maxWidth, 14),
              color: const Color(0xFF795548),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(double maxWidth) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _dismiss,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: _getResponsiveFontSize(maxWidth, 24),
            ),
            SizedBox(width: _getResponsiveSpacing(maxWidth, 12)),
            Flexible(
              child: Text(
                'ENTENDI! VAMOS JOGAR',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(maxWidth, 18),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismiss() {
    HapticFeedback.selectionClick();

    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }
}
