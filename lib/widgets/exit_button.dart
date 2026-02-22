import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/widgets/pages/explore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExitButton extends StatelessWidget {
  const ExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Return to home page
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      child: PhysicalModel(
        color: ThemeColours.primary,
        shape: BoxShape.circle,
        elevation: 4.0,
        child: Padding(
          padding: EdgeInsetsGeometry.all(12.0),
          child: Icon(
            PhosphorIconsBold.x,
            color: Colors.white,
            size: 24.0,
          ),
        ),
      ),
    );
  }
}