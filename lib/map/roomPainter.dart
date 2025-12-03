import 'package:flutter/material.dart';

import 'package:cwscompass/room.dart';
import 'package:cwscompass/map_data.dart';

class RoomPainter extends CustomPainter {
  final MapData mapData;

  RoomPainter(this.mapData);

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
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = room.colour;

    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final room in mapData.rooms) {
      drawRoom(canvas, room);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}