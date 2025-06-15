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
    
    // Configura o mundo e a câmera
    camera.world = world;
    camera.viewport = FixedAspectRatioViewport(aspectRatio: 1.0);
    camera.viewfinder.anchor = Anchor.center;
    
    await add(world);

    // Pré-carrega todos os assets ANTES de criar qualquer peça
    await images.loadAll(PetalPiece.petalSprites.values.where((path) => !path.contains('empty')).toList());
    await AudioManager().init();

    // Cria o tabuleiro com o tamanho de peça já calculado
    board = GameBoard(
      gridSize: Vector2.all(kPieceCount.toDouble()),
      pieceSize: pieceSize,
    );
    
    // Injeta a referência do board no BLoC
    bloc.board = board; 
    
    // Adiciona o tabuleiro ao mundo e espera ele carregar
    await world.add(board);
    
    // Centraliza a câmera no tabuleiro e define o zoom
    camera.viewfinder.position = board.size / 2;
    camera.viewfinder.zoom = kVirtualResolution / camera.viewport.size.x;
    
    // Manda o tabuleiro se popular com as peças
    await board.populateBoard();

    // Adiciona o overlay da UI e começa a ouvir o BLoC
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