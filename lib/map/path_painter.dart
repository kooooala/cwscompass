import 'dart:math';

import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/map/school.dart' as school;
import 'package:cwscompass/common/theme_colours.dart';
import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final school.Route route;
  final int floor;
  static const double betweenDots = 20;

  final bool drawStart, drawEnd;

  final TransformationController transformations;

  PathPainter({
    required this.route,
    required this.floor,
    required this.transformations,
    this.drawStart = false,
    this.drawEnd = false,
  }) : super(repaint: transformations);

  @override
  void paint(Canvas canvas, Size size) {
    double spillover = 0;
    double scale = transformations.value.getMaxScaleOnAxis();
    //if (scale < 10) {
    //  scale = 10;
    //}
    final actualBetweenDots = betweenDots / scale;

    final path = route.path.coordinates;

    for (var i = 0; i < path.length - 1; i++) {
      final point1 = path[i].point;
      final point2 = path[i + 1].point;

      // Skip over repeat points
      if (point1 == point2) {
        continue;
      }

      final isCurrent = path[i + 1].floor == floor && path[i].floor == floor;
      final colour = isCurrent ? ThemeColours.accent : ThemeColours.accent.withAlpha(64);

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

        canvas.drawCircle(Offset(x, y), 5 / scale, Paint()..color = colour);
      }

      spillover = actualBetweenDots - ((magnitude - spillover) % actualBetweenDots);
    }

    if (drawStart) {
      final startOffset = Offset(path.first.point.x, path.first.point.y);
      final colour = path.first.floor == floor ? ThemeColours.accent : ThemeColours.accent.withAlpha(64);
      canvas.drawCircle(startOffset, 7 / scale, Paint()..color = colour);
      canvas.drawCircle(startOffset, 4 / scale, Paint()..color = Colors.white);
    }

    if (drawEnd) {
      final endOffset = Offset(path.last.point.x, path.last.point.y);
      final colour = path.last.floor == floor ? ThemeColours.accent : ThemeColours.accent.withAlpha(64);
      canvas.drawCircle(endOffset, 7 / scale, Paint()..color = colour);
      canvas.drawCircle(endOffset, 4 / scale, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return route != oldDelegate.route;
  }
}