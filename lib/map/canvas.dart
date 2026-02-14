import 'dart:async';
import 'dart:math';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/map/debug_painter.dart';
import 'package:cwscompass/map/staircase_painter.dart';
import 'package:cwscompass/polygon.dart';
import 'package:cwscompass/widgets/overlays/explore.dart';
import 'package:vector_math/vector_math_64.dart' as vectors;

import 'package:cwscompass/map/label_painter.dart';
import 'package:cwscompass/map/marker.dart';
import 'package:cwscompass/map/path_painter.dart';
import 'package:cwscompass/map/room_painter.dart';
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

abstract class FocusRequest {}

class PolygonFocus extends FocusRequest {
  final Polygon polygon;
  final ZoomFocus zoomFocus;

  PolygonFocus(this.polygon, this.zoomFocus);
}

class PointFocus extends FocusRequest {
  final Point<double> focus;
  final double scale;

  PointFocus(this.focus, this.scale);
}

class FloorSelection {
  final int viewFloor, locationFloor;
  final int floorCount;

  FloorSelection(this.viewFloor, this.locationFloor, this.floorCount);
}

class SelectedFloorProvider extends AsyncNotifier<FloorSelection> {
  @override
  FutureOr<FloorSelection> build() async {
    final data = await ref.watch(mapDataProvider.future);
    return FloorSelection(0, 0, data.school.floors.length);
  }

  void setView(int floor) {
    final old = state.value;

    if (old != null) {
      state = AsyncData(FloorSelection(floor, old.locationFloor, old.floorCount));
    }
  }

  void setLocation(int floor) {
    final old = state.value;

    if (old != null) {
      state = AsyncData(FloorSelection(old.viewFloor, floor, old.floorCount));
    }
  }
}

final selectedFloorProvider = AsyncNotifierProvider<SelectedFloorProvider, FloorSelection>(SelectedFloorProvider.new);

class MapCanvasController {
  bool focusOnTap;
  bool focusOnRoomSelect;

  bool roomSelectable;

  bool drawStart, drawEnd;

  bool showPath;
  bool zoomToPath;
  double maxAnimationScale;
  double focusYOffset;
  ValueNotifier<school.Route?> path = ValueNotifier(null);

  final TransformationController transformationController;

  final ValueNotifier<FocusRequest?> focusRequest = ValueNotifier(null);

  MapCanvasController({
    this.focusOnTap = false,
    this.focusOnRoomSelect = false,
    this.roomSelectable = false,
    this.drawStart = false,
    this.drawEnd = false,
    this.showPath = false,
    this.zoomToPath = false,
    this.maxAnimationScale = 32.0,
    this.focusYOffset = 75.0,
    required this.transformationController
  });

  void focusPolygon(Polygon polygon, ZoomFocus zoomFocus) {
    focusRequest.value = PolygonFocus(polygon, zoomFocus);
  }

  void focusPoint(Point<double> focus, double scale) {
    focusRequest.value = PointFocus(focus, scale);
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
      final polygon = Polygon(widget.controller.path.value!.path.coordinates);
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
      Point<double> focus;
      double scale;

      switch (request) {
        case PointFocus pointFocus:
          focus = pointFocus.focus;
          scale = pointFocus.scale;
          break;
        case PolygonFocus polygonFocus:
          focus = switch (polygonFocus.zoomFocus) {
            ZoomFocus.centroid => centroid(polygonFocus.polygon),
            ZoomFocus.average => average(polygonFocus.polygon),
          };
          scale = computeZoomScale(polygonFocus.polygon);
        default:
          return;
      }
      startFocusAnimation(focus, scale);
    }
  }

  void onRoomSelect(Room? _, Room? next) {
    if (next != null) {
      startFocusAnimation(next.centroid, computeZoomScale(next));
    }
  }

  void startFocusAnimation(Point<double> focus, double scale) {
    if (focusAnimation != null) {
      cancelAnimation();
    }

    if (scale >= widget.controller.maxAnimationScale) {
      scale = widget.controller.maxAnimationScale;
    }

    final x = -focus.x * scale + widget.width / 2;
    final y = -focus.y * scale + widget.height / 2 - widget.controller.focusYOffset;

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
    ref.watch(selectedFloorProvider).whenData((selected) {
      for (final room in school.floors[selected.viewFloor].rooms) {
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
    });
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
                  child: ref.watch(selectedFloorProvider).when(
                    data: (selected) {
                      return Stack(
                        children: [
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 150),
                            child: Stack(
                              key: ValueKey(selected.viewFloor),
                              children: [
                                RepaintBoundary(
                                  child: CustomPaint(painter: StructurePainter(
                                    structures: data.school.floors[selected.viewFloor].buildings,
                                    floor: selected.viewFloor,
                                    nameVisible: false
                                  )),
                                ),
                                RepaintBoundary(
                                  child: CustomPaint(painter: StructurePainter(
                                    structures: data.school.floors[selected.viewFloor].rooms,
                                    floor: selected.viewFloor
                                  )),
                                ),
                                RepaintBoundary(
                                    child: CustomPaint(painter: LabelPainter(data.school, selected.viewFloor))
                                ),
                                ListenableBuilder(
                                    listenable: widget.controller.path,
                                    builder: (context, _) {
                                      if (widget.controller.path.value == null) {
                                        return SizedBox.shrink();
                                      } else {
                                        return CustomPaint(painter: PathPainter(
                                            drawStart: widget.controller.drawStart,
                                            drawEnd: widget.controller.drawEnd,
                                            route: widget.controller.path.value!,
                                            floor: selected.viewFloor,
                                            transformations: widget.controller.transformationController
                                        ));
                                      }
                                    }
                                ),
                                RepaintBoundary(
                                  child: CustomPaint(painter: StaircasePainter(data.school, selected.viewFloor, 0.5)),
                                ),
                              ],
                            )
                          ),
                          //RepaintBoundary(
                          //  child: CustomPaint(painter: DebugPainter(data.school, selected.viewFloor)),
                          //),
                          Marker(2, data.school),
                        ],
                      );
                    },
                    loading: () => CircularProgressIndicator(),
                    error: (err, stack) => Text("Oops: $err")
                  )
                )
              ),
            )
          );
        },
        loading: () => CircularProgressIndicator(),
        error: (err, stack) {
          Text("Oops: $err");
          return null;
        },
      ),
    );
  }
}