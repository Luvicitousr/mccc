// lib/src/ui/moves_panel.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Um painel que usa um ValueListenableBuilder para se reconstruir
/// automaticamente quando o número de movimentos restantes muda.
class MovesPanel extends StatelessWidget {
  final ValueListenable<int> movesLeft;

  const MovesPanel({super.key, required this.movesLeft});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder é um widget otimizado que escuta
    // o 'movesLeft' e reconstrói apenas esta parte da UI quando o valor muda.
    return ValueListenableBuilder<int>(
      valueListenable: movesLeft,
      builder: (context, value, child) {
        return Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            // ✅ Substituímos o Text por uma Column para empilhar os textos.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize
                  .min, // Faz a coluna ter o tamanho mínimo necessário
              children: [
                // 1. Texto para o título.
                const Text(
                  'Movimentos Restantes',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4), // Pequeno espaço entre os textos.
                // 2. Texto para o número, com maior destaque.
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
