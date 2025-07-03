import 'dart:collection';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import '../engine/petal_piece.dart';
import '../engine/level_definition.dart';
import '../effects/zen_bomb_explosion.dart';

/// 💣 Sistema de Mecânicas da Bomba
/// Implementa toda a lógica de ativação, explosão e efeitos em cadeia
class BombMechanics {
  final LevelDefinition level;
  final List<PetalPiece> pieces;
  final Function(Set<PetalPiece>) onPiecesAffected;
  final Function(ZenBombExplosion) onExplosionEffect;

  // Configurações da bomba
  static const int explosionRadius = 2; // Raio de 2 células
  static const Duration chainReactionDelay = Duration(milliseconds: 300);

  BombMechanics({
    required this.level,
    required this.pieces,
    required this.onPiecesAffected,
    required this.onExplosionEffect,
  });

  /// 🎯 Sequência principal de ativação da bomba
  Future<BombActivationResult> activateBomb(PetalPiece bombPiece) async {
    if (kDebugMode) {
      print("[BOMB] 💥 Iniciando sequência de ativação da bomba");
    }

    final bombIndex = pieces.indexOf(bombPiece);
    if (bombIndex == -1) {
      if (kDebugMode) {
        print("[BOMB] ❌ Erro: Bomba não encontrada na lista de peças");
      }
      return BombActivationResult.failed("Bomba não encontrada");
    }

    // 1. Detecta troca válida (já validada antes da chamada)
    if (kDebugMode) {
      print("[BOMB] ✅ Troca válida detectada com bomba");
    }

    // 2. Calcula área de explosão
    final explosionArea = _calculateExplosionArea(bombIndex);

    if (kDebugMode) {
      print(
          "[BOMB] 💥 Área de explosão calculada: ${explosionArea.length} peças afetadas");
    }

    // 3. Processa reações em cadeia
    final chainReactionResult = await _processChainReactions(explosionArea);

    // 4. Cria efeito visual zen
    await _createZenExplosionEffect(bombIndex);

    // 5. Aplica efeitos às peças
    _applyExplosionEffects(chainReactionResult.allAffectedPieces);

    // 6. Notifica sistema principal
    onPiecesAffected(chainReactionResult.allAffectedPieces);

    return BombActivationResult.success(
      bombsDetonated: chainReactionResult.bombsDetonated,
      piecesAffected: chainReactionResult.allAffectedPieces.length,
      chainReactions: chainReactionResult.chainReactions,
    );
  }

  /// 📐 Calcula área de explosão 5x5 ao redor da bomba
  Set<PetalPiece> _calculateExplosionArea(int bombIndex) {
    final affectedPieces = <PetalPiece>{};
    final bombCol = bombIndex % level.width;
    final bombRow = (bombIndex / level.width).floor();

    if (kDebugMode) {
      print("[BOMB] 📍 Bomba localizada em ($bombCol, $bombRow)");
    }

    // Processa área 5x5 (raio 2) com ordem Centro -> Bordas -> Clockwise
    final processOrder = _generateClockwiseProcessOrder(bombCol, bombRow);

    for (final position in processOrder) {
      final col = position.x;
      final row = position.y;

      // Verifica limites do tabuleiro
      if (col < 0 || col >= level.width || row < 0 || row >= level.height) {
        continue;
      }

      final pieceIndex = row * level.width + col;
      if (pieceIndex >= 0 && pieceIndex < pieces.length) {
        final piece = pieces[pieceIndex];
        affectedPieces.add(piece);

        if (kDebugMode && piece.type == PetalType.bomb) {
          print("[BOMB] 💣 Bomba adicional encontrada em ($col, $row)");
        }
      }
    }

    return affectedPieces;
  }

  /// 🔄 Gera ordem de processamento clockwise
  List<math.Point<int>> _generateClockwiseProcessOrder(
      int centerCol, int centerRow) {
    final order = <math.Point<int>>[];

    // 1. Centro primeiro
    order.add(math.Point(centerCol, centerRow));

    // 2. Anéis concêntricos em ordem clockwise
    for (int radius = 1; radius <= explosionRadius; radius++) {
      final ringPositions =
          _generateClockwiseRing(centerCol, centerRow, radius);
      order.addAll(ringPositions);
    }

    return order;
  }

  /// ⭕ Gera posições de um anel em ordem clockwise
  List<math.Point<int>> _generateClockwiseRing(
      int centerCol, int centerRow, int radius) {
    final positions = <math.Point<int>>[];

    // Começa do topo e vai clockwise
    // Topo
    for (int col = centerCol - radius; col <= centerCol + radius; col++) {
      positions.add(math.Point(col, centerRow - radius));
    }

    // Direita (excluindo cantos)
    for (int row = centerRow - radius + 1;
        row <= centerRow + radius - 1;
        row++) {
      positions.add(math.Point(centerCol + radius, row));
    }

    // Baixo (da direita para esquerda)
    for (int col = centerCol + radius; col >= centerCol - radius; col--) {
      positions.add(math.Point(col, centerRow + radius));
    }

    // Esquerda (excluindo cantos)
    for (int row = centerRow + radius - 1;
        row >= centerRow - radius + 1;
        row--) {
      positions.add(math.Point(centerCol - radius, row));
    }

    return positions;
  }

  /// ⛓️ Processa reações em cadeia
  Future<ChainReactionResult> _processChainReactions(
      Set<PetalPiece> initialArea) async {
    final allAffectedPieces = <PetalPiece>{};
    final bombsToDetonate = Queue<PetalPiece>();
    final processedBombs = <PetalPiece>{};
    int chainReactions = 0;

    // Adiciona peças iniciais
    allAffectedPieces.addAll(initialArea);

    // Encontra bombas na área inicial
    for (final piece in initialArea) {
      if (piece.type == PetalType.bomb && !processedBombs.contains(piece)) {
        bombsToDetonate.add(piece);
        processedBombs.add(piece);
      }
    }

    // Processa reações em cadeia
    while (bombsToDetonate.isNotEmpty) {
      final currentBomb = bombsToDetonate.removeFirst();
      final bombIndex = pieces.indexOf(currentBomb);

      if (bombIndex == -1) continue;

      chainReactions++;

      if (kDebugMode) {
        print("[BOMB] ⛓️ Reação em cadeia #$chainReactions");
      }

      // Calcula nova área de explosão
      final newExplosionArea = _calculateExplosionArea(bombIndex);

      // Adiciona novas peças afetadas
      for (final piece in newExplosionArea) {
        if (!allAffectedPieces.contains(piece)) {
          allAffectedPieces.add(piece);

          // Se for uma nova bomba, adiciona à fila
          if (piece.type == PetalType.bomb && !processedBombs.contains(piece)) {
            bombsToDetonate.add(piece);
            processedBombs.add(piece);

            if (kDebugMode) {
              print("[BOMB] 💣 Nova bomba adicionada à cadeia");
            }
          }
        }
      }

      // Delay entre reações para efeito visual
      await Future.delayed(chainReactionDelay);
    }

    return ChainReactionResult(
      allAffectedPieces: allAffectedPieces,
      bombsDetonated: processedBombs.length,
      chainReactions: chainReactions,
    );
  }

  /// 🎨 Cria efeito visual zen da explosão
  Future<void> _createZenExplosionEffect(int bombIndex) async {
    final bombCol = bombIndex % level.width;
    final bombRow = (bombIndex / level.width).floor();

    // Calcula posição no mundo do jogo
    final pieceSize = 64.0; // Tamanho padrão da peça
    final explosionCenter = Vector2(
      bombCol * pieceSize + pieceSize / 2,
      bombRow * pieceSize + pieceSize / 2,
    );

    final maxRadius = explosionRadius * pieceSize;

    final explosion = ZenBombExplosion(
      explosionCenter: explosionCenter,
      maxRadius: maxRadius,
      onComplete: () {
        if (kDebugMode) {
          print("[BOMB] ✨ Efeito visual de explosão concluído");
        }
      },
    );

    onExplosionEffect(explosion);

    if (kDebugMode) {
      print("[BOMB] 🎨 Efeito visual zen criado");
    }
  }

  /// ⚡ Aplica efeitos da explosão às peças
  void _applyExplosionEffects(Set<PetalPiece> affectedPieces) {
    for (final piece in affectedPieces) {
      switch (piece.type) {
        case PetalType.caged1:
          // Aplica 1 ponto de dano
          piece.changeType(PetalType.caged2);
          if (kDebugMode) {
            print("[BOMB] 🔨 Caged1 danificada -> Caged2");
          }
          break;

        case PetalType.caged2:
          // Aplica 1 ponto de dano e remove
          piece.changeType(PetalType.empty);
          if (kDebugMode) {
            print("[BOMB] 💥 Caged2 destruída");
          }
          break;

        case PetalType.bedrock:
          // Bedrock é indestrutível
          if (kDebugMode) {
            print("[BOMB] 🗿 Bedrock resistiu à explosão");
          }
          break;

        case PetalType.bomb:
          // Outras bombas são detonadas (já processadas na cadeia)
          piece.changeType(PetalType.empty);
          if (kDebugMode) {
            print("[BOMB] 💣 Bomba detonada em cadeia");
          }
          break;

        default:
          // Peças normais são removidas imediatamente
          piece.changeType(PetalType.empty);
          if (kDebugMode) {
            print("[BOMB] 🌸 Peça normal removida: ${piece.type}");
          }
          break;
      }
    }
  }

  /// 🎯 Verifica se uma posição está dentro do raio de explosão
  bool _isWithinExplosionRadius(
      int bombCol, int bombRow, int targetCol, int targetRow) {
    final deltaCol = (targetCol - bombCol).abs();
    final deltaRow = (targetRow - bombRow).abs();
    return deltaCol <= explosionRadius && deltaRow <= explosionRadius;
  }
}

/// 📊 Resultado da ativação da bomba
class BombActivationResult {
  final bool success;
  final String message;
  final int bombsDetonated;
  final int piecesAffected;
  final int chainReactions;

  BombActivationResult._({
    required this.success,
    required this.message,
    this.bombsDetonated = 0,
    this.piecesAffected = 0,
    this.chainReactions = 0,
  });

  factory BombActivationResult.success({
    required int bombsDetonated,
    required int piecesAffected,
    required int chainReactions,
  }) {
    return BombActivationResult._(
      success: true,
      message: "Bomba ativada com sucesso",
      bombsDetonated: bombsDetonated,
      piecesAffected: piecesAffected,
      chainReactions: chainReactions,
    );
  }

  factory BombActivationResult.failed(String reason) {
    return BombActivationResult._(
      success: false,
      message: reason,
    );
  }

  @override
  String toString() {
    return "BombActivationResult(success: $success, bombsDetonated: $bombsDetonated, piecesAffected: $piecesAffected, chainReactions: $chainReactions)";
  }
}

/// ⛓️ Resultado das reações em cadeia
class ChainReactionResult {
  final Set<PetalPiece> allAffectedPieces;
  final int bombsDetonated;
  final int chainReactions;

  ChainReactionResult({
    required this.allAffectedPieces,
    required this.bombsDetonated,
    required this.chainReactions,
  });
}
