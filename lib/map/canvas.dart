import 'package:cwscompass/map/polygon.dart';
import 'package:flutter/material.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.1,
        maxScale: 64,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.8, 1),
              colors: <Color>[
                Color(0xff1f005c),
                Color(0xff5b0060),
                Color(0xff870160),
                Color(0xffac255e),
                Color(0xffca485c),
                Color(0xffe16b5c),
                Color(0xfff39060),
                Color(0xffffb56b),
              ], // Gradient from https://learnui.design/tools/gradient-generator.html
              tileMode: TileMode.mirror,
            ),
          ),
          child: SizedBox(
            width: 512,
            height: 512,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  painter: Polygon(<Offset>[Offset(0, 128), Offset(64, 0), Offset(128, 128)], Colors.yellow),
                ),
                Align(child: Text("Test")),
              ]
            )
          ),
        ),
      )
    );
  }
}