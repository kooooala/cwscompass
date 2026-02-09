import 'package:cwscompass/map/school.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:flutter/material.dart';

import 'package:cwscompass/room.dart';
import 'package:cwscompass/map_data.dart';

class RoomPainter extends CustomPainter {
  final School school;
  final int floor;

  RoomPainter(this.school, this.floor);

  static Path pathFromRoom(Room room) {
    final vertices = room.vertices;

    final path = Path();

    path.moveTo(vertices[0].x, vertices[0].y);
    for (final vertex in vertices.sublist(1)) {
      path.lineTo(vertex.x, vertex.y);
    }

    return path;
  }

  static void drawRoom(Canvas canvas, Room room) {
    final path = pathFromRoom(room);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = room.colour;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05
      ..color = ThemeColours.darkText;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final room in school.floors[floor].rooms) {
      drawRoom(canvas, room);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}