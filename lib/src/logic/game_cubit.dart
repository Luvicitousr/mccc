import 'package:bloc/bloc.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(GameState.initial);

  void startGame() => emit(state.copyWith(status: GameStatus.playing));
  void updateScore(int delta) => emit(state.copyWith(score: state.score + delta));
  // outros eventos: tileMatched, gameOver...
}
