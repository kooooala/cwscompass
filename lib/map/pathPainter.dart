import 'dart:math';

import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/map/school.dart' as school;
import 'package:cwscompass/theme_colours.dart';
import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final school.Route route;
  static const double betweenDots = 20;

  final TransformationController transformations;

  PathPainter(this.route, this.transformations) : super(repaint: transformations);

  @override
  void paint(Canvas canvas, Size size) {
    double spillover = 0;
    double scale = transformations.value.getMaxScaleOnAxis();
    //if (scale < 10) {
    //  scale = 10;
    //}
    final actualBetweenDots = betweenDots / scale;
    for (var i = 0; i < route.path.coordinates.length - 1; i++) {
      final point1 = route.path.coordinates[i].point;
      final point2 = route.path.coordinates[i + 1].point;

      // Skip over repeat points
      if (point1 == point2) {
        continue;
      }

      final magnitude = maths.pythagoras(point1, point2);
      final count = (magnitude + spillover) ~/ actualBetweenDots;

      final angle = atan2(point2.y - point1.y, point2.x - point1.x);

      for (var j = 0; j <= count; j++) {
        final x = spillover * cos(angle) + (point2.x - point1.x) * (actualBetweenDots / magnitude) * j + point1.x;
        final y = spillover * sin(angle) + (point2.y - point1.y) * (actualBetweenDots / magnitude) * j + point1.y;

        // FIXME I have no idea why this is needed
        if (maths.pythagoras(point1, Point(x, y)) > magnitude) {
          break;
        }

        canvas.drawCircle(Offset(x, y), 5 / scale, Paint()..color = ThemeColours.accent);
      }

      spillover = actualBetweenDots - ((magnitude - spillover) % actualBetweenDots);
    }

    final startOffset = Offset(route.start.point.x, route.start.point.y);
    canvas.drawCircle(startOffset, 7 / scale, Paint()..color = ThemeColours.accent);
    canvas.drawCircle(startOffset, 4 / scale, Paint()..color = Colors.white);

    final endOffset = Offset(route.end.point.x, route.end.point.y);
    canvas.drawCircle(endOffset, 7 / scale, Paint()..color = ThemeColours.accent);
    canvas.drawCircle(endOffset, 4 / scale, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return route != oldDelegate.route;
  }
}