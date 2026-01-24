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

class MapCanvas extends ConsumerWidget {
  final double width, height;
  final void Function(Room room) onRoomTap;

  const MapCanvas({super.key, required this.width, required this.height, required this.onRoomTap});

  void onTapUp(TapUpDetails details, School school) {
    for (final room in school.rooms) {
      if (room.intersects(Point(details.localPosition.dx, details.localPosition.dy))) {
        onRoomTap(room);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(mapDataProvider);
    final transformations = TransformationController();

    return Center(
      child: school.when(
        data: (data) {
          final start = data.school.closestNode(Coordinates(51.5490108,-1.7894657));
          final dest = data.school.closestNode(Coordinates(51.54907, -1.78829));

          final route = data.school.shortestRoute(start, dest);

          return InteractiveViewer(
            transformationController: transformations,
            minScale: 1,
            maxScale: 64,
            child: GestureDetector(
              onTapUp: (details) => onTapUp(details, data.school),
              child: Container(
                color: Colors.white,
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
                      RepaintBoundary(
                        child: CustomPaint(painter: PathPainter(route, transformations)),
                      ),
                      Marker(2, data.school),
                    ]
                  )
                ),
              )
            ),
          );
        },
        loading: () => CircularProgressIndicator(),
        error: (err, stack) => Text("Oops: $err"),
      ),
    );
  }
}