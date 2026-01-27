import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vectors;

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

class MapCanvas extends ConsumerStatefulWidget {
  final double width, height;
  final bool focusOnTap;

  final void Function(Room room) onRoomTap;
  final void Function() onBlankTap;

  const MapCanvas({super.key, required this.width, required this.height, required this.onRoomTap, required this.onBlankTap, this.focusOnTap = false});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MapCanvasState();
}

class MapCanvasState extends ConsumerState<MapCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  final TransformationController transformationController = TransformationController();
  Animation<Matrix4>? focusAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800)
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    transformationController.dispose();
    super.dispose();
  }

  void startFocusAnimation(Point<double> focus, double scale) {
    if (focusAnimation != null) {
      cancelAnimation();
    }

    final x = -focus.x * scale + widget.width / 2;
    final y = -focus.y * scale + widget.height / 2 - 75;

    animationController.reset();
    focusAnimation = Matrix4Tween(
      begin: transformationController.value,
      end: Matrix4.compose(
        vectors.Vector3(x, y, 0),
        vectors.Quaternion.identity(),
        vectors.Vector3.all(scale)
      )
    ).animate(CurvedAnimation(
      parent: animationController, 
      curve: Curves.easeInOutSine
    ));
    focusAnimation!.addListener(onAnimationUpdate);
    animationController.forward();
  }

  void onAnimationUpdate() {
    transformationController.value = focusAnimation!.value;
    if (!animationController.isAnimating) {
      cancelAnimation();
    }
  }

  void cancelAnimation() {
    animationController.stop();
    focusAnimation!.removeListener(onAnimationUpdate);
    focusAnimation = null;
    animationController.reset();
  }

  double computeScale(Room room) {
    final topLeft = room.boundingBox.topLeft, bottomRight = room.boundingBox.bottomRight;
    
    final xScale = widget.width / (bottomRight.x - topLeft.x);
    final yScale = widget.height / (bottomRight.y - topLeft.y);
    
    final scale = xScale > yScale ? yScale : xScale;
    return scale * 0.5;
  }

  void onTapUp(TapUpDetails details, School school) {
    for (final room in school.rooms) {
      if (room.intersects(Point(details.localPosition.dx, details.localPosition.dy))) {
        widget.onRoomTap(room);
        if (widget.focusOnTap) {
          startFocusAnimation(room.centroid, computeScale(room));
        }
        return;
      }
    }
    widget.onBlankTap();
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(mapDataProvider);

    return Center(
      child: school.when(
        data: (data) {
          final start = data.school.closestNode(Coordinates(51.5490108,-1.7894657));
          final dest = data.school.closestNode(Coordinates(51.54907, -1.78829));

          final route = data.school.shortestRoute(start, dest);

          return InteractiveViewer(
            transformationController: transformationController,
            onInteractionStart: (_) {
              if (animationController.status == AnimationStatus.forward) {
                cancelAnimation();
              }
            },
            minScale: 1,
            maxScale: 64,
            child: GestureDetector(
              onTapUp: (details) => onTapUp(details, data.school),
              child: Container(
                color: Colors.white,
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: Stack(
                    children: <Widget>[
                      RepaintBoundary(
                        child: CustomPaint(painter: RoomPainter(data.school)),
                      ),
                      RepaintBoundary(
                        child: CustomPaint(painter: LabelPainter(data.school)),
                      ),
                      RepaintBoundary(
                        child: CustomPaint(painter: PathPainter(route, transformationController)),
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