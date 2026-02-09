import 'package:cwscompass/map/school.dart';
import 'package:flutter/material.dart';

class DebugPainter extends CustomPainter {
  final School school;

  DebugPainter(this.school);

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Implement pathfinding across floors
    for (final node in school.floors[0].graph.keys) {
      for (final edge in school.floors[0].graph[node]!) {
        for (int i = 0; i < edge.coordinates.length - 1; i++) {
          final point1 = edge.coordinates[i].point;
          final point2 = edge.coordinates[i + 1].point;
          canvas.drawLine(Offset(point1.x, point1.y), Offset(point2.x, point2.y), Paint()..color = Color(0xFF8F4953));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}