// lib/src/ui/objectives_panel.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../engine/petal_piece.dart'; // Precisamos do enum PetalType

class ObjectivesPanel extends StatelessWidget {
  final ValueListenable<Map<PetalType, int>> objectives;

  const ObjectivesPanel({
    super.key,
    required this.objectives,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<PetalType, int>>(
      valueListenable: objectives,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: value.entries.map((entry) {
                // Para cada objetivo, criamos um ícone e um contador.
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/tiles/${entry.key.name}_petal.png',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}