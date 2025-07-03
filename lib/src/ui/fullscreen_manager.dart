import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// 🖥️ Gerenciador de Modo Tela Cheia - VERSÃO CORRIGIDA
///
/// Fornece diferentes métodos para implementar modo tela cheia
/// com compatibilidade entre versões e plataformas
/// ✅ CORREÇÃO APLICADA: Removido uso incorreto de SystemChrome.latestStyle
class FullscreenManager {
  static FullscreenManager? _instance;
  static FullscreenManager get instance => _instance ??= FullscreenManager._();

  FullscreenManager._();

  bool _isFullscreen = false;
  // ✅ CORREÇÃO: Removido _previousStyle que causava erro
  // SystemUiOverlayStyle? _previousStyle;

  /// 🎯 **MÉTODO 1: Modo Tela Cheia Básico**
  /// Remove completamente as barras do sistema
  Future<void> enableBasicFullscreen() async {
    try {
      // ✅ CORREÇÃO: Removido salvamento de estilo anterior
      // _previousStyle = SystemChrome.latestStyle; // ❌ ERRO: retorna void

      // Remove todas as overlays do sistema
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [],
      );

      _isFullscreen = true;

      if (kDebugMode) {
        print("[FULLSCREEN] ✅ Modo tela cheia básico ativado");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[FULLSCREEN] ❌ Erro ao ativar modo básico: $e");
      }
    }
  }

  /// 🎮 **MÉTODO 2: Modo Tela Cheia para Jogos**
  /// Ideal para jogos - oculta barras mas permite acesso por swipe
  Future<void> enableGameFullscreen() async {
    try {
      // ✅ CORREÇÃO: Removido salvamento de estilo anterior
      // _previousStyle = SystemChrome.latestStyle; // ❌ ERRO: retorna void

      // Modo imersivo com acesso por swipe
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      // Configurações adicionais para jogos
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      _isFullscreen = true;

      if (kDebugMode) {
        print("[FULLSCREEN] 🎮 Modo tela cheia para jogos ativado");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[FULLSCREEN] ❌ Erro ao ativar modo jogo: $e");
      }
    }
  }

  /// 📱 **MÉTODO 3: Modo Tela Cheia Adaptativo**
  /// Adapta-se automaticamente à plataforma e versão
  Future<void> enableAdaptiveFullscreen() async {
    try {
      // ✅ CORREÇÃO: Removido salvamento de estilo anterior
      // _previousStyle = SystemChrome.latestStyle; // ❌ ERRO: retorna void

      if (Platform.isAndroid) {
        await _enableAndroidFullscreen();
      } else if (Platform.isIOS) {
        await _enableIOSFullscreen();
      } else {
        // Fallback para outras plataformas
        await enableBasicFullscreen();
      }

      _isFullscreen = true;

      if (kDebugMode) {
        print("[FULLSCREEN] 📱 Modo tela cheia adaptativo ativado");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[FULLSCREEN] ❌ Erro ao ativar modo adaptativo: $e");
      }
    }
  }

  /// 🎬 **MÉTODO 4: Modo Tela Cheia com Transição Suave**
  /// Inclui animações para uma experiência mais polida
  Future<void> enableSmoothFullscreen({
    Duration transitionDuration = const Duration(milliseconds: 300),
    VoidCallback? onComplete,
  }) async {
    try {
      // ✅ CORREÇÃO: Removido salvamento de estilo anterior
      // _previousStyle = SystemChrome.latestStyle; // ❌ ERRO: retorna void

      // Primeira fase: Torna as barras transparentes
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );

      // Aguarda um frame para aplicar as mudanças
      await Future.delayed(const Duration(milliseconds: 50));

      // Segunda fase: Remove as barras gradualmente
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [],
      );

      // Aguarda a duração da transição
      await Future.delayed(transitionDuration);

      _isFullscreen = true;
      onComplete?.call();

      if (kDebugMode) {
        print("[FULLSCREEN] 🎬 Modo tela cheia com transição ativado");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[FULLSCREEN] ❌ Erro ao ativar modo suave: $e");
      }
    }
  }

  /// 🔄 **Restaura o modo normal**
  Future<void> exitFullscreen() async {
    try {
      // Restaura todas as overlays do sistema
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );

      // ✅ CORREÇÃO: Usa estilo padrão sempre (sem tentar restaurar anterior)
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      _isFullscreen = false;

      if (kDebugMode) {
        print("[FULLSCREEN] 🔄 Modo tela cheia desativado");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[FULLSCREEN] ❌ Erro ao sair do modo tela cheia: $e");
      }
    }
  }

  /// 🤖 Implementação específica para Android
  Future<void> _enableAndroidFullscreen() async {
    // Verifica a versão do Android através de capabilities
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  /// 🍎 Implementação específica para iOS
  Future<void> _enableIOSFullscreen() async {
    // iOS tem limitações - apenas oculta a status bar
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom], // Mantém apenas a barra inferior
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// 📊 Getters para estado atual
  bool get isFullscreen => _isFullscreen;

  /// 🔧 Toggle entre modo normal e tela cheia
  Future<void> toggleFullscreen() async {
    if (_isFullscreen) {
      await exitFullscreen();
    } else {
      await enableAdaptiveFullscreen();
    }
  }
}

/// 🎨 Widget Helper para Modo Tela Cheia
class FullscreenWidget extends StatefulWidget {
  final Widget child;
  final bool enableFullscreen;
  final FullscreenMode mode;
  final Duration transitionDuration;
  final VoidCallback? onFullscreenChanged;

  const FullscreenWidget({
    super.key,
    required this.child,
    this.enableFullscreen = false,
    this.mode = FullscreenMode.adaptive,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.onFullscreenChanged,
  });

  @override
  State<FullscreenWidget> createState() => _FullscreenWidgetState();
}

class _FullscreenWidgetState extends State<FullscreenWidget> {
  final FullscreenManager _fullscreenManager = FullscreenManager.instance;

  @override
  void initState() {
    super.initState();
    _applyFullscreenMode();
  }

  @override
  void didUpdateWidget(FullscreenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableFullscreen != widget.enableFullscreen ||
        oldWidget.mode != widget.mode) {
      _applyFullscreenMode();
    }
  }

  Future<void> _applyFullscreenMode() async {
    if (widget.enableFullscreen) {
      switch (widget.mode) {
        case FullscreenMode.basic:
          await _fullscreenManager.enableBasicFullscreen();
          break;
        case FullscreenMode.game:
          await _fullscreenManager.enableGameFullscreen();
          break;
        case FullscreenMode.adaptive:
          await _fullscreenManager.enableAdaptiveFullscreen();
          break;
        case FullscreenMode.smooth:
          await _fullscreenManager.enableSmoothFullscreen(
            transitionDuration: widget.transitionDuration,
            onComplete: widget.onFullscreenChanged,
          );
          break;
      }
    } else {
      await _fullscreenManager.exitFullscreen();
    }

    widget.onFullscreenChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 📱 Enum para diferentes modos de tela cheia
enum FullscreenMode {
  basic, // Remove todas as barras
  game, // Modo imersivo para jogos
  adaptive, // Adapta-se à plataforma
  smooth, // Com transições suaves
}

/// 🔧 Extensões para facilitar o uso
extension FullscreenContext on BuildContext {
  /// Ativa modo tela cheia no contexto atual
  Future<void> enableFullscreen(
      [FullscreenMode mode = FullscreenMode.adaptive]) async {
    final manager = FullscreenManager.instance;

    switch (mode) {
      case FullscreenMode.basic:
        await manager.enableBasicFullscreen();
        break;
      case FullscreenMode.game:
        await manager.enableGameFullscreen();
        break;
      case FullscreenMode.adaptive:
        await manager.enableAdaptiveFullscreen();
        break;
      case FullscreenMode.smooth:
        await manager.enableSmoothFullscreen();
        break;
    }
  }

  /// Desativa modo tela cheia
  Future<void> exitFullscreen() async {
    await FullscreenManager.instance.exitFullscreen();
  }

  /// Toggle modo tela cheia
  Future<void> toggleFullscreen() async {
    await FullscreenManager.instance.toggleFullscreen();
  }

  /// Verifica se está em modo tela cheia
  bool get isFullscreen => FullscreenManager.instance.isFullscreen;
}

/// 🎮 Mixin para telas que precisam de modo tela cheia
mixin FullscreenMixin<T extends StatefulWidget> on State<T> {
  FullscreenManager get fullscreenManager => FullscreenManager.instance;

  /// Ativa modo tela cheia ao entrar na tela
  Future<void> enterFullscreen(
      [FullscreenMode mode = FullscreenMode.adaptive]) async {
    switch (mode) {
      case FullscreenMode.basic:
        await fullscreenManager.enableBasicFullscreen();
        break;
      case FullscreenMode.game:
        await fullscreenManager.enableGameFullscreen();
        break;
      case FullscreenMode.adaptive:
        await fullscreenManager.enableAdaptiveFullscreen();
        break;
      case FullscreenMode.smooth:
        await fullscreenManager.enableSmoothFullscreen();
        break;
    }
  }

  /// Sai do modo tela cheia ao sair da tela
  Future<void> exitFullscreen() async {
    await fullscreenManager.exitFullscreen();
  }

  @override
  void dispose() {
    // Automaticamente sai do modo tela cheia ao destruir a tela
    fullscreenManager.exitFullscreen();
    super.dispose();
  }
}
