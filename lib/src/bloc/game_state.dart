// lib/src/bloc/game_state.dart
part of 'game_bloc.dart';

@immutable
abstract class GameState {}

/// Estado que representa o jogo em andamento.
/// A 'key' é usada para forçar a reconstrução do widget do jogo.
class GamePlayState extends GameState {
  final UniqueKey key;
  GamePlayState() : key = UniqueKey();
}