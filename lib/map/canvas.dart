import 'dart:math';
import 'package:cwscompass/widgets/overlays/explore.dart';
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

class MapCanvasController {
  bool focusOnTap;
  bool focusOnRoomSelect;
  final TransformationController transformationController = TransformationController();

  MapCanvasController({this.focusOnTap = false, this.focusOnRoomSelect = false});
}

class MapCanvas extends ConsumerStatefulWidget {
  final double width, height;
  final MapCanvasController controller;

  const MapCanvas({super.key, required this.width, required this.height, required this.controller});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MapCanvasState();
}

class MapCanvasState extends ConsumerState<MapCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  Animation<Matrix4>? focusAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500)
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    //widget.controller.transformationController.dispose();
    super.dispose();
  }

  void onRoomSelect(Room? previous, Room? next) {
    if (next != null) {
      startFocusAnimation(next.centroid, computeScale(next));
    }
  }

  void startFocusAnimation(Point<double> focus, double scale) {
    if (focusAnimation != null) {
      cancelAnimation();
    }

    final x = -focus.x * scale + widget.width / 2;
    final y = -focus.y * scale + widget.height / 2 - 75;

    animationController.reset();
    focusAnimation = Matrix4Tween(
      begin: widget.controller.transformationController.value,
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
    widget.controller.transformationController.value = focusAnimation!.value;
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
        ref.read(selectedRoomProvider.notifier).set(room);
        if (widget.controller.focusOnTap) {
          startFocusAnimation(room.centroid, computeScale(room));
        }
        return;
      }
    }
    // Tapped on blank space
    ref.read(selectedRoomProvider.notifier).set(null);
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(mapDataProvider);

    if (widget.controller.focusOnRoomSelect) {
      ref.listen<Room?>(selectedRoomProvider, onRoomSelect);
    }

    return Center(
      child: school.when(
        data: (data) {
          final start = data.school.closestNode(Coordinates(51.5490108,-1.7894657));
          final dest = data.school.closestNode(Coordinates(51.54907, -1.78829));

          final route = data.school.shortestRoute(start, dest);

          return InteractiveViewer(
            transformationController: widget.controller.transformationController,
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
                        child: CustomPaint(painter: PathPainter(route, widget.controller.transformationController)),
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