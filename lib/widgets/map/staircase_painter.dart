import 'package:cwscompass/data/school.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/data/staircase.dart';
import 'package:flutter/material.dart';

import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/data/map_data.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StaircasePainter extends CustomPainter {
  final School school;
  final int floor;
  final double radius;

  StaircasePainter(this.school, this.floor, this.radius);

  void _drawStaircase(Canvas canvas, Staircase staircase, double radius) {
    final landing = staircase.coordinates.firstWhere((c) => c.floor == floor);

    // The staircase is drawn by layering an arrow icon and stairs icon on top of a blue circle
    final circlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = ThemeColours.primary;
    canvas.drawCircle(Offset(landing.point.x, landing.point.y), radius, circlePaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final otherLanding = staircase.coordinates.firstWhere((c) => c.floor != floor);
    final isUp = otherLanding.floor > landing.floor;
    final arrow = isUp ? PhosphorIconsBold.arrowUpRight : PhosphorIconsBold.arrowDownLeft;
    textPainter.text = TextSpan(
      text: String.fromCharCode(arrow.codePoint),
      style: TextStyle(
        fontFamily: arrow.fontFamily,
        fontSize: radius * 0.7,
        color: Colors.white,
        package: arrow.fontPackage
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(landing.point.x - radius * 0.6, landing.point.y));

    final stairs = PhosphorIconsBold.steps;
    textPainter.text = TextSpan(
      text: String.fromCharCode(stairs.codePoint),
      style: TextStyle(
          fontFamily: stairs.fontFamily,
          fontSize: radius,
          color: Colors.white,
          package: stairs.fontPackage
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(landing.point.x - radius * 0.4, landing.point.y + radius * 0.6));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final staircases = school.staircases.where((staircase) => staircase.coordinates.any((c) => c.floor == floor));
    for (var staircase in staircases) {
      _drawStaircase(canvas, staircase, radius);
    }
  }

  @override
  bool shouldRepaint(StaircasePainter old) => old.floor != floor;
}