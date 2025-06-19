// lib/src/bloc/game_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

// Importa os arquivos de evento e estado como partes deste arquivo.
part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  // O estado inicial é um novo estado de jogo.
  GameBloc() : super(GamePlayState()) {
    // Registra o handler para o evento de reset.
    on<ResetGameEvent>(_onResetGame);
  }

  /// Quando o evento ResetGameEvent é recebido...
  void _onResetGame(ResetGameEvent event, Emitter<GameState> emit) {
    // ...emite um NOVO estado GamePlayState.
    // A criação de uma nova instância com uma nova UniqueKey
    // é o que sinaliza para a UI que ela deve ser reconstruída.
    emit(GamePlayState());
  }
}