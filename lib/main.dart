import 'package:flutter/material.dart';
import 'package:meu_candy_crush_clone/src/game/tutorial_manager.dart'; // Importe o novo gerenciador
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_candy_crush_clone/src/bloc/game_bloc.dart'; // Importe seu BLoC
import 'package:meu_candy_crush_clone/src/ui/zen_level_selection_screen.dart'; // Importe sua tela
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/game.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ NOVO: Import para localização
import 'src/game/game_state_manager.dart';
import 'src/effects/bomb_tutorial_manager.dart';
import 'src/ui/zen_victory_panel.dart';
import 'src/ui/smooth_page_transitions.dart';
import 'src/ui/petal_fall_game.dart';
import 'src/ui/zen_level_selection_screen.dart';
import 'src/ui/zen_settings_screen.dart';
import 'src/ui/fullscreen_manager.dart';
import 'src/ui/exit_dialog_manager.dart';
import 'src/ui/i18n/app_localizations.dart'; // ✅ NOVO: Import do sistema de localização
import 'src/ui/i18n/language_manager.dart'; // ✅ NOVO: Import do gerenciador de idiomas
import 'package:flutter/foundation.dart';
import 'src/game/first_victory_manager.dart'; // Importe o novo gerenciador
import 'package:meu_candy_crush_clone/src/ui/zen_garden_screen.dart'; // ✅ 1. Importe a nova tela
import 'package:meu_candy_crush_clone/src/icons/zen_garden_icon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialize o gerenciador aqui
  await FirstVictoryManager.instance.init();

  // ✅ INICIALIZE O GERENCIADOR DE TUTORIAL AQUI
  await TutorialManager.instance.initialize();

  await _initializeFullscreenApp();
  WakelockPlus.enable();
  await BombTutorialManager.instance.initialize();
  await GameStateManager.instance.initialize();

  // ✅ NOVO: Inicializa o gerenciador de idiomas
  await LanguageManager.instance.initialize();

  await _configureFullscreenSystemUI();

  runApp(const ZenCandyCrushApp());
}

Future<void> _initializeFullscreenApp() async {
  try {
    if (kDebugMode) {
      print(
        "[FULLSCREEN_APP] 🚀 Inicializando aplicativo em modo tela cheia...",
      );
    }

    await FullscreenManager.instance.enableAdaptiveFullscreen();

    if (kDebugMode) {
      print("[FULLSCREEN_APP] ✅ Modo tela cheia ativado com sucesso!");
    }
  } catch (e) {
    if (kDebugMode) {
      print("[FULLSCREEN_APP] ❌ Erro ao ativar modo tela cheia: $e");
    }
  }
}

Future<void> _configureFullscreenSystemUI() async {
  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
    );

    if (kDebugMode) {
      print("[FULLSCREEN_APP] ⚙️ Configurações de UI do sistema aplicadas");
    }
  } catch (e) {
    if (kDebugMode) {
      print("[FULLSCREEN_APP] ❌ Erro ao configurar UI do sistema: $e");
    }
  }
}

class ZenCandyCrushApp extends StatefulWidget {
  const ZenCandyCrushApp({super.key});

  @override
  State<ZenCandyCrushApp> createState() => _ZenCandyCrushAppState();
}

class _ZenCandyCrushAppState extends State<ZenCandyCrushApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FullscreenManager.instance.enableAdaptiveFullscreen();
      });

      if (kDebugMode) {
        print("[FULLSCREEN_APP] 🔄 Reaplicando fullscreen após retomar app");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ ADICIONE O BLOCPROVIDER AQUI
        BlocProvider<GameBloc>(create: (context) => GameBloc()),
        ChangeNotifierProvider.value(value: GameStateManager.instance),
        Provider.value(value: BombTutorialManager.instance),
        Provider.value(value: FullscreenManager.instance),
        Provider.value(value: ExitDialogManager.instance),
        // ✅ NOVO: Provider para o gerenciador de idiomas
        ChangeNotifierProvider.value(value: LanguageManager.instance),
      ],
      child: Consumer<LanguageManager>(
        builder: (context, languageManager, child) {
          return MaterialApp(
            title: 'Garden of Petals',
            debugShowCheckedModeBanner: false,

            // ✅ NOVO: Configuração de localização
            locale: languageManager.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,

            theme: _buildFullscreenTheme(context),

            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const ZenSplashScreen(),
              '/menu': (context) => const ZenMainMenuWithBackHandler(),
              '/level_select': (context) => const ZenLevelSelectionScreen(),
              '/game': (context) => const ZenGameScreen(),
              '/settings': (context) => const ZenSettingsScreen(),
              '/debug_tutorial': (context) => const DebugTutorialScreen(),
            },

            builder: (context, child) {
              return FullscreenAppWrapper(child: child ?? Container());
            },

            onGenerateRoute: (settings) {
              final routeName = settings.name ?? '';

              Widget page;
              switch (routeName) {
                case '/victory':
                  page = const ZenVictoryScreen();
                  break;
                case '/settings':
                  page = const ZenSettingsScreen();
                  break;
                default:
                  page = const ZenMainMenuWithBackHandler();
              }

              return ZenTransitionHelper.contextualTransition(
                page,
                fromRoute: ModalRoute.of(context)?.settings.name ?? '',
                toRoute: routeName,
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildFullscreenTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ZenColors.bambooGreen,
        brightness: Brightness.light,
      ),

      textTheme: GoogleFonts.notoSansTextTheme(Theme.of(context).textTheme)
          .copyWith(
            headlineLarge: ZenTypography.heading,
            bodyLarge: ZenTypography.body,
          ),

      scaffoldBackgroundColor: Colors.transparent,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZenColors.bambooGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: ZenColors.earthBrown),
        titleTextStyle: ZenTypography.heading.copyWith(
          color: ZenColors.earthBrown,
          fontSize: 20,
        ),
      ),
    );
  }
}

class FullscreenAppWrapper extends StatefulWidget {
  final Widget child;

  const FullscreenAppWrapper({super.key, required this.child});

  @override
  State<FullscreenAppWrapper> createState() => _FullscreenAppWrapperState();
}

class _FullscreenAppWrapperState extends State<FullscreenAppWrapper> {
  @override
  void initState() {
    super.initState();
    _ensureFullscreen();
  }

  Future<void> _ensureFullscreen() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !FullscreenManager.instance.isFullscreen) {
        await FullscreenManager.instance.enableAdaptiveFullscreen();

        if (kDebugMode) {
          print("[FULLSCREEN_WRAPPER] 🔄 Fullscreen reaplicado");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: widget.child,
    );
  }
}

class ZenSplashScreen extends StatefulWidget {
  const ZenSplashScreen({super.key});

  @override
  State<ZenSplashScreen> createState() => _ZenSplashScreenState();
}

class _ZenSplashScreenState extends State<ZenSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacementZen(const ZenMainMenuWithBackHandler());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Container(
          decoration: const BoxDecoration(gradient: ZenColors.zenGradient),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                ZenColors.bambooGreen.withOpacity(0.8),
                                ZenColors.bambooGreen.withOpacity(0.4),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.spa,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'Garden of Petals',
                          style: ZenTypography.heading.copyWith(
                            fontSize: 32,
                            color: ZenColors.earthBrown,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Harmonia em cada movimento',
                          style: ZenTypography.body.copyWith(
                            color: ZenColors.stoneGray,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ZenMainMenuWithBackHandler extends StatefulWidget {
  const ZenMainMenuWithBackHandler({super.key});

  @override
  State<ZenMainMenuWithBackHandler> createState() =>
      _ZenMainMenuWithBackHandlerState();
}

class _ZenMainMenuWithBackHandlerState
    extends State<ZenMainMenuWithBackHandler> {
  bool _imageExists = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkImageAvailability();
  }

  Future<void> _checkImageAvailability() async {
    try {
      print("🔍 Verificando se imagem home_background.jpg existe...");

      await rootBundle.load('assets/images/home_background.jpg');

      print("✅ Imagem home_background.jpg encontrada!");

      if (mounted) {
        setState(() {
          _imageExists = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Imagem home_background.jpg NÃO encontrada: $e");
      print(
        "📁 Verifique se o arquivo está em: assets/images/home_background.jpg",
      );
      print("📋 Verifique se está declarado no pubspec.yaml");

      if (mounted) {
        setState(() {
          _imageExists = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (kDebugMode) {
      print("[BACK_HANDLER] 🔙 Botão voltar pressionado na home page");
    }

    final shouldExit = await ExitDialogManager.instance.showExitDialog(context);

    if (kDebugMode) {
      print(
        "[BACK_HANDLER] 🤔 Usuário decidiu ${shouldExit ? 'SAIR' : 'FICAR'}",
      );
    }

    return shouldExit;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              _buildBackground(),
              _buildPetalAnimation(),
              _buildMenuContent(context),
              if (_isLoading) _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_isLoading) {
      return _buildZenGradientBackground();
    }

    if (_imageExists) {
      print("🖼️ Carregando imagem de fundo...");
      return Image.asset(
        'assets/images/home_background.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print("❌ ERRO ao carregar imagem: $error");
          print("📍 Stack trace: $stackTrace");
          return _buildZenGradientBackground();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            print("✅ Imagem carregada sincronamente");
            return child;
          }

          if (frame == null) {
            print("⏳ Carregando frame da imagem...");
            return _buildZenGradientBackground();
          }

          print("✅ Imagem carregada com sucesso!");
          return child;
        },
      );
    } else {
      print("🎨 Usando gradiente zen como fundo");
      return _buildZenGradientBackground();
    }
  }

  Widget _buildZenGradientBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F8F8),
            Color(0xFFE8F5E8),
            Color(0xFFFFF8DC),
            Color(0xFFE6F3FF),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: CustomPaint(painter: ZenPatternPainter(), size: Size.infinite),
    );
  }

  Widget _buildPetalAnimation() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.4,
        child: GameWidget<PetalFallGame>.controlled(
          gameFactory: PetalFallGame.new,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ZenColors.bambooGreen),
        ),
      ),
    );
  }

  Widget _buildMenuContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
        left: 24,
        right: 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.05),
              Colors.transparent,
              Colors.black.withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            _buildLogoSection(),
            const Spacer(),
            _buildMenuButtons(context),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: ZenColors.bambooGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ZenColors.bambooGreen.withOpacity(0.8),
                  ZenColors.bambooGreen.withOpacity(0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ZenColors.bambooGreen.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.spa, size: 50, color: Colors.white),
          ),

          const SizedBox(height: 24),

          Text(
            'Garden of Petals',
            style: ZenTypography.heading.copyWith(
              fontSize: 36,
              color: ZenColors.earthBrown,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Harmonia em cada movimento',
            style: ZenTypography.body.copyWith(
              color: ZenColors.stoneGray,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: ZenColors.bambooGreen.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildMenuButton(
            context,
            label: 'Jogar',
            icon: Icon(Icons.play_arrow_rounded, size: 24),
            onPressed: () =>
                Navigator.of(context).pushZen(const ZenLevelSelectionScreen()),
          ),

          const SizedBox(height: 16),

          _buildMenuButton(
            context,
            label: 'Configurações',
            icon: Icon( Icons.settings_outlined, size: 24),
            onPressed: () =>
                Navigator.of(context).pushZen(const ZenSettingsScreen()),
          ),

          // ✅ 2. ADICIONE O BOTÃO PARA O JARDIM ZEN AQUI
                const SizedBox(height: 20),
                _buildMenuButton(context, label: 'Jardim Zen', icon: ZenGardenIcon(), onPressed: () => Navigator.of(context).pushZen(const ZenGardenScreen()),
                    ),

          if (kDebugMode) ...[
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              label: 'Debug Tutorial',
              icon: Icon( Icons.bug_report, size: 24),
              onPressed: () =>
                  Navigator.of(context).pushZen(const DebugTutorialScreen()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ZenColors.bambooGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: ZenColors.bambooGreen.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

class ZenPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZenColors.bambooGreen.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width * 0.7, size.height * 0.3);
    for (int i = 1; i <= 8; i++) {
      canvas.drawCircle(center, i * 30.0, paint);
    }

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ZenGameScreen extends StatelessWidget {
  const ZenGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ZenColors.zenGradient),
        child: const Center(
          child: Text(
            'Jogo Zen\n(Em desenvolvimento)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: ZenColors.stoneGray),
          ),
        ),
      ),
    );
  }
}

class ZenVictoryScreen extends StatelessWidget {
  const ZenVictoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ZenVictoryPanel(
        game: null as dynamic,
        onContinue: () {
          Navigator.of(
            context,
          ).pushReplacementZen(const ZenLevelSelectionScreen());
        },
        onMenu: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/menu', (route) => false);
        },
      ),
    );
  }
}

class DebugTutorialScreen extends StatefulWidget {
  const DebugTutorialScreen({super.key});

  @override
  State<DebugTutorialScreen> createState() => _DebugTutorialScreenState();
}

class _DebugTutorialScreenState extends State<DebugTutorialScreen> {
  final BombTutorialManager _tutorialManager = BombTutorialManager.instance;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _tutorialManager.getDebugStatus();
    setState(() {
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Tela de debug não disponível em produção')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Tutorial da Bomba'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ZenColors.zenGradient),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Atual:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ..._status.entries.map(
                        (entry) => Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _tutorialManager.resetTutorialFlags();
                    await _loadStatus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flags resetadas!')),
                    );
                  },
                  child: const Text('Reset Tutorial Flags'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final shouldShow = await _tutorialManager
                        .processBombEncounter();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deve mostrar tutorial: $shouldShow'),
                      ),
                    );
                    await _loadStatus();
                  },
                  child: const Text('Simular Encontro com Bomba'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadStatus,
                  child: const Text('Atualizar Status'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class ZenTypography {
  static const TextStyle heading = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: 2.0,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.0,
    height: 1.6,
  );
}
