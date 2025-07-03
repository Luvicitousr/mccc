import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import '../engine/petal_piece.dart';
import '../engine/action_manager.dart';
import '../actions/swap_pieces_action.dart';
import '../actions/remove_pieces_action.dart';
import '../actions/callback_action.dart';
import 'bomb_mechanics.dart';

/// 🎮 Manipulador de Ativação de Bomba - VERSÃO CORRIGIDA PARA OBJETIVOS E CAGED
/// ✅ CORREÇÕES APLICADAS:
/// - Tratamento correto de peças caged (contador de dano)
/// - Atualização precisa de objetivos baseada em peças efetivamente removidas
/// - Sequência correta: explosão → aplicação de efeitos → atualização de objetivos
/// - Validações para evitar contagem dupla
class BombActivationHandler {
  final ActionManager actionManager;
  final List<PetalPiece> pieces;
  final List<Aabb2> pieceSlots;
  final int levelWidth;
  final ValueNotifier<int> movesLeft;
  final ValueNotifier<Map<PetalType, int>> objectives;
  final Function() startCascade;

  // Callbacks para eventos
  Function(Vector2)? onBombCreated;
  Function(Vector2, double)? onBombExploded;
  Function()? onFirstBombFound;
  Function(int)? onChainReaction;
  Function(Vector2)? onBombCreatedWithImmediateTutorial;

  // Estado interno
  bool _isActivating = false;
  bool _hasTutorialBeenShown = false;

  // ✅ NOVO: Controle de recursão e bombas processadas
  final Set<PetalPiece> _processedBombs = {};
  int _chainDepth = 0;
  static const int _maxChainDepth = 10;

  BombActivationHandler({
    required this.actionManager,
    required this.pieces,
    required this.pieceSlots,
    required this.levelWidth,
    required this.movesLeft,
    required this.objectives,
    required this.startCascade,
  });

  /// 🎯 Verifica se uma peça é uma bomba
  bool isBomb(PetalPiece piece) {
    return piece.type == PetalType.bomb;
  }

  /// 💥 Ativa bomba a partir de um movimento - VERSÃO CORRIGIDA PARA OBJETIVOS
  Future<bool> activateBombFromMove(int fromIndex, int toIndex) async {
    if (_isActivating) {
      if (kDebugMode) {
        print("[BOMB_HANDLER] ⏸️ Já existe uma ativação em andamento");
      }
      return false;
    }

    _isActivating = true;
    _processedBombs.clear();
    _chainDepth = 0;

    try {
      final fromPiece = pieces[fromIndex];
      final toPiece = pieces[toIndex];

      // Verifica qual peça é a bomba
      final bombPiece = isBomb(fromPiece) ? fromPiece : toPiece;
      final otherPiece = isBomb(fromPiece) ? toPiece : fromPiece;

      // Verifica se é a primeira vez que o jogador encontra uma bomba
      if (!_hasTutorialBeenShown) {
        _hasTutorialBeenShown = true;
        onFirstBombFound?.call();
      }

      if (kDebugMode) {
        print("[BOMB_HANDLER] 💣 Iniciando ativação de bomba");
      }

      // Decrementa movimentos
      movesLeft.value--;

      // 1. Executa animação de swap
      final bombPosition = pieceSlots[pieces.indexOf(bombPiece)].min;
      final otherPosition = pieceSlots[pieces.indexOf(otherPiece)].min;

      await _executeSwapAnimation(
          bombPiece, otherPiece, bombPosition, otherPosition);

      // 2. Calcula área de explosão
      final bombIndex = pieces.indexOf(bombPiece);
      final bombCol = bombIndex % levelWidth;
      final bombRow = (bombIndex / levelWidth).floor();

      if (kDebugMode) {
        print("[BOMB_HANDLER] 📍 Bomba localizada em ($bombCol, $bombRow)");
      }

      // 3. ✅ CORREÇÃO: Coleta peças afetadas com análise detalhada
      final explosionResult = _analyzeExplosionEffects(bombCol, bombRow);

      // 4. Notifica explosão para efeitos visuais
      final explosionCenter = Vector2(
        bombPosition.x + 32,
        bombPosition.y + 32,
      );
      onBombExploded?.call(explosionCenter, 160);

      // 5. ✅ CORREÇÃO: Executa sequência correta de efeitos
      await _executeExplosionSequence(explosionResult);

      // 6. Inicia cascata
      startCascade();

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("[BOMB_HANDLER] ❌ Erro durante ativação: $e");
        print("[BOMB_HANDLER] Stack trace: $stackTrace");
      }
      return false;
    } finally {
      _isActivating = false;
      _processedBombs.clear();
      _chainDepth = 0;
    }
  }

  /// 💥 ✅ NOVO: Analisa efeitos da explosão com detalhamento de danos
  ExplosionResult _analyzeExplosionEffects(int bombCol, int bombRow) {
    final affectedPieces = <PetalPiece>{};
    final bombsToProcess = <({int col, int row})>[];
    final processedPositions = <String>{};
    final pieceEffects = <PetalPiece, PieceEffect>{};

    // Adiciona bomba inicial
    bombsToProcess.add((col: bombCol, row: bombRow));

    if (kDebugMode) {
      print("[BOMB_HANDLER] 🔍 Analisando efeitos da explosão...");
    }

    while (bombsToProcess.isNotEmpty && _chainDepth < _maxChainDepth) {
      final currentBomb = bombsToProcess.removeAt(0);
      final positionKey = "${currentBomb.col},${currentBomb.row}";

      if (processedPositions.contains(positionKey)) {
        continue;
      }

      processedPositions.add(positionKey);
      _chainDepth++;

      // Processa área 5x5 ao redor da bomba atual
      final currentAffected =
          _getExplosionArea(currentBomb.col, currentBomb.row);

      for (final piece in currentAffected) {
        if (!affectedPieces.contains(piece)) {
          affectedPieces.add(piece);

          // ✅ CORREÇÃO: Analisa efeito específico para cada peça
          final effect = _analyzePieceEffect(piece);
          pieceEffects[piece] = effect;

          if (kDebugMode) {
            print(
                "[BOMB_HANDLER] 📊 Peça ${piece.type} → ${effect.resultType} (removida: ${effect.willBeRemoved})");
          }

          // Verifica se é uma nova bomba para reação em cadeia
          if (piece.type == PetalType.bomb &&
              !_processedBombs.contains(piece)) {
            final pieceIndex = pieces.indexOf(piece);
            if (pieceIndex != -1) {
              final newBombCol = pieceIndex % levelWidth;
              final newBombRow = (pieceIndex / levelWidth).floor();
              final newPositionKey = "$newBombCol,$newBombRow";

              if (!processedPositions.contains(newPositionKey)) {
                bombsToProcess.add((col: newBombCol, row: newBombRow));
                _processedBombs.add(piece);

                if (kDebugMode) {
                  print(
                      "[BOMB_HANDLER] 💣 Bomba em cadeia: ($newBombCol, $newBombRow)");
                }

                onChainReaction?.call(currentAffected.length);
              }
            }
          }
        }
      }
    }

    return ExplosionResult(
      affectedPieces: affectedPieces,
      pieceEffects: pieceEffects,
      chainDepth: _chainDepth,
    );
  }

  /// 🔍 ✅ NOVO: Analisa efeito específico de uma peça
  PieceEffect _analyzePieceEffect(PetalPiece piece) {
    switch (piece.type) {
      case PetalType.caged1:
        // ✅ CORREÇÃO: Caged1 recebe 1 dano → vira Caged2 (não é removida)
        return PieceEffect(
          originalType: piece.type,
          resultType: PetalType.caged2,
          willBeRemoved: false,
          damageApplied: 1,
        );

      case PetalType.caged2:
        // ✅ CORREÇÃO: Caged2 recebe 1 dano → é removida (vira empty)
        return PieceEffect(
          originalType: piece.type,
          resultType: PetalType.empty,
          willBeRemoved: true,
          damageApplied: 1,
        );

      case PetalType.bedrock:
        // Bedrock é indestrutível
        return PieceEffect(
          originalType: piece.type,
          resultType: piece.type,
          willBeRemoved: false,
          damageApplied: 0,
        );

      case PetalType.bomb:
        // Bombas são detonadas (removidas)
        return PieceEffect(
          originalType: piece.type,
          resultType: PetalType.empty,
          willBeRemoved: true,
          damageApplied: 0,
        );

      default:
        // Peças normais são removidas
        return PieceEffect(
          originalType: piece.type,
          resultType: PetalType.empty,
          willBeRemoved: true,
          damageApplied: 0,
        );
    }
  }

  /// 🎬 ✅ NOVO: Executa sequência completa de explosão
  Future<void> _executeExplosionSequence(
      ExplosionResult explosionResult) async {
    if (kDebugMode) {
      print("[BOMB_HANDLER] 🎬 Executando sequência de explosão...");
    }

    // Usa o getter que já filtra as peças corretas para a animação.
    await _executeRemoveAnimation(explosionResult.removedPieces);

    // 2. ✅ CORREÇÃO: Aplica efeitos às peças (dano, transformações)
    _applyExplosionEffects(explosionResult);

    // 3. ✅ CORREÇÃO: Atualiza objetivos baseado em peças efetivamente removidas
    _updateObjectivesFromExplosion(explosionResult);

    if (kDebugMode) {
      print("[BOMB_HANDLER] ✅ Sequência de explosão concluída");
    }
  }

  /// ⚡ ✅ CORREÇÃO: Aplica efeitos baseado na análise detalhada
  void _applyExplosionEffects(ExplosionResult explosionResult) {
    if (kDebugMode) {
      print("[BOMB_HANDLER] ⚡ Aplicando efeitos da explosão...");
    }

    for (final piece in explosionResult.affectedPieces) {
      final effect = explosionResult.pieceEffects[piece];
      if (effect != null) {
        // Aplica a transformação determinada na análise
        piece.changeType(effect.resultType);

        if (kDebugMode) {
          print(
              "[BOMB_HANDLER] 🔄 ${effect.originalType} → ${effect.resultType}");
        }
      }
    }
  }

  /// 🎯 ✅ CORREÇÃO: Atualiza objetivos baseado em peças efetivamente removidas
  void _updateObjectivesFromExplosion(ExplosionResult explosionResult) {
    final currentObjectives = Map<PetalType, int>.from(objectives.value);
    bool objectivesUpdated = false;
    final removedPiecesCount = <PetalType, int>{};

    if (kDebugMode) {
      print("[BOMB_HANDLER] 🎯 Atualizando objetivos baseado na explosão...");
    }

    // ✅ CORREÇÃO: Conta apenas peças que foram efetivamente removidas
    for (final piece in explosionResult.affectedPieces) {
      final effect = explosionResult.pieceEffects[piece];

      // Adiciona a condição 'effect.originalType != PetalType.bomb'
      if (effect != null &&
          effect.willBeRemoved &&
          effect.originalType != PetalType.bomb) {
        // Conta a peça original que foi removida
        final originalType = effect.originalType;
        removedPiecesCount[originalType] =
            (removedPiecesCount[originalType] ?? 0) + 1;

        if (kDebugMode) {
          print(
              "[BOMB_HANDLER] 📊 Peça removida para objetivos: $originalType");
        }
      }
    }

    // Atualiza objetivos baseado nas peças removidas
    for (final entry in removedPiecesCount.entries) {
      var pieceType = entry.key;
      final count = entry.value;

      // ✅ CORREÇÃO APLICADA: Se a peça removida for uma jaula nível 2 (caged2),
      // ela deve contar para o objetivo de jaula nível 1 (caged1).
      if (pieceType == PetalType.caged2) {
        pieceType = PetalType.caged1;
      }

      if (currentObjectives.containsKey(pieceType)) {
        final oldValue = currentObjectives[pieceType]!;
        final newValue = (oldValue - count).clamp(0, 999);
        currentObjectives[pieceType] = newValue;
        objectivesUpdated = true;

        if (kDebugMode) {
          print(
              "[BOMB_HANDLER] 🎯 Objetivo $pieceType: $oldValue → $newValue (-$count)");
        }
      }
    }

    // ✅ CORREÇÃO: Conta a bomba ativada pelo jogador separadamente
    if (currentObjectives.containsKey(PetalType.bomb)) {
      final oldValue = currentObjectives[PetalType.bomb]!;
      final newValue = (oldValue - 1).clamp(0, 999);
      currentObjectives[PetalType.bomb] = newValue;
      objectivesUpdated = true;

      if (kDebugMode) {
        print(
            "[BOMB_HANDLER] 💣 Objetivo bomb: $oldValue → $newValue (bomba ativada)");
      }
    }

    // Aplica atualizações se houve mudanças
    if (objectivesUpdated) {
      objectives.value = currentObjectives;

      if (kDebugMode) {
        print("[BOMB_HANDLER] ✅ Objetivos atualizados na interface");
      }
    }
  }

  /// 💥 Obtém área de explosão 5x5
  Set<PetalPiece> _getExplosionArea(int bombCol, int bombRow) {
    final affectedPieces = <PetalPiece>{};
    const explosionRadius = 2;

    for (int row = bombRow - explosionRadius;
        row <= bombRow + explosionRadius;
        row++) {
      for (int col = bombCol - explosionRadius;
          col <= bombCol + explosionRadius;
          col++) {
        if (col < 0 ||
            col >= levelWidth ||
            row < 0 ||
            row >= pieces.length ~/ levelWidth) {
          continue;
        }

        final pieceIndex = row * levelWidth + col;
        if (pieceIndex >= 0 && pieceIndex < pieces.length) {
          final piece = pieces[pieceIndex];
          affectedPieces.add(piece);
        }
      }
    }

    return affectedPieces;
  }

  /// 🎬 Executa animação de swap
  Future<void> _executeSwapAnimation(
    PetalPiece bombPiece,
    PetalPiece otherPiece,
    Vector2 bombPosition,
    Vector2 otherPosition,
  ) async {
    final completer = Completer<void>();

    actionManager
        .push(
      SwapPiecesAction(
        pieceDestinations: {
          bombPiece: otherPosition,
          otherPiece: bombPosition,
        },
        durationMs: 150,
      ),
    )
        .push(
      FunctionAction(() {
        completer.complete();
      }),
    );

    return completer.future;
  }

  /// 🎬 Executa animação de remoção
  Future<void> _executeRemoveAnimation(Set<PetalPiece> affectedPieces) async {
    final completer = Completer<void>();

    actionManager
        .push(
      RemovePiecesAction(
        piecesToRemove: affectedPieces,
      ),
    )
        .push(
      FunctionAction(() {
        completer.complete();
      }),
    );

    return completer.future;
  }

  /// 🎯 Cria bomba a partir de uma combinação de 5+ peças
  void createBombFromMatch(
      Set<PetalPiece> matchedPieces, int swappedPieceIndex) {
    if (matchedPieces.length < 5) {
      return;
    }

    if (kDebugMode) {
      print(
          "[BOMB_HANDLER] 🎯 Criando bomba a partir de combinação de ${matchedPieces.length} peças");
    }

    final bombPiece = pieces[swappedPieceIndex];
    bombPiece.changeType(PetalType.bomb);
    matchedPieces.remove(bombPiece);

    final bombPosition = pieceSlots[swappedPieceIndex].min;
    final bombCenter = Vector2(
      bombPosition.x + 32,
      bombPosition.y + 32,
    );

    if (onBombCreatedWithImmediateTutorial != null) {
      if (kDebugMode) {
        print(
            "[BOMB_HANDLER] 🎓 Notificando criação de bomba com tutorial imediato");
      }
      onBombCreatedWithImmediateTutorial!(bombCenter);
    } else {
      onBombCreated?.call(bombCenter);
    }

    if (kDebugMode) {
      print("[BOMB_HANDLER] 💣 Bomba criada no índice $swappedPieceIndex");
    }
  }

  /// 📊 Getters para estado
  bool get isActivating => _isActivating;
  bool get hasTutorialBeenShown => _hasTutorialBeenShown;
  int get chainDepth => _chainDepth;
  int get processedBombsCount => _processedBombs.length;
  int get maxChainDepth => _maxChainDepth;
}

/// 📊 ✅ NOVO: Classe para resultado da análise de explosão
class ExplosionResult {
  final Set<PetalPiece> affectedPieces;
  final Map<PetalPiece, PieceEffect> pieceEffects;
  final int chainDepth;

  ExplosionResult({
    required this.affectedPieces,
    required this.pieceEffects,
    required this.chainDepth,
  });

  /// Obtém peças que serão efetivamente removidas
  Set<PetalPiece> get removedPieces {
    return affectedPieces.where((piece) {
      final effect = pieceEffects[piece];
      return effect?.willBeRemoved ?? false;
    }).toSet();
  }

  /// Obtém peças que serão transformadas (mas não removidas)
  Set<PetalPiece> get transformedPieces {
    return affectedPieces.where((piece) {
      final effect = pieceEffects[piece];
      return effect != null &&
          !effect.willBeRemoved &&
          effect.originalType != effect.resultType;
    }).toSet();
  }
}

/// 🔍 ✅ NOVO: Classe para efeito específico de uma peça
class PieceEffect {
  final PetalType originalType;
  final PetalType resultType;
  final bool willBeRemoved;
  final int damageApplied;

  PieceEffect({
    required this.originalType,
    required this.resultType,
    required this.willBeRemoved,
    required this.damageApplied,
  });

  @override
  String toString() {
    return 'PieceEffect($originalType → $resultType, removed: $willBeRemoved, damage: $damageApplied)';
  }
}
