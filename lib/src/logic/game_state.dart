// Em: lib/src/logic/game_state.dart
import 'package:equatable/equatable.dart';

// Enum para controlar os diferentes status do jogo de forma segura.
enum GameStatus { initial, playing, paused, finished }

// A classe de estado imutável para o jogo.
class GameState extends Equatable {
  final GameStatus status;
  final int score;

  // Construtor principal.
  const GameState({
    required this.status,
    required this.score,
  });

  static const initial = GameState(status: GameStatus.initial,
        score: 0);

  // O método copyWith, essencial para o Cubit emitir novos estados.
  GameState copyWith({
    GameStatus? status,
    int? score,
  }) {
    return GameState(
      status: status ?? this.status,
      score: score ?? this.score,
    );
  }

  // Necessário para o Equatable.
  @override
  List<Object> get props => [status, score];
}