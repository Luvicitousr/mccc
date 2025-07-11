// lib/src/bloc/game_state.dart
part of 'game_bloc.dart';

@immutable
abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial, antes de qualquer nível ser carregado.
class GameInitial extends GameState {}

/// ✅ ESTADO NECESSÁRIO: Representa que um nível está carregado e pronto para ser jogado.
/// A GamePage usa este estado para obter a definição do nível.
class GameReady extends GameState {
  final LevelDefinition level;

  const GameReady(this.level);

  @override
  List<Object?> get props => [level];
}

/// Estado que representa o jogo em andamento.
/// A 'key' é usada para forçar a reconstrução do widget do jogo, se necessário.
class GamePlayState extends GameState {
  final UniqueKey key;
  GamePlayState() : key = UniqueKey();

  @override
  List<Object?> get props => [key];
}