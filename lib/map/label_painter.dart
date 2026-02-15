import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/data/structures/building.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/data/structures/toilet.dart';
import 'package:cwscompass/map/school.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LabelPainter extends CustomPainter {
  final Iterable<Structure> structures;
  final int floor;
  
  LabelPainter(this.structures, this.floor);

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final structure in structures) {
      String label;
      TextStyle style;

      if (structure is Room) {
        label = structure.name.capitalise();
        final contrast = maths.contrastRatio(structure.colour, ThemeColours.darkText);
        final colour = contrast > 4.5 ? ThemeColours.darkText : ThemeColours.lightText;

        style = GoogleFonts.nunito(
          color: colour,
          fontWeight: FontWeight.w500,
          fontSize: 1.0,
        );
      } else if (structure is Toilet) {
        final icon = Toilet.toiletTypeIcon(structure.type);
        label = String.fromCharCode(icon.codePoint);

        style = TextStyle(
          color: Toilet.toiletTypeColour(structure.type),
          fontFamily: icon.fontFamily,
          fontSize: 1.0,
          package: icon.fontPackage
        );
      } else {
        continue;
      }

      textPainter.text = TextSpan(
        text: label,
        style: style
      );
      textPainter.layout();

      final offset = Offset(
        structure.centroid.x - textPainter.width / 2,
        structure.centroid.y - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(LabelPainter old) => old.floor != floor;
}