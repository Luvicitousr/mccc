// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'src/game/candy_game.dart';
import 'src/bloc/game_bloc.dart';
import 'src/ui/game_board_widget.dart';
import 'src/engine/board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // As instâncias principais são criadas e mantidas aqui
  late final GameBloc _gameBloc;
  late final CandyGame _game;

  @override
  void initState() {
    super.initState();
    // 1. Cria o BLoC primeiro.
    _gameBloc = GameBloc();
    // 2. Cria o Jogo, injetando o BLoC.
    _game = CandyGame(bloc: _gameBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petal Crush',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // Usa BlocProvider.value para fornecer a instância do BLoC já criada
        body: BlocProvider.value(
          value: _gameBloc,
          child: GameWidget(
            game: _game,
            overlayBuilderMap: {
              GameBoardWidget.overlayKey: (context, game) {
                return const GameBoardWidget();
              },
            },
          ),
        ),
      ),
    );
  }
}