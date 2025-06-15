// lib/src/bloc/game_bloc.dart
import 'dart:async';
import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:isolate';
import '../engine/board.dart';
import '../engine/petal_piece.dart';
import '../engine/matcher.dart';
import '../utils/animations.dart';
import '../utils/particle_effect.dart';
import '../audio/audio_manager.dart';

// Função Top-Level para o Isolate
List<MatchData> _findMatchesInIsolate(List<List<PetalType>> gridTypes) {
  final matcher = PetalMatcher();
  final logicalGrid = gridTypes.map((row) => row.map((type) => PetalPiece(type)).toList()).toList();
  return matcher.findMatches(logicalGrid);
}

// Eventos
abstract class GameEvent extends Equatable { const GameEvent(); @override List<Object?> get props => []; }
class InitializeGame extends GameEvent {}
class SelectPiece extends GameEvent { final int row, col; const SelectPiece(this.row, this.col); @override List<Object?> get props => [row, col]; }
class SwapPieces extends GameEvent { final int row1, col1, row2, col2; const SwapPieces(this.row1, this.col1, this.row2, this.col2); @override List<Object?> get props => [row1, col1, row2, col2]; }
class UndoSwap extends GameEvent { final int row1, col1, row2, col2; const UndoSwap(this.row1, this.col1, this.row2, this.col2); @override List<Object?> get props => [row1, col1, row2, col2]; }
class FinalizeSwap extends GameEvent { final int row1, col1, row2, col2; const FinalizeSwap(this.row1, this.col1, this.row2, this.col2); @override List<Object?> get props => [row1, col1, row2, col2]; }
class HandleMatches extends GameEvent { final Set<Offset> matches; const HandleMatches({required this.matches}); @override List<Object?> get props => [matches]; }
class IncrementMultiplier extends GameEvent {}
class ApplyGravityAndRefill extends GameEvent {}
class SpecialPieceCreated extends GameEvent { final PetalPiece petal; const SpecialPieceCreated(this.petal); @override List<Object> get props => [petal]; }

// Estados
enum GameStatus { idle, animating }
abstract class GameState extends Equatable { final GameStatus status; const GameState({required this.status}); @override List<Object?> get props => [status]; }
class GameInitial extends GameState { const GameInitial() : super(status: GameStatus.idle); }
class GameStateUpdated extends GameState {
  final GameBoard board;
  final Component? animation;
  const GameStateUpdated({required this.board, required GameStatus status, this.animation}) : super(status: status);
  @override
  List<Object?> get props => [board, status, animation];
}

// BLoC
class GameBloc extends Bloc<GameEvent, GameState> {
  // A referência do tabuleiro é 'late' porque será injetada pela CandyGame.
  late GameBoard board;

  // O construtor volta a ser simples.
  GameBloc() : super(const GameInitial()) {
    // Registra todos os seus handlers de evento
    on<InitializeGame>(_onInitializeGame);
    on<SwapPieces>(_onSwapPieces);
    on<UndoSwap>(_onUndoSwap);
    on<FinalizeSwap>(_onFinalizeSwap);
    on<HandleMatches>(_onHandleMatches);
    on<IncrementMultiplier>(_onIncrementMultiplier);
    on<SelectPiece>(_onSelectPiece);
    on<ApplyGravityAndRefill>(_onApplyGravityAndRefill);
    on<SpecialPieceCreated>(_onSpecialPieceCreated);
  }

  void _onInitializeGame(InitializeGame event, Emitter<GameState> emit) {
    board.setBloc(this);
    emit(GameStateUpdated(board: board, status: GameStatus.idle));
  }
  
  void _onSelectPiece(SelectPiece event, Emitter<GameState> emit) { print("BLOC: Peça selecionada na posição: (${event.row}, ${event.col})"); }

  void _onSwapPieces(SwapPieces event, Emitter<GameState> emit) {
    emit(GameStateUpdated(board: board, status: GameStatus.animating));
    final swapAnimation = SwapAnimation(board: board, row1: event.row1, col1: event.col1, row2: event.row2, col2: event.col2, onComplete: () => add(FinalizeSwap(event.row1, event.col1, event.row2, event.col2)));
    AudioManager().playSwapSound();
    emit(GameStateUpdated(board: board, status: GameStatus.animating, animation: swapAnimation));
  }

  void _onUndoSwap(UndoSwap event, Emitter<GameState> emit) {
    final swapBackAnimation = SwapAnimation(board: board, row1: event.row1, col1: event.col1, row2: event.row2, col2: event.col2, onComplete: () {
      board.swapPieces(event.row1, event.col1, event.row2, event.col2);
      emit(GameStateUpdated(board: board, status: GameStatus.idle));
    });
    emit(GameStateUpdated(board: board, status: GameStatus.animating, animation: swapBackAnimation));
  }

  Future<void> _onFinalizeSwap(FinalizeSwap event, Emitter<GameState> emit) async {
    board.swapPieces(event.row1, event.col1, event.row2, event.col2);
    final gridTypes = board.getGridTypes();
    final List<MatchData> matches = await Isolate.run(() => _findMatchesInIsolate(gridTypes));
    if (matches.isNotEmpty) {
      final piecesToClear = board.processMatches(matches);
      add(HandleMatches(matches: piecesToClear));
    } else {
      AudioManager().playErrorSound();
      add(UndoSwap(event.row2, event.col2, event.row1, event.col1));
    }
  }

  void _onHandleMatches(HandleMatches event, Emitter<GameState> emit) {
    final effectsContainer = Component();
    final cascadeLevel = board.multiplier;
    final matchedPieces = event.matches.map((offset) => board.pieceAt(offset.dy.toInt(), offset.dx.toInt())).toList();
    effectsContainer.add(MatchAnimation(matchedPieces: matchedPieces, cascadeLevel: cascadeLevel, onComplete: () {
      board.markMatchesAsEmpty(event.matches);
      add(ApplyGravityAndRefill());
    }));
    effectsContainer.add(MatchParticleEffect(matchedPieces: matchedPieces, cascadeLevel: cascadeLevel));
    AudioManager().playMatchSound();
    emit(GameStateUpdated(board: board, status: GameStatus.animating, animation: effectsContainer));
  }

  Future<void> _onApplyGravityAndRefill(ApplyGravityAndRefill event, Emitter<GameState> emit) async {
    await board.applyGravityAndRefill();
    final matchesData = board.findMatches();
    if (matchesData.isNotEmpty) {
      final piecesToClear = board.processMatches(matchesData);
      add(HandleMatches(matches: piecesToClear));
      add(IncrementMultiplier());
    } else {
      board.resetMultiplier();
      emit(GameStateUpdated(board: board, status: GameStatus.idle));
    }
  }

  void _onSpecialPieceCreated(SpecialPieceCreated event, Emitter<GameState> emit) {
    final petal = event.petal;
    petal.add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 1.0, infinite: true, alternate: true)));
    petal.add(OpacityEffect.to(0.7, EffectController(duration: 1.0, infinite: true, alternate: true)));
    emit(GameStateUpdated(board: board, status: state.status));
  }
  
  void _onIncrementMultiplier(IncrementMultiplier event, Emitter<GameState> emit) {
    board.incrementMultiplier();
    emit(GameStateUpdated(board: board, status: state.status));
  }
}