import 'package:cwscompass/data/school.dart';
import 'package:flutter/material.dart';

class DebugPainter extends CustomPainter {
  final School school;
  final int floor;

  DebugPainter(this.school, this.floor);

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = school.graph.simplified.keys.where((c) => c.floor == floor);

    for (final node in nodes) {
      // Draw a circle at every junction
      canvas.drawCircle(Offset(node.point.x, node.point.y), 1, Paint()..color = Colors.yellow);
      for (final edge in school.graph.simplified[node]!) {
        for (int i = 0; i < edge.coordinates.length - 1; i++) {
          final point1 = edge.coordinates[i].point;
          final point2 = edge.coordinates[i + 1].point;
          // Draw a line between the current and next node
          canvas.drawLine(Offset(point1.x, point1.y), Offset(point2.x, point2.y), Paint()..color = Color(0xFF8F4953));
        }
      }
    }
  }

  @override
  bool shouldRepaint(DebugPainter old) => old.floor != floor;
}