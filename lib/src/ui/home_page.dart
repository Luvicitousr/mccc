// lib/src/ui/home_page.dart
import 'package:flame/flame.dart';
import 'package:flame/game.dart'; // <-- Adicione esta linha.
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagem de fundo
          Image.asset(
            'assets/images/home_page.gif', // Reutilizando a imagem de fundo
            fit: BoxFit.cover,
          ),
          // 2. Conteúdo centralizado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3. Título do Jogo
                const Text(
                  'Garden of Petals',
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // 4. Botão de Jogar
                ElevatedButton(
                  onPressed: () {
                    // ✅ AÇÃO CORRIGIDA: Usa o Navigator padrão do Flutter.
                    Navigator.of(context).pushNamed('/play');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('Jogar'),
                ),
                // (Você pode adicionar mais botões aqui para outros níveis no futuro)
              ],
            ),
          ),
        ],
      ),
    );
  }
}