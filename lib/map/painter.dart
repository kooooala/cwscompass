import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cwscompass/room.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/map_data.dart';

class Painter extends CustomPainter {
  final MapData mapData;

  Painter(this.mapData);

  static Point<double> projectVertex(Coordinates vertex) {
    final topLeft = Point<double>(-1.79278594, 51.55157938);
    final bottomRight = Point<double>(-1.78508911, 51.54750466);

    final canvasSize = 512;

    final width = bottomRight.x - topLeft.x;
    final height = topLeft.y - bottomRight.y;

    final dx = (vertex.toPoint().x - topLeft.x) / width * canvasSize;
    final dy = ((1 - (vertex.toPoint().y - bottomRight.y) / height) * canvasSize); // with latitude, positive = up

    return Point<double>(dx, dy);
  }

  static Path pathFromRoom(Room room) {
    final vertices = room.vertices.map((vertex) => projectVertex(vertex)).toList();

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