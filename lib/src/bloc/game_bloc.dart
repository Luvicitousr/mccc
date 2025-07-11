// lib/src/bloc/game_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../engine/level_definition.dart';
import '../game/level_manager.dart';

// Importa os arquivos de evento e estado como partes deste arquivo.
part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  // ✅ CORREÇÃO 1: O estado inicial deve ser 'GameInitial'.
  GameBloc() : super(GameInitial()) {
    // ✅ CORREÇÃO 2: Registra o handler para o novo evento 'GameLevelSelected'.
    on<GameLevelSelected>(_onLevelSelected);

    // Mantém o handler para o evento de reset.
    on<ResetGameEvent>(_onResetGame);
  }

  /// ✅ NOVO HANDLER: Chamado quando um nível é selecionado.
  void _onLevelSelected(GameLevelSelected event, Emitter<GameState> emit) {
    if (kDebugMode) {
      print(
        "[BLoC] Evento GameLevelSelected recebido para o nível ${event.levelNumber}",
      );
    }

    // 1. Carrega a definição do nível usando o LevelManager.
    final levelDefinition = LevelManager.instance.loadLevel(event.levelNumber);

    // 2. Emite o estado GameReady com a definição do nível.
    // A GamePage está ouvindo por este estado para poder construir o jogo.
    emit(GameReady(levelDefinition));

    if (kDebugMode) {
      print(
        "[BLoC] Estado GameReady emitido com o nível: ${levelDefinition.title}",
      );
    }
  }

  /// Isso garante que a aplicação esteja pronta para receber um novo evento
  /// de seleção de nível a partir de um estado limpo.
  void _onResetGame(ResetGameEvent event, Emitter<GameState> emit) {
    if (kDebugMode) {
      print(
        "[BLoC] Evento ResetGameEvent recebido. Voltando para o estado GameInitial.",
      );
    }
    // Emite o estado inicial para 'limpar' o estado atual.
    emit(GameInitial());
  }
}
