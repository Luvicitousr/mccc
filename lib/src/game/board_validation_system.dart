import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../engine/petal_piece.dart';
import '../engine/level_definition.dart';
import 'package:flame/components.dart'; // Importação necessária para Sprite

/// 🛡️ Sistema de Validação Completa do Tabuleiro Inicial
///
/// Este sistema implementa validação rigorosa para garantir que:
/// 1. Não existam combinações pré-existentes (3+ peças iguais)
/// 2. Pelo menos um movimento válido esteja disponível
/// 3. O tabuleiro seja jogável desde o início
class BoardValidationSystem {
  final LevelDefinition level;

  // Configurações de validação
  static const int maxGenerationAttempts = 100;
  static const int maxValidationChecks = 1000;
  static const int minValidMovesRequired = 1;

  BoardValidationSystem({required this.level});

  /// 🎯 **MÉTODO PRINCIPAL DE VALIDAÇÃO**
  /// Valida completamente um tabuleiro antes do início do jogo
  ///
  /// Retorna:
  /// - true: Tabuleiro válido e pronto para jogar
  /// - false: Tabuleiro inválido (tem combinações ou sem jogadas)
  bool validateInitialBoard(List<PetalPiece> pieces) {
    if (kDebugMode) {
      print(
          "[BOARD_VALIDATION] 🛡️ Iniciando validação completa do tabuleiro inicial");
    }

    try {
      // Validação 1: Verificar se não há combinações pré-existentes
      if (_hasPreExistingMatches(pieces)) {
        if (kDebugMode) {
          print(
              "[BOARD_VALIDATION] ❌ FALHOU: Combinações pré-existentes encontradas");
        }
        return false;
      }

      // Validação 2: Verificar se há pelo menos um movimento válido
      if (!_hasValidMovesAvailable(pieces)) {
        if (kDebugMode) {
          print(
              "[BOARD_VALIDATION] ❌ FALHOU: Nenhum movimento válido disponível");
        }
        return false;
      }

      if (kDebugMode) {
        print(
            "[BOARD_VALIDATION] ✅ SUCESSO: Tabuleiro válido e pronto para jogar");
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("[BOARD_VALIDATION] ❌ ERRO durante validação: $e");
        print("[BOARD_VALIDATION] Stack trace: $stackTrace");
      }
      return false;
    }
  }

  /// 🔍 **DETECÇÃO DE COMBINAÇÕES PRÉ-EXISTENTES**
  /// Verifica se existem sequências de 3+ peças iguais no tabuleiro
  bool _hasPreExistingMatches(List<PetalPiece> pieces) {
    if (kDebugMode) {
      print("[BOARD_VALIDATION] 🔍 Verificando combinações pré-existentes...");
    }

    int matchesFound = 0;

    // Verifica todas as posições do tabuleiro
    for (int row = 0; row < level.height; row++) {
      for (int col = 0; col < level.width; col++) {
        final matches = _findMatchesAt(pieces, col, row);
        if (matches.isNotEmpty) {
          matchesFound++;

          if (kDebugMode) {
            final piece = _pieceAt(pieces, col, row);
            print(
                "[BOARD_VALIDATION] ❌ Match encontrado em ($col, $row): ${piece?.type} - ${matches.length} peças");
          }

          // Retorna imediatamente se encontrar qualquer match
          return true;
        }
      }
    }

    if (kDebugMode) {
      print("[BOARD_VALIDATION] ✅ Nenhuma combinação pré-existente encontrada");
    }

    return false;
  }

  /// 🎯 **VERIFICAÇÃO DE MOVIMENTOS VÁLIDOS**
  /// Verifica se há pelo menos um movimento que resulte em match
  bool _hasValidMovesAvailable(List<PetalPiece> pieces) {
    if (kDebugMode) {
      print(
          "[BOARD_VALIDATION] 🎯 Verificando movimentos válidos disponíveis...");
    }

    int totalChecks = 0;
    int validMovesFound = 0;

    // Verifica todas as posições do tabuleiro
    for (int row = 0; row < level.height; row++) {
      for (int col = 0; col < level.width; col++) {
        final currentPiece = _pieceAt(pieces, col, row);

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

          // Limite de segurança para evitar loops infinitos
          if (totalChecks > maxValidationChecks) {
            if (kDebugMode) {
              print(
                  "[BOARD_VALIDATION] ⚠️ Limite de verificações atingido: $maxValidationChecks");
            }
            break;
          }

          // Verifica se o movimento é válido
          if (_isValidMove(pieces, col, row, adjCol, adjRow)) {
            // Simula o movimento para verificar se cria match
            if (_simulateAndCheckMatch(pieces, col, row, adjCol, adjRow)) {
              validMovesFound++;

              if (kDebugMode && validMovesFound <= 3) {
                print(
                    "[BOARD_VALIDATION] ✅ Movimento válido #$validMovesFound: ($col,$row) -> ($adjCol,$adjRow)");
              }

              // Se encontrou pelo menos um movimento válido, pode parar
              if (validMovesFound >= minValidMovesRequired) {
                if (kDebugMode) {
                  print(
                      "[BOARD_VALIDATION] ✅ Requisito mínimo de movimentos válidos atendido: $validMovesFound");
                }
                return true;
              }
            }
          }
        }
      }
    }

    if (kDebugMode) {
      print("[BOARD_VALIDATION] 📊 Total de verificações: $totalChecks");
      print(
          "[BOARD_VALIDATION] 📊 Movimentos válidos encontrados: $validMovesFound");
    }

    return validMovesFound >= minValidMovesRequired;
  }

  /// 🔍 **ENCONTRA MATCHES EM UMA POSIÇÃO ESPECÍFICA**
  /// Verifica se há sequências de 3+ peças iguais horizontal e verticalmente
  Set<PetalPiece> _findMatchesAt(List<PetalPiece> pieces, int col, int row) {
    final piece = _pieceAt(pieces, col, row);
    if (piece == null || !_canPieceBeMatchedFrom(piece)) {
      return {};
    }

    final currentType = piece.type;
    final foundPieces = <PetalPiece>{};

    // Verifica linha horizontal
    List<PetalPiece> horizontalLine = [piece];

    // Esquerda
    for (int x = col - 1; x >= 0; x--) {
      final p = _pieceAt(pieces, x, row);
      if (p?.type == currentType) {
        horizontalLine.add(p!);
      } else {
        break;
      }
    }

    // Direita
    for (int x = col + 1; x < level.width; x++) {
      final p = _pieceAt(pieces, x, row);
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
      final p = _pieceAt(pieces, col, y);
      if (p?.type == currentType) {
        verticalLine.add(p!);
      } else {
        break;
      }
    }

    // Baixo
    for (int y = row + 1; y < level.height; y++) {
      final p = _pieceAt(pieces, col, y);
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

  /// 🎮 **SIMULA MOVIMENTO E VERIFICA MATCH**
  /// Testa se um movimento específico resultaria em combinação
  bool _simulateAndCheckMatch(
      List<PetalPiece> pieces, int fromCol, int fromRow, int toCol, int toRow) {
    final piece1 = _pieceAt(pieces, fromCol, fromRow);
    final piece2 = _pieceAt(pieces, toCol, toRow);

    if (piece1 == null || piece2 == null) {
      return false;
    }

    // Salva tipos originais
    final originalType1 = piece1.type;
    final originalType2 = piece2.type;

    // Simula a troca
    piece1.type = originalType2;
    piece2.type = originalType1;

    // Verifica se cria match em qualquer uma das posições
    final hasMatch = _findMatchesAt(pieces, fromCol, fromRow).isNotEmpty ||
        _findMatchesAt(pieces, toCol, toRow).isNotEmpty;

    // Restaura tipos originais
    piece1.type = originalType1;
    piece2.type = originalType2;

    return hasMatch;
  }

  /// 🛡️ **MÉTODOS DE VALIDAÇÃO AUXILIARES**

  /// Verifica se uma peça pode ser movida
  bool _canPieceBeMovedFrom(PetalPiece? piece) {
    if (piece == null) return false;

    return piece.type != PetalType.empty &&
        piece.type != PetalType.wall &&
        piece.type != PetalType.bedrock &&
        piece.type != PetalType.caged1 &&
        piece.type != PetalType.caged2;
  }

  /// Verifica se uma peça pode fazer match
  bool _canPieceBeMatchedFrom(PetalPiece piece) {
    return piece.type != PetalType.empty &&
        piece.type != PetalType.wall &&
        piece.type != PetalType.bedrock &&
        piece.type != PetalType.caged1 &&
        piece.type != PetalType.caged2;
  }

  /// Verifica se uma posição é válida no tabuleiro
  bool _isValidPosition(int col, int row) {
    return col >= 0 && col < level.width && row >= 0 && row < level.height;
  }

  /// Verifica se um movimento é válido
  bool _isValidMove(
      List<PetalPiece> pieces, int fromCol, int fromRow, int toCol, int toRow) {
    if (!_isValidPosition(fromCol, fromRow) ||
        !_isValidPosition(toCol, toRow)) {
      return false;
    }

    final fromPiece = _pieceAt(pieces, fromCol, fromRow);
    final toPiece = _pieceAt(pieces, toCol, toRow);

    if (fromPiece == null || toPiece == null) {
      return false;
    }

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

  /// Obtém peça em uma posição específica
  PetalPiece? _pieceAt(List<PetalPiece> pieces, int col, int row) {
    if (!_isValidPosition(col, row)) {
      return null;
    }

    final index = row * level.width + col;
    return index < pieces.length ? pieces[index] : null;
  }
}

/// 🏗️ **GERADOR DE TABULEIRO VÁLIDO**
/// Classe auxiliar para gerar tabuleiros que passem na validação
class ValidBoardGenerator {
  final LevelDefinition level;
  final BoardValidationSystem validator;
  final Map<PetalType, Sprite> spriteMap; // Tipo corrigido para Sprite

  ValidBoardGenerator({
    required this.level,
    required this.spriteMap,
  }) : validator = BoardValidationSystem(level: level);

  /// 🎲 **GERA TABULEIRO VÁLIDO**
  /// Tenta gerar um tabuleiro válido até o limite de tentativas
  Future<List<PetalPiece>?> generateValidBoard({
    required double pieceSize,
    required double offsetX,
    required double offsetY,
  }) async {
    if (kDebugMode) {
      print("[BOARD_GENERATOR] 🎲 Iniciando geração de tabuleiro válido...");
    }

    for (int attempt = 1;
        attempt <= BoardValidationSystem.maxGenerationAttempts;
        attempt++) {
      if (kDebugMode) {
        print(
            "[BOARD_GENERATOR] 🔄 Tentativa #$attempt de ${BoardValidationSystem.maxGenerationAttempts}");
      }

      // Gera um novo tabuleiro
      final pieces = await _generateSingleBoard(pieceSize, offsetX, offsetY);

      // Valida o tabuleiro gerado
      if (validator.validateInitialBoard(pieces)) {
        if (kDebugMode) {
          print(
              "[BOARD_GENERATOR] ✅ Tabuleiro válido gerado na tentativa #$attempt");
        }
        return pieces;
      }

      if (kDebugMode) {
        print("[BOARD_GENERATOR] ❌ Tentativa #$attempt falhou na validação");
      }
    }

    if (kDebugMode) {
      print(
          "[BOARD_GENERATOR] 🚨 FALHA: Não foi possível gerar tabuleiro válido em ${BoardValidationSystem.maxGenerationAttempts} tentativas");
    }

    return null;
  }

  /// 🏗️ **GERA UM ÚNICO TABULEIRO**
  /// Cria um tabuleiro sem matches iniciais
  Future<List<PetalPiece>> _generateSingleBoard(
    double pieceSize,
    double offsetX,
    double offsetY,
  ) async {
    final pieces = <PetalPiece>[];

    for (int j = 0; j < level.height; j++) {
      for (int i = 0; i < level.width; i++) {
        final index = j * level.width + i;
        final position = Vector2(
          i * pieceSize + offsetX,
          j * pieceSize + offsetY,
        );

        PetalType pieceType =
            _determinePieceType(level.layout[index], pieces, i, j);

        pieces.add(
          PetalPiece(
            type: pieceType,
            spriteMap: spriteMap,
            position: position,
            size: Vector2.all(pieceSize),
          ),
        );
      }
    }

    return pieces;
  }

  /// 🎯 **DETERMINA TIPO DA PEÇA**
  /// Escolhe o tipo baseado no layout e evita matches iniciais
  PetalType _determinePieceType(
      dynamic layoutValue, List<PetalPiece> pieces, int i, int j) {
    // Tipos fixos baseados no layout
    if (layoutValue == 0) return PetalType.wall;
    if (layoutValue == 2) return PetalType.caged1;
    if (layoutValue == -1) return PetalType.bedrock;
    if (layoutValue == -2) return PetalType.weed;

    // Para peças normais, evita matches iniciais
    if (layoutValue == 1) {
      return _generatePieceTypeAvoidingMatches(pieces, i, j);
    }

    return PetalType.empty;
  }

  /// 🚫 **GERA TIPO EVITANDO MATCHES**
  /// Escolhe um tipo de peça jogável de forma aleatória. A validação
  /// de combinações será feita posteriormente pelo BoardValidationSystem.
  PetalType _generatePieceTypeAvoidingMatches(
      List<PetalPiece> pieces, int i, int j) {
    final availableTypes = _getAvailableTypes();
    // Simplesmente retorna um tipo aleatório da lista de tipos jogáveis.
    return availableTypes[math.Random().nextInt(availableTypes.length)];
  }

  /// 🎨 **OBTÉM TIPOS DISPONÍVEIS**
  /// Lista de tipos que podem ser usados para peças normais
  List<PetalType> _getAvailableTypes() {
    return [
      PetalType.cherry,
      PetalType.maple,
      PetalType.orchid,
      PetalType.plum,
      PetalType.lily,
      PetalType.peony,
    ];
  }

  /// 📍 **OBTÉM PEÇA EM POSIÇÃO**
  /// Helper para acessar peças durante a geração
  PetalPiece? _getPieceAt(List<PetalPiece> pieces, int i, int j) {
    if (i < 0 || i >= level.width || j < 0 || j >= level.height) {
      return null;
    }

    final index = j * level.width + i;
    return index < pieces.length ? pieces[index] : null;
  }
}
