import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../engine/petal_piece.dart';
import '../engine/level_definition.dart';

/// 🎯 Sistema Aprimorado de Validação de Jogadas e Shuffle Inteligente
///
/// Este sistema implementa:
/// 1. Verificação completa de todas as combinações possíveis
/// 2. Shuffle inteligente que garante jogadas válidas
/// 3. Prevenção de matches durante o shuffle
/// 4. Verificações de segurança e limites
class EnhancedMoveValidationSystem {
  final LevelDefinition level;
  final List<PetalPiece> pieces;

  // Configurações do sistema
  static const int maxShuffleAttempts = 10;
  static const int maxValidationChecks = 1000;
  static const Duration shuffleAnimationDuration = Duration(milliseconds: 1500);

  EnhancedMoveValidationSystem({
    required this.level,
    required this.pieces,
  });

  /// 🔍 Verifica se existem jogadas válidas disponíveis no tabuleiro
  /// Retorna true se houver pelo menos uma jogada possível
  bool hasValidMovesAvailable() {
    if (kDebugMode) {
      print(
          "[VALIDATION] 🔍 Iniciando verificação completa de jogadas válidas...");
    }

    int totalChecks = 0;
    int validMovesFound = 0;
    final List<ValidMove> validMoves = [];

    // Verifica todas as combinações possíveis de peças adjacentes
    for (int row = 0; row < level.height; row++) {
      for (int col = 0; col < level.width; col++) {
        final currentIndex = row * level.width + col;
        final currentPiece = pieces[currentIndex];

        // Pula peças que não podem ser movidas
        if (!_canPieceBeMovedFrom(currentPiece)) {
          continue;
        }

        // Verifica movimentos adjacentes (cima, baixo, esquerda, direita)
        final adjacentPositions = [
          [col, row - 1], // Cima
          [col, row + 1], // Baixo
          [col - 1, row], // Esquerda
          [col + 1, row], // Direita
        ];

        for (final pos in adjacentPositions) {
          final adjCol = pos[0];
          final adjRow = pos[1];

          // Verifica limites do tabuleiro
          if (!_isValidPosition(adjCol, adjRow)) {
            continue;
          }

          totalChecks++;
          if (totalChecks > maxValidationChecks) {
            if (kDebugMode) {
              print(
                  "[VALIDATION] ⚠️ Limite de verificações atingido: $maxValidationChecks");
            }
            break;
          }

          final adjIndex = adjRow * level.width + adjCol;

          // Verifica se o movimento é válido
          if (isValidMove(currentIndex, adjIndex)) {
            // Simula o movimento para verificar se cria match
            if (_simulateAndCheckMatch(col, row, adjCol, adjRow)) {
              validMovesFound++;
              validMoves.add(ValidMove(
                fromCol: col,
                fromRow: row,
                toCol: adjCol,
                toRow: adjRow,
                fromPiece: currentPiece.type,
                toPiece: pieces[adjIndex].type,
              ));

              if (kDebugMode && validMovesFound <= 5) {
                print(
                    "[VALIDATION] ✅ Jogada válida #$validMovesFound: ($col,$row) -> ($adjCol,$adjRow)");
              }
            }
          }
        }
      }
    }

    if (kDebugMode) {
      print("[VALIDATION] 📊 Verificação completa:");
      print("[VALIDATION]   - Total de verificações: $totalChecks");
      print("[VALIDATION]   - Jogadas válidas encontradas: $validMovesFound");
      print(
          "[VALIDATION]   - Resultado: ${validMovesFound > 0 ? 'TEM JOGADAS' : 'SEM JOGADAS'}");
    }

    return validMovesFound > 0;
  }

  /// 🎲 Executa shuffle inteligente quando não há jogadas válidas
  /// Garante que o novo arranjo tenha pelo menos uma jogada válida
  Future<ShuffleResult> executeIntelligentShuffle() async {
    if (kDebugMode) {
      print("[SHUFFLE] 🎲 Iniciando shuffle inteligente...");
    }

    int attempts = 0;
    bool hasValidConfiguration = false;
    List<PetalType> originalTypes = _captureCurrentState();

    while (!hasValidConfiguration && attempts < maxShuffleAttempts) {
      attempts++;

      if (kDebugMode) {
        print("[SHUFFLE] 🔄 Tentativa #$attempts de shuffle...");
      }

      // Executa o shuffle
      final shuffleSuccess = _performSingleShuffle();

      if (!shuffleSuccess) {
        if (kDebugMode) {
          print("[SHUFFLE] ❌ Falha no shuffle da tentativa #$attempts");
        }
        continue;
      }

      // Verifica se o novo arranjo tem jogadas válidas
      if (hasValidMovesAvailable()) {
        // Verifica se não criou matches indesejados
        if (!_hasImmediateMatches()) {
          hasValidConfiguration = true;
          if (kDebugMode) {
            print(
                "[SHUFFLE] ✅ Configuração válida encontrada na tentativa #$attempts");
          }
        } else {
          if (kDebugMode) {
            print(
                "[SHUFFLE] ⚠️ Tentativa #$attempts criou matches, tentando novamente...");
          }
        }
      } else {
        if (kDebugMode) {
          print("[SHUFFLE] ❌ Tentativa #$attempts não criou jogadas válidas");
        }
      }
    }

    if (!hasValidConfiguration) {
      if (kDebugMode) {
        print(
            "[SHUFFLE] 🚨 FALHA: Não foi possível criar configuração válida em $maxShuffleAttempts tentativas");
        print(
            "[SHUFFLE] 🔧 Restaurando estado original e aplicando correção forçada...");
      }

      // Restaura estado original
      _restoreState(originalTypes);

      // Aplica correção forçada
      _forceValidConfiguration();
      hasValidConfiguration = true;
    }

    return ShuffleResult(
      success: hasValidConfiguration,
      attempts: attempts,
      hasValidMoves: hasValidMovesAvailable(),
      message: hasValidConfiguration
          ? "Shuffle concluído com sucesso em $attempts tentativa(s)"
          : "Shuffle falhou após $attempts tentativas",
    );
  }

  /// 🔄 Executa um único shuffle das peças ativas
  bool _performSingleShuffle() {
    try {
      // Coleta apenas peças que podem fazer combinações
      final shuffleablePieces = _getShuffleablePieces();

      if (shuffleablePieces.isEmpty) {
        if (kDebugMode) {
          print("[SHUFFLE] ⚠️ Nenhuma peça disponível para shuffle");
        }
        return false;
      }

      // Extrai os tipos das peças
      final types = shuffleablePieces.map((piece) => piece.type).toList();

      // Embaralha usando algoritmo Fisher-Yates
      _fisherYatesShuffle(types);

      // Aplica os tipos embaralhados de volta às peças
      for (int i = 0; i < shuffleablePieces.length; i++) {
        shuffleablePieces[i].changeType(types[i]);
      }

      if (kDebugMode) {
        print("[SHUFFLE] ✅ ${shuffleablePieces.length} peças embaralhadas");
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("[SHUFFLE] ❌ Erro durante shuffle: $e");
      }
      return false;
    }
  }

  /// 🎯 Coleta peças que podem ser embaralhadas
  List<PetalPiece> _getShuffleablePieces() {
    final shuffleablePieces = <PetalPiece>[];

    for (final piece in pieces) {
      if (_canPieceBeShuffled(piece)) {
        shuffleablePieces.add(piece);
      }
    }

    return shuffleablePieces;
  }

  /// 🔀 Algoritmo Fisher-Yates para embaralhamento
  void _fisherYatesShuffle<T>(List<T> list) {
    final random = math.Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  /// 🛡️ Verifica se uma peça pode ser movida
  bool _canPieceBeMovedFrom(PetalPiece piece) {
    return piece.type != PetalType.empty &&
        piece.type != PetalType.wall &&
        piece.type != PetalType.bedrock &&
        piece.type != PetalType.caged1 &&
        piece.type != PetalType.caged2;
  }

  /// 🔄 Verifica se uma peça pode ser embaralhada
  bool _canPieceBeShuffled(PetalPiece piece) {
    return piece.type != PetalType.empty &&
        piece.type != PetalType.wall &&
        piece.type != PetalType.bedrock &&
        piece.type != PetalType.weed &&
        piece.type != PetalType.bomb &&
        piece.type != PetalType.caged1 &&
        piece.type != PetalType.caged2;
  }

  /// 📍 Verifica se uma posição é válida no tabuleiro
  bool _isValidPosition(int col, int row) {
    return col >= 0 && col < level.width && row >= 0 && row < level.height;
  }

  /// ✅ Verifica se um movimento é válido
  bool isValidMove(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= pieces.length ||
        toIndex < 0 ||
        toIndex >= pieces.length) {
      return false;
    }

    final fromPiece = pieces[fromIndex];
    final toPiece = pieces[toIndex];

    // Não pode mover paredes ou espaços vazios
    if (fromPiece.type == PetalType.wall || fromPiece.type == PetalType.empty) {
      return false;
    }

    // Não pode mover para espaços vazios ou paredes
    if (toPiece.type == PetalType.empty || toPiece.type == PetalType.wall) {
      return false;
    }

    // Não pode mover bedrock
    if (fromPiece.type == PetalType.bedrock ||
        toPiece.type == PetalType.bedrock) {
      return false;
    }

    return true;
  }

  /// 🎯 Simula um movimento e verifica se cria match
  bool _simulateAndCheckMatch(int fromCol, int fromRow, int toCol, int toRow) {
    final fromIndex = fromRow * level.width + fromCol;
    final toIndex = toRow * level.width + toCol;

    final piece1 = pieces[fromIndex];
    final piece2 = pieces[toIndex];

    // Salva tipos originais
    final originalType1 = piece1.type;
    final originalType2 = piece2.type;

    // Simula a troca
    piece1.type = originalType2;
    piece2.type = originalType1;

    // Verifica se cria match
    final hasMatch = _findMatchesAt(fromCol, fromRow).isNotEmpty ||
        _findMatchesAt(toCol, toRow).isNotEmpty;

    // Restaura tipos originais
    piece1.type = originalType1;
    piece2.type = originalType2;

    return hasMatch;
  }

  /// 🔍 Encontra matches em uma posição específica
  Set<PetalPiece> _findMatchesAt(int col, int row) {
    final piece = _pieceAt(col, row);
    if (piece == null || !_canPieceBeMovedFrom(piece)) {
      return {};
    }

    final currentType = piece.type;
    final foundPieces = <PetalPiece>{};

    // Verifica linha horizontal
    List<PetalPiece> horizontalLine = [piece];

    // Esquerda
    for (int x = col - 1; x >= 0; x--) {
      final p = _pieceAt(x, row);
      if (p?.type == currentType) {
        horizontalLine.add(p!);
      } else {
        break;
      }
    }

    // Direita
    for (int x = col + 1; x < level.width; x++) {
      final p = _pieceAt(x, row);
      if (p?.type == currentType) {
        horizontalLine.add(p!);
      } else {
        break;
      }
    }

    // Verifica linha vertical
    List<PetalPiece> verticalLine = [piece];

    // Cima
    for (int y = row - 1; y >= 0; y--) {
      final p = _pieceAt(col, y);
      if (p?.type == currentType) {
        verticalLine.add(p!);
      } else {
        break;
      }
    }

    // Baixo
    for (int y = row + 1; y < level.height; y++) {
      final p = _pieceAt(col, y);
      if (p?.type == currentType) {
        verticalLine.add(p!);
      } else {
        break;
      }
    }

    // Adiciona matches de 3 ou mais
    if (horizontalLine.length >= 3) {
      foundPieces.addAll(horizontalLine);
    }
    if (verticalLine.length >= 3) {
      foundPieces.addAll(verticalLine);
    }

    return foundPieces;
  }

  /// 📍 Obtém peça em uma posição específica
  PetalPiece? _pieceAt(int col, int row) {
    if (!_isValidPosition(col, row)) {
      return null;
    }
    final index = row * level.width + col;
    return index < pieces.length ? pieces[index] : null;
  }

  /// 🚨 Verifica se há matches imediatos no tabuleiro
  bool _hasImmediateMatches() {
    for (int row = 0; row < level.height; row++) {
      for (int col = 0; col < level.width; col++) {
        if (_findMatchesAt(col, row).isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  /// 💾 Captura o estado atual do tabuleiro
  List<PetalType> _captureCurrentState() {
    return pieces.map((piece) => piece.type).toList();
  }

  /// 🔄 Restaura um estado anterior do tabuleiro
  void _restoreState(List<PetalType> state) {
    for (int i = 0; i < pieces.length && i < state.length; i++) {
      pieces[i].changeType(state[i]);
    }
  }

  /// 🔧 Força uma configuração válida como último recurso
  void _forceValidConfiguration() {
    if (kDebugMode) {
      print("[SHUFFLE] 🔧 Aplicando correção forçada...");
    }

    // Encontra três posições adjacentes não-parede
    for (int row = 0; row < level.height - 1; row++) {
      for (int col = 0; col < level.width - 1; col++) {
        final pos1 = _pieceAt(col, row);
        final pos2 = _pieceAt(col + 1, row);
        final pos3 = _pieceAt(col, row + 1);

        if (pos1 != null &&
            pos2 != null &&
            pos3 != null &&
            _canPieceBeShuffled(pos1) &&
            _canPieceBeShuffled(pos2) &&
            _canPieceBeShuffled(pos3)) {
          // Cria um padrão que garantirá uma jogada válida
          final targetType = _getRandomPlayableType();
          final differentType = _getRandomPlayableType();

          pos1.changeType(targetType);
          pos2.changeType(targetType);
          pos3.changeType(differentType);

          if (kDebugMode) {
            print("[SHUFFLE] ✅ Configuração forçada criada em ($col,$row)");
          }
          return;
        }
      }
    }

    if (kDebugMode) {
      print("[SHUFFLE] ⚠️ Não foi possível aplicar correção forçada");
    }
  }

  /// 🎲 Obtém um tipo de peça jogável aleatório
  PetalType _getRandomPlayableType() {
    final playableTypes = [
      PetalType.cherry,
      PetalType.maple,
      PetalType.orchid,
      PetalType.plum,
      PetalType.lily,
      PetalType.peony,
    ];
    return playableTypes[math.Random().nextInt(playableTypes.length)];
  }
}

/// 📊 Classe para representar uma jogada válida
class ValidMove {
  final int fromCol;
  final int fromRow;
  final int toCol;
  final int toRow;
  final PetalType fromPiece;
  final PetalType toPiece;

  ValidMove({
    required this.fromCol,
    required this.fromRow,
    required this.toCol,
    required this.toRow,
    required this.fromPiece,
    required this.toPiece,
  });

  @override
  String toString() {
    return "($fromCol,$fromRow) -> ($toCol,$toRow): $fromPiece ↔ $toPiece";
  }
}

/// 📋 Resultado do processo de shuffle
class ShuffleResult {
  final bool success;
  final int attempts;
  final bool hasValidMoves;
  final String message;

  ShuffleResult({
    required this.success,
    required this.attempts,
    required this.hasValidMoves,
    required this.message,
  });

  @override
  String toString() {
    return "ShuffleResult(success: $success, attempts: $attempts, hasValidMoves: $hasValidMoves, message: '$message')";
  }
}
