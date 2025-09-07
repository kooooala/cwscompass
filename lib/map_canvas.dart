import 'package:flutter/material.dart';

class MapCanvas extends CustomPainter {
  MapCanvas(this.rect, this.color);

  final Rect rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(rect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant MapCanvas oldDelegate) {
    return oldDelegate.color != color;
  }
}