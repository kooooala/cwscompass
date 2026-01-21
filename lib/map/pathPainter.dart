import 'dart:math';

import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/map/school.dart' as school;
import 'package:flutter/material.dart';

import 'package:cwscompass/map_data.dart';

class PathPainter extends CustomPainter {
  final school.Route route;
  static const double betweenDots = 20;

  final TransformationController transformations;

  PathPainter(this.route, this.transformations) : super(repaint: transformations);

  @override
  void paint(Canvas canvas, Size size) {
    double spillover = 0;
    double scale = transformations.value.getMaxScaleOnAxis();
    if (scale < 10) {
      scale = 10;
    }
    final actualBetweenDots = betweenDots / scale;
    for (var i = 0; i < route.coordinates.length - 1; i++) {
      final point1 = route.coordinates[i].point;
      final point2 = route.coordinates[i + 1].point;

      final magnitude = maths.pythagoras(point1, point2);
      final count = (magnitude + spillover) ~/ actualBetweenDots;

      final angle= atan2(point2.y - point1.y, point2.x - point1.x);

      for (var j = 0; j <= count; j++) {
        final x = spillover * cos(angle) + (point2.x - point1.x) * (actualBetweenDots / magnitude) * j + point1.x;
        final y = spillover * sin(angle) + (point2.y - point1.y) * (actualBetweenDots / magnitude) * j + point1.y;

        // FIXME I have no idea why this is needed
        if (maths.pythagoras(point1, Point(x, y)) > magnitude) {
          break;
        }

        canvas.drawCircle(Offset(x, y), 5 / scale, Paint()..color = Color(0xFF8F4953));
      }

      spillover = actualBetweenDots - ((magnitude - spillover) % actualBetweenDots);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}