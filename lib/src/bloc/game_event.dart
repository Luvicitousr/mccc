// lib/src/bloc/game_event.dart
part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

/// ✅ NOVO EVENTO: Disparado quando um nível é selecionado para ser jogado.
/// O GameLauncher dispara este evento, e o GameBloc o ouve para
/// carregar a definição do nível e emitir um estado GameReady.
class GameLevelSelected extends GameEvent {
  final int levelNumber;

  const GameLevelSelected(this.levelNumber);

  @override
  List<Object> get props => [levelNumber];
}


/// Evento disparado para reiniciar o nível atual.
class ResetGameEvent extends GameEvent {
  // Construtor const adicionado para consistência.
  const ResetGameEvent();
}
