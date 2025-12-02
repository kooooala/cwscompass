import 'package:flutter/material.dart';

class Polygon extends CustomPainter {
  final List<Offset> vertices;
  final Color color;

  Polygon(this.vertices, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final path = Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);

    for (final vertex in vertices.sublist(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }

    path.lineTo(vertices[0].dx, vertices[0].dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}