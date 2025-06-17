// lib/main.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart'; // Importe o Material
import 'package:flutter/widgets.dart';
// 1. Importe o pacote que acabamos de adicionar.
import 'package:wakelock_plus/wakelock_plus.dart';
// 1. Importe a biblioteca de serviços do Flutter.
import 'package:flutter/services.dart';
// Importe as telas de UI que criamos/modificamos
import 'src/ui/home_page.dart';
import 'src/ui/game_page.dart';

// 2. Transforme a função main em assíncrona (async).
Future<void> main() async {
  // 2. Garante que os bindings do Flutter sejam inicializados antes de chamar o pacote.
  //    Isso é necessário para que o Wakelock funcione corretamente.
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Ativa o Wakelock para manter a tela ligada.
  WakelockPlus.enable();

  // 3. Adicione o código para travar a orientação.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Permite a orientação retrato padrão.
    DeviceOrientation.portraitDown, // Permite a orientação retrato de cabeça para baixo.
  ]);
  // ✅ AÇÃO CORRIGIDA: Inicie um MaterialApp, não um GameWidget.
  runApp(const MyApp());
}

/// O Widget raiz do seu aplicativo.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Desativa a faixa de "Debug" no canto da tela.
      debugShowCheckedModeBanner: false,
      title: 'Candy Game',
      // A tela inicial do aplicativo será a HomePage.
      home: HomePage(),
      // Define as rotas nomeadas para navegação.
      routes: {
        '/play': (context) => const GamePage(),
      },
    );
  }
}