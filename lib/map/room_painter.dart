import 'package:cwscompass/map/school.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:flutter/material.dart';

import 'package:cwscompass/room.dart';
import 'package:cwscompass/map_data.dart';

class RoomPainter extends CustomPainter {
  final School school;
  final int floor;

  RoomPainter(this.school, this.floor);

  static Path roomOutline(Room room) {
    final vertices = room.vertices;

    final path = Path();

    path.moveTo(vertices[0].x, vertices[0].y);
    for (final vertex in vertices.sublist(1)) {
      path.lineTo(vertex.x, vertex.y);
    }

    return path;
  }

  static void drawRoom(Canvas canvas, Room room) {
    final outline = roomOutline(room);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = room.colour;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05
      ..color = ThemeColours.darkText;

    canvas.drawPath(outline, fill);
    canvas.drawPath(outline, stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final room in school.rooms[floor]) {
      drawRoom(canvas, room);
    }
  }

  @override
  bool shouldRepaint(RoomPainter old) => old.floor != floor;
}