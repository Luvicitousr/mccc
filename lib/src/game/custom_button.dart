// lib/src/game/custom_button.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class CustomButton extends PositionComponent with TapCallbacks {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  CustomButton({
    required this.text,
    required this.onPressed,
    required this.color,
    this.textColor = Colors.white,
    required super.position,
    required super.size,
    super.anchor,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Cria a aparência do botão (o retângulo de fundo)
    final shape = RectangleComponent(size: size, paint: Paint()..color = color);

    // 2. Cria o texto do botão
    final style = TextStyle(
      fontSize: size.y * 0.5, // 50% da altura do botão
      color: textColor,
      fontWeight: FontWeight.bold,
    );
    final textElement = TextComponent(
      text: text,
      textRenderer: TextPaint(style: style),
      anchor: Anchor.center,
      position: size / 2.0, // Centraliza o texto no botão
    );

    // 3. Adiciona a forma e o texto como filhos deste componente
    await add(shape);
    await add(textElement);
  }

  @override
  void onTapUp(TapUpEvent event) {
    // 4. Executa a ação quando o botão é pressionado
    onPressed();
  }
}
