// lib/src/bloc/game_event.dart
part of 'game_bloc.dart';

@immutable
abstract class GameEvent {}

/// Evento disparado para reiniciar o nível atual.
class ResetGameEvent extends GameEvent {}