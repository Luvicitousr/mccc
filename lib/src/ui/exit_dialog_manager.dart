import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// 🚪 Gerenciador de Diálogo de Saída do Aplicativo - VERSÃO CORRIGIDA
///
/// ✅ CORREÇÕES APLICADAS:
/// - Implementação robusta de fechamento do app
/// - Múltiplos métodos de saída como fallback
/// - Melhor handling de plataformas diferentes
/// - Logging detalhado para debug
class ExitDialogManager {
  static ExitDialogManager? _instance;
  static ExitDialogManager get instance => _instance ??= ExitDialogManager._();

  ExitDialogManager._();

  /// 🎭 Exibe diálogo de confirmação de saída
  ///
  /// Retorna:
  /// - true: Usuário confirmou que deseja sair
  /// - false: Usuário cancelou ou fechou o diálogo
  Future<bool> showExitDialog(BuildContext context) async {
    if (kDebugMode) {
      print("[EXIT_DIALOG] 🎭 Exibindo diálogo de confirmação de saída");
    }

    // Feedback tátil ao abrir o diálogo
    HapticFeedback.lightImpact();

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Permite fechar tocando fora
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (BuildContext context) => const ZenExitDialog(),
      );

      // Se o usuário fechou o diálogo sem escolher, considera como "não sair"
      final shouldExit = result ?? false;

      if (kDebugMode) {
        print(
            "[EXIT_DIALOG] 🤔 Resultado do diálogo: ${shouldExit ? 'SAIR' : 'CANCELAR'}");
      }

      // ✅ CORREÇÃO CRÍTICA: Se o usuário escolheu sair, executa o fechamento
      if (shouldExit) {
        await _executeAppExit();
      }

      return shouldExit;
    } catch (e) {
      if (kDebugMode) {
        print("[EXIT_DIALOG] ❌ Erro ao exibir diálogo: $e");
      }

      // Em caso de erro, não sai do app por segurança
      return false;
    }
  }

  /// 🚪 Executa o fechamento do aplicativo com múltiplos métodos
  Future<void> _executeAppExit() async {
    if (kDebugMode) {
      print("[EXIT_DIALOG] 🚪 Executando fechamento do aplicativo...");
    }

    try {
      // Feedback tátil de confirmação
      HapticFeedback.heavyImpact();

      // ✅ MÉTODO 1: SystemNavigator.pop() - Método padrão do Flutter
      if (kDebugMode) {
        print("[EXIT_DIALOG] 📱 Tentando SystemNavigator.pop()...");
      }

      SystemNavigator.pop();

      // ✅ FALLBACK: Se SystemNavigator.pop() não funcionar, usa outros métodos
      await Future.delayed(const Duration(milliseconds: 500));

      if (kDebugMode) {
        print(
            "[EXIT_DIALOG] ⚠️ SystemNavigator.pop() pode não ter funcionado, tentando fallbacks...");
      }

      // ✅ MÉTODO 2: exit() para Android (mais agressivo)
      if (Platform.isAndroid) {
        if (kDebugMode) {
          print("[EXIT_DIALOG] 🤖 Usando exit(0) para Android...");
        }
        exit(0);
      }

      // ✅ MÉTODO 3: Para iOS, tenta minimizar (iOS não permite fechar apps programaticamente)
      if (Platform.isIOS) {
        if (kDebugMode) {
          print(
              "[EXIT_DIALOG] 🍎 iOS detectado - apps não podem ser fechados programaticamente");
        }
        // No iOS, apenas retorna para o sistema
        SystemNavigator.pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print("[EXIT_DIALOG] ❌ Erro ao fechar aplicativo: $e");
        print("[EXIT_DIALOG] 🔄 Tentando método de emergência...");
      }

      // ✅ MÉTODO DE EMERGÊNCIA: Force exit
      try {
        exit(0);
      } catch (emergencyError) {
        if (kDebugMode) {
          print(
              "[EXIT_DIALOG] 💥 Falha crítica no fechamento: $emergencyError");
        }
      }
    }
  }

  /// 🚪 Força o fechamento do aplicativo (método público)
  Future<void> forceExitApp() async {
    if (kDebugMode) {
      print(
          "[EXIT_DIALOG] 🚪 Forçando fechamento do aplicativo (método público)");
    }

    await _executeAppExit();
  }
}

/// 🎨 Diálogo de Saída com Design Zen - VERSÃO CORRIGIDA
class ZenExitDialog extends StatefulWidget {
  const ZenExitDialog({super.key});

  @override
  State<ZenExitDialog> createState() => _ZenExitDialogState();
}

class _ZenExitDialogState extends State<ZenExitDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: _buildDialogContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF7CB342).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone zen
          _buildZenIcon(),

          const SizedBox(height: 20),

          // Título
          _buildTitle(),

          const SizedBox(height: 12),

          // Mensagem
          _buildMessage(),

          const SizedBox(height: 28),

          // Botões de ação
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildZenIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF7CB342).withOpacity(0.2),
            const Color(0xFF7CB342).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF7CB342).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.spa,
        size: 40,
        color: Color(0xFF7CB342),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Sair do Jardim?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2C2C2C),
        letterSpacing: 1.0,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return const Text(
      'Tem certeza de que deseja deixar o\nGarden of Petals?',
      style: TextStyle(
        fontSize: 16,
        color: Color(0xFF666666),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botão Cancelar
        Expanded(
          child: _buildButton(
            label: 'Ficar',
            icon: Icons.close_rounded,
            isPrimary: false,
            onPressed: () => _handleCancel(),
          ),
        ),

        const SizedBox(width: 16),

        // Botão Sair
        Expanded(
          child: _buildButton(
            label: 'Sair',
            icon: Icons.exit_to_app_rounded,
            isPrimary: true,
            onPressed: () => _handleExit(),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final backgroundColor =
        isPrimary ? const Color(0xFFE57373) : Colors.transparent;
    final textColor = isPrimary ? Colors.white : const Color(0xFF7CB342);
    final borderColor =
        isPrimary ? const Color(0xFFE57373) : const Color(0xFF7CB342);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
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
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCancel() async {
    if (kDebugMode) {
      print("[EXIT_DIALOG] 🙅‍♂️ Usuário escolheu FICAR no app");
    }

    // Animação de saída
    await _animationController.reverse();

    if (mounted) {
      Navigator.of(context).pop(false); // Retorna false = não sair
    }
  }

  /// ✅ CORREÇÃO CRÍTICA: Método de saída corrigido
  void _handleExit() async {
    if (kDebugMode) {
      print("[EXIT_DIALOG] 👋 Usuário escolheu SAIR do app - EXECUTANDO SAÍDA");
    }

    // Feedback tátil de confirmação
    HapticFeedback.mediumImpact();

    // ✅ CORREÇÃO: Fecha o diálogo primeiro
    if (mounted) {
      Navigator.of(context).pop(true); // Retorna true = sair
    }

    // ✅ CORREÇÃO: Aguarda um frame para garantir que o diálogo foi fechado
    await Future.delayed(const Duration(milliseconds: 100));

    // ✅ CORREÇÃO: Executa o fechamento do app diretamente
    if (kDebugMode) {
      print("[EXIT_DIALOG] 🚪 Executando fechamento direto do aplicativo...");
    }

    try {
      // Método direto de fechamento
      if (Platform.isAndroid) {
        if (kDebugMode) {
          print("[EXIT_DIALOG] 🤖 Fechando app Android com exit(0)");
        }
        exit(0);
      } else {
        if (kDebugMode) {
          print("[EXIT_DIALOG] 📱 Usando SystemNavigator.pop()");
        }
        SystemNavigator.pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print("[EXIT_DIALOG] ❌ Erro no fechamento direto: $e");
      }

      // Fallback final
      try {
        exit(0);
      } catch (finalError) {
        if (kDebugMode) {
          print("[EXIT_DIALOG] 💥 Falha crítica final: $finalError");
        }
      }
    }
  }
}

/// 🎨 Variação do diálogo para diferentes contextos
class ZenExitDialogVariants {
  /// 🎮 Diálogo específico para quando está em um jogo
  static Future<bool> showGameExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (BuildContext context) => const ZenGameExitDialog(),
        ) ??
        false;

    // ✅ CORREÇÃO: Executa saída se confirmado
    if (result) {
      await ExitDialogManager.instance._executeAppExit();
    }

    return result;
  }

  /// 📚 Diálogo específico para quando está lendo tutorial
  static Future<bool> showTutorialExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (BuildContext context) => const ZenTutorialExitDialog(),
        ) ??
        false;

    // ✅ CORREÇÃO: Executa saída se confirmado
    if (result) {
      await ExitDialogManager.instance._executeAppExit();
    }

    return result;
  }
}

/// 🎮 Diálogo de saída específico para jogos
class ZenGameExitDialog extends StatelessWidget {
  const ZenGameExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: 60,
              color: Color(0xFFFF8F00),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pausar Jogo?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Seu progresso será salvo automaticamente.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Continuar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                    ),
                    child: const Text('Sair'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 📚 Diálogo de saída específico para tutoriais
class ZenTutorialExitDialog extends StatelessWidget {
  const ZenTutorialExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 60,
              color: Color(0xFF7CB342),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sair do Tutorial?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Você pode acessar o tutorial novamente\na qualquer momento.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Continuar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7CB342),
                    ),
                    child: const Text('Sair'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔧 Extensões para facilitar o uso
extension ExitDialogContext on BuildContext {
  /// Mostra diálogo de saída padrão
  Future<bool> showExitDialog() async {
    return await ExitDialogManager.instance.showExitDialog(this);
  }

  /// Mostra diálogo de saída específico para jogos
  Future<bool> showGameExitDialog() async {
    return await ZenExitDialogVariants.showGameExitDialog(this);
  }

  /// Mostra diálogo de saída específico para tutoriais
  Future<bool> showTutorialExitDialog() async {
    return await ZenExitDialogVariants.showTutorialExitDialog(this);
  }

  /// Força saída do aplicativo
  Future<void> forceExitApp() async {
    await ExitDialogManager.instance.forceExitApp();
  }
}
