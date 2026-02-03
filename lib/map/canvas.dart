import 'dart:math';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/map/debugPainter.dart';
import 'package:cwscompass/polygon.dart';
import 'package:cwscompass/widgets/overlays/explore.dart';
import 'package:vector_math/vector_math_64.dart' as vectors;

import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/map/labelPainter.dart';
import 'package:cwscompass/map/marker.dart';
import 'package:cwscompass/map/pathPainter.dart';
import 'package:cwscompass/map/roomPainter.dart';
import 'package:cwscompass/map/school.dart' as school;
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transformationControllerProvider = Provider((ref) {
  return TransformationController();
});

enum ZoomFocus {
  centroid,
  average
}

class MapCanvasController {
  bool focusOnTap;
  bool focusOnRoomSelect;
  bool roomSelectable;
  bool showPath;
  bool zoomToPath;
  ValueNotifier<(school.Route, Coordinates)?> path = ValueNotifier(null);
  final TransformationController transformationController;
  final ValueNotifier<(Polygon, ZoomFocus)?> focusRequest = ValueNotifier(null);

  MapCanvasController({
    this.focusOnTap = false,
    this.focusOnRoomSelect = false,
    this.roomSelectable = false,
    this.showPath = false,
    this.zoomToPath = false,
    required this.transformationController
  });

  void focus(Polygon polygon, ZoomFocus zoomFocus) {
    focusRequest.value = (polygon, zoomFocus);
  }
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
    widget.controller.focusRequest.addListener(onFocusRequest);

    if (widget.controller.zoomToPath && widget.controller.path.value != null) {
      final polygon = Polygon(widget.controller.path.value!.$1.coordinates.map((c) => c.point).toList());
      startFocusAnimation(average(polygon), computeZoomScale(polygon));
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    widget.controller.focusRequest.removeListener(onFocusRequest);
    super.dispose();
  }

  void onFocusRequest() {
    final request = widget.controller.focusRequest.value;
    if (request != null) {
      final polygon = request.$1;
      final focus = switch (request.$2) {
        ZoomFocus.centroid => centroid(polygon),
        ZoomFocus.average => average(polygon),
      };
      startFocusAnimation(focus, computeZoomScale(polygon));
    }
  }

  void onRoomSelect(Room? previous, Room? next) {
    if (next != null) {
      startFocusAnimation(next.centroid, computeZoomScale(next));
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

  double computeZoomScale(Polygon polygon) {
    final topLeft = polygon.boundingBox.topLeft, bottomRight = polygon.boundingBox.bottomRight;

    final xScale = widget.width / (bottomRight.x - topLeft.x);
    final yScale = widget.height / (bottomRight.y - topLeft.y);

    final scale = xScale > yScale ? yScale : xScale;
    return scale * 0.5;
  }

  void onTapUp(TapUpDetails details, school.School school) {
    for (final room in school.rooms) {
      if (room.intersects(Point(details.localPosition.dx, details.localPosition.dy))) {
        if (widget.controller.roomSelectable) {
          ref.read(selectedRoomProvider.notifier).set(room);
        }
        if (widget.controller.focusOnTap) {
          startFocusAnimation(room.centroid, computeZoomScale(room));
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
                      ListenableBuilder(
                        listenable: widget.controller.path,
                        builder: (context, _) {
                          if (widget.controller.path.value == null) {
                            return SizedBox.shrink();
                          } else {
                            final path = widget.controller.path;
                            return CustomPaint(painter: PathPainter(path.value!.$1, path.value!.$2.point, widget.controller.transformationController));
                          }
                        }
                      ),
                      //RepaintBoundary(
                      //  child: CustomPaint(painter: DebugPainter(data.school)),
                      //),
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