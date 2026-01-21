import 'dart:math';

import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/labelPainter.dart';
import 'package:cwscompass/map/marker.dart';
import 'package:cwscompass/map/pathPainter.dart';
import 'package:cwscompass/map/roomPainter.dart';
import 'package:cwscompass/map/school.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transformationProvider = Provider((ref) => TransformationController());

class MapCanvas extends ConsumerWidget {
  final double width, height;
  final void Function(Room room) onRoomTap;

  const MapCanvas({super.key, required this.width, required this.height, required this.onRoomTap});

  void onTapUp(TapUpDetails details, School school) {
    for (final room in school.rooms) {
      if (room.pointIntersects(Point(details.localPosition.dx, details.localPosition.dy))) {
        onRoomTap(room);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.read(mapDataProvider);
    final transformations = ref.read(transformationProvider);

    return Center(
      child: school.when(
        data: (data) =>
            InteractiveViewer(
              transformationController: transformations,
              minScale: 1,
              maxScale: 64,
              child: GestureDetector(
                onTapUp: (details) => onTapUp(details, data.school),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment(0.8, 1),
                      colors: <Color>[
                        Color(0xfff9f9f9),
                        Color(0xffd4dad6),
                        Color(0xffafbbb6),
                        Color(0xff8b9d9b),
                        Color(0xff698083),
                        Color(0xff49636f),
                        Color(0xff2c475c),
                        Color(0xff142b4e),
                      ], // Gradient from https://learnui.design/tools/gradient-generator.html
                      tileMode: TileMode.mirror,
                    ),
                  ),
                  child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: <Widget>[
                          RepaintBoundary(
                            child: CustomPaint(painter: RoomPainter(data.school)),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(painter: LabelPainter(data.school)),
                          ),
                          //RepaintBoundary(
                          //  child: CustomPaint(painter: PathPainter(data)),
                          //),
                          Marker(2, data.school),
                        ]
                      )
                  ),
                )
              ),
            ),
        loading: () => CircularProgressIndicator(),
        error: (err, stack) => Text("Oops: $err"),
      ),
    );
  }
}