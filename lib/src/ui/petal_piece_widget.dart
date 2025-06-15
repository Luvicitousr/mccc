// lib/src/ui/petal_piece_widget.dart
import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';
import 'package:flame/widgets.dart';
import '../engine/petal_piece.dart';

class PetalPreviewWidget extends StatefulWidget {
  final PetalType type;
  final double size;

  const PetalPreviewWidget({
    Key? key,
    required this.type,
    this.size = 64.0,
  }) : super(key: key);

  @override
  _PetalPreviewWidgetState createState() => _PetalPreviewWidgetState();
}

class _PetalPreviewWidgetState extends State<PetalPreviewWidget> {
  Sprite? _sprite;

  @override
  void initState() {
    super.initState();
    _loadSprite();
  }

  @override
  void didUpdateWidget(PetalPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type) {
      _loadSprite();
    }
  }

  Future<void> _loadSprite() async {
    if (widget.type == PetalType.empty) {
      if (mounted) setState(() => _sprite = null);
      return;
    }
    
    // ✅ CORREÇÃO: Acessa o mapa estático público diretamente,
    // em vez de chamar o método que foi removido.
    final path = PetalPiece.petalSprites[widget.type] ?? 'tiles/empty.png';
    final loadedSprite = await Sprite.load(path);
    
    if (mounted) {
      setState(() {
        _sprite = loadedSprite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _sprite == null
          ? Container(color: Colors.black12.withOpacity(0.1)) // Placeholder
          : SpriteWidget(sprite: _sprite!),
    );
  }
}