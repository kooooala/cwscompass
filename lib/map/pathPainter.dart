import 'package:cwscompass/common/maths.dart' as maths;
import 'package:flutter/material.dart';

import 'package:cwscompass/map_data.dart';

class PathPainter extends CustomPainter {
  final MapData mapData;

  PathPainter(this.mapData);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in mapData.paths) {
      for (final (i, vertex) in path.vertices.sublist(0, path.vertices.length - 1).indexed) {
        final v1 = vertex.toPoint(), v2 = path.vertices[i + 1].toPoint();
        canvas.drawLine(Offset(v1.x, v1.y), Offset(v2.x, v2.y), Paint());
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}