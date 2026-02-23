import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:flutter/material.dart';

class StructurePainter extends CustomPainter {
  final Iterable<Structure> structures;
  final int floor;

  StructurePainter({required this.structures, required this.floor});

  static Path _structureOutline(Structure structure) {
    // Add the vertices of the structure to the path
    final vertices = structure.coordinates.map((c) => c.point).toList();

    final path = Path();

    path.moveTo(vertices[0].x, vertices[0].y);
    for (final vertex in vertices.sublist(1)) {
      path.lineTo(vertex.x, vertex.y);
    }

    return path;
  }

  static void _drawRoom(Canvas canvas, Structure structure) {
    final outline = _structureOutline(structure);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = structure.colour;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05
      ..color = ThemeColours.darkText;

    canvas.drawPath(outline, fill);
    canvas.drawPath(outline, stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final structure in structures) {
      _drawRoom(canvas, structure);
    }
  }

  @override
  bool shouldRepaint(StructurePainter old) => old.floor != floor;
}