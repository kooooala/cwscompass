import 'package:cwscompass/common/maths.dart' as maths;
import 'package:flutter/material.dart';

import 'package:cwscompass/map_data.dart';

class LabelPainter extends CustomPainter {
  final MapData mapData;
  
  LabelPainter(this.mapData);

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final room in mapData.rooms) {
      final contrast = maths.contrastRatio(room.colour, Colors.black);
      final colour = contrast > 4.5 ? Colors.black : Colors.white;

      textPainter.text = TextSpan(
        text: "${room.subject} room ${room.number}",
        style: TextStyle(
          color: colour,
          fontSize: 1),
      );
      textPainter.layout();

      final offset = Offset(
        room.centroid.x - textPainter.width / 2,
        room.centroid.y - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}