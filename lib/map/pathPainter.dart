import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/map/school.dart' as school;
import 'package:flutter/material.dart';

import 'package:cwscompass/map_data.dart';

class PathPainter extends CustomPainter {
  final school.Route route;

  PathPainter(this.route);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < route.coordinates.length - 1; i++) {
      final v1 = route.coordinates[i].toPoint(), v2 = route.coordinates[i + 1].toPoint();
      canvas.drawLine(Offset(v1.x, v1.y), Offset(v2.x, v2.y), Paint()..strokeWidth = 0.1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}