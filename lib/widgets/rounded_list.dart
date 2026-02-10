import 'package:cwscompass/common/theme_colours.dart';
import 'package:flutter/material.dart';

class RoundedList extends StatelessWidget {
  final List<Widget> children;
  final double radius;

  const RoundedList({super.key, required this.children, this.radius = 16.0});

  @override
  Widget build(BuildContext context) {
    final childrenWithDividers = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      childrenWithDividers.add(children[i]);

      // Add a divider if the current element is not the last
      if (i != children.length - 1) {
        childrenWithDividers.add(Divider(thickness: 1.0, color: ThemeColours.divider, height: 0,));
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        children: childrenWithDividers,
      )
    );
  }
}