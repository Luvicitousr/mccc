// lib/src/game/candy_game.dart
import 'dart:async';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../audio/audio_manager.dart';
import '../bloc/game_bloc.dart';
import '../engine/board.dart';
import '../engine/petal_piece.dart';
import '../ui/game_board_widget.dart';

const double kVirtualResolution = 640;
const int kPieceCount = 8;

class CandyGame extends FlameGame with DragCallbacks {
  final GameBloc bloc;
  CandyGame({required this.bloc});

  late final GameBoard board;
  StreamSubscription<GameState>? _blocSubscription;
  bool _isSwapping = false;
  late int startRow, startCol;
  
  double get pieceSize => kVirtualResolution / kPieceCount;

  final World world = World();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    camera.world = world;
    camera.viewport = FixedAspectRatioViewport(aspectRatio: 1.0);
    camera.viewfinder.anchor = Anchor.center;
    
    await add(world);

    await images.loadAll(PetalPiece.petalSprites.values.where((path) => !path.contains('empty')).toList());
    await AudioManager().init();

    board = GameBoard(
      gridSize: Vector2.all(kPieceCount.toDouble()),
      pieceSize: pieceSize,
    );
    
    // Injeta a referência do board no BLoC, que foi recebida via construtor
    bloc.board = board; 
    
    await world.add(board);
    
    camera.viewfinder.position = board.size / 2;
    camera.viewfinder.zoom = kVirtualResolution / camera.viewport.size.x;
    
    await board.populateBoard();

    overlays.add(GameBoardWidget.overlayKey);
    _blocSubscription = bloc.stream.listen(_onGameStateChanged);
    bloc.add(InitializeGame());
  }

  void _onGameStateChanged(GameState state) {
    if (state is GameStateUpdated && state.animation != null) {
      world.add(state.animation!);
    }
  }

  void handleSwap(int row1, int col1, int row2, int col2) {
    if (bloc.state.status != GameStatus.idle) return;
    if (!board.isValidPosition(row2, col2)) return;
    bloc.add(SwapPieces(row1, col1, row2, col2));
  }
  
  @override
  void onDragStart(DragStartEvent event) {
    if (bloc.state.status != GameStatus.idle) return;
    super.onDragStart(event);
    _isSwapping = false;
    final touchPositionInWorld = camera.globalToLocal(event.canvasPosition);
    startRow = (touchPositionInWorld.y / pieceSize).floor();
    startCol = (touchPositionInWorld.x / pieceSize).floor();
    if (board.isValidPosition(startRow, startCol)) {
        bloc.add(SelectPiece(startRow, startCol));
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (bloc.state.status != GameStatus.idle) return;
    if (_isSwapping) return;
    super.onDragUpdate(event);
    final delta = event.localDelta;
    const double swipeThreshold = 10.0;
    int endRow = startRow;
    int endCol = startCol;

    if (delta.x.abs() > delta.y.abs()) {
      if (delta.x > swipeThreshold) { endCol++; } 
      else if (delta.x < -swipeThreshold) { endCol--; }
    } else {
      if (delta.y > swipeThreshold) { endRow++; } 
      else if (delta.y < -swipeThreshold) { endRow--; }
    }

    if (endRow != startRow || endCol != startCol) {
      _isSwapping = true;
      if (board.isValidPosition(endRow, endCol)) {
        handleSwap(startRow, startCol, endRow, endCol);
      }
    }
  }
  
  @override
  void onRemove() {
    _blocSubscription?.cancel();
    super.onRemove();
  }
}