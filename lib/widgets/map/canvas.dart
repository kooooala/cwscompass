import 'dart:math';
import 'package:cwscompass/widgets/map/selected_floor.dart';
import 'package:cwscompass/widgets/map/zoom_focus.dart';
import 'package:vector_math/vector_math_64.dart' as vectors;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/loading.dart';
import 'package:cwscompass/widgets/map/staircase_painter.dart';
import 'package:cwscompass/common/polygon.dart';
import 'package:cwscompass/widgets/pages/explore.dart';
import 'package:cwscompass/widgets/map/label_painter.dart';
import 'package:cwscompass/widgets/map/marker.dart';
import 'package:cwscompass/widgets/map/path_painter.dart';
import 'package:cwscompass/widgets/map/structure_painter.dart';
import 'package:cwscompass/data/school.dart' as school;
import 'package:cwscompass/data/map_data.dart';

final transformationControllerProvider = Provider((ref) {
  return TransformationController();
});

class MapCanvasController {
  // Control whether tapping on a room causes it to be focused
  bool focusOnTap;
  // Control whether selecting a room (not from tapping on the map) causes it to be focused
  bool focusOnRoomSelect;

  // Control whether tapping on a room affects the value in selectedRoomProvider
  bool roomSelectable;

  // Control whether the start/end of the path is drawn
  bool drawStart, drawEnd;

  // Control whether the path is shown on the map
  bool showPath;
  // Control whether the path is zoomed to when it changes
  bool zoomToPath;
  // Control the maximum zoom scale of focus animations
  double maxAnimationScale;
  // Control how much the y coordinates is offset in focus animations
  double focusYOffset;
  // The path displayed on the map
  ValueNotifier<school.Route?> path = ValueNotifier(null);

  // The transformation controller used by the interactive viewer in the canvas
  // Essentially a thin wrapper of a 4d matrix that represents the transformations the interactive viewer is transformed by
  final TransformationController transformationController;

  // The canvas listens to this and starts a focus animation when its value changes
  final ValueNotifier<FocusRequest?> _focusRequest = ValueNotifier(null);

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
    _focusRequest.value = PolygonFocus(polygon, zoomFocus);
  }

  void focusPoint(Point<double> focus, double scale) {
    _focusRequest.value = PointFocus(focus, scale);
  }
}

class MapCanvas extends ConsumerStatefulWidget {
  final double width, height;
  final MapCanvasController controller;

  MapCanvas({super.key, required this.width, required this.height, required this.controller});

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
    // Listen to focus requests
    widget.controller._focusRequest.addListener(onFocusRequest);

    // Zoom to controller's path if there already is a value in it
    if (widget.controller.zoomToPath && widget.controller.path.value != null) {
      final polygon = Polygon(widget.controller.path.value!.path.coordinates);
      startFocusAnimation(average(polygon), computeZoomScale(polygon));
    }
  }

  @override
  void dispose() {
    // Clean-up
    animationController.dispose();
    widget.controller._focusRequest.removeListener(onFocusRequest);
    super.dispose();
  }

  void onFocusRequest() {
    final request = widget.controller._focusRequest.value;
    if (request != null) {
      Point<double> focus;
      double scale;

      // Calculate scale and focus based on the type of focus requested
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

  void onRoomSelect(Interactable? _, Interactable? next) {
    if (next != null) {
      // Zoom to room
      startFocusAnimation(next.centroid, computeZoomScale(next));
    }
  }

  void startFocusAnimation(Point<double> focus, double scale) {
    if (focusAnimation != null) {
      // Cancel the existing animation if there already is an animation running
      cancelAnimation();
    }

    // Prevent scale from going over controller.maxAnimationScale
    scale = scale.clamp(1.0, widget.controller.maxAnimationScale);

    final x = -focus.x * scale + widget.width / 2;
    final y = -focus.y * scale + widget.height / 2 - widget.controller.focusYOffset;

    animationController.reset();
    // Generate values beTWEEN the transformation controller's current value and the new focus
    focusAnimation = Matrix4Tween(
      begin: widget.controller.transformationController.value,
      end: Matrix4.compose(
        // Translation
        vectors.Vector3(x, y, 0),
        // Identity matrix for rotation since we're not rotating the map
        vectors.Quaternion.identity(),
        vectors.Vector3.all(scale)
      )
    ).animate(CurvedAnimation(
      parent: animationController, 
      curve: Curves.easeInOutSine
    ));
    // Attach onAnimationUpdate to update the transformation controller's value
    focusAnimation!.addListener(onAnimationUpdate);
    animationController.forward();
  }

  void onAnimationUpdate() {
    // Set the transformation controller's value to the animation's value
    widget.controller.transformationController.value = focusAnimation!.value;
    if (!animationController.isAnimating) {
      cancelAnimation();
    }
  }

  void cancelAnimation() {
    // Stop the animation and remove the listener we attached
    animationController.stop();
    focusAnimation!.removeListener(onAnimationUpdate);
    focusAnimation = null;
    animationController.reset();
  }

  double computeZoomScale(Polygon polygon) {
    final topLeft = polygon.boundingBox.topLeft, bottomRight = polygon.boundingBox.bottomRight;

    final xScale = widget.width / (bottomRight.x - topLeft.x);
    final yScale = widget.height / (bottomRight.y - topLeft.y);

    // Get the smaller of the two to make sure the entire polygon is visible
    final scale = xScale > yScale ? yScale : xScale;
    return scale * 0.5;
  }

  void onTapUp(TapUpDetails details, school.School school) {
    ref.watch(selectedFloorProvider).whenData((selected) {
      // Iterate through each interactable on the floor and check if the tapped point intersects
      for (final room in school.floors[selected.viewFloor].structures.whereType<Interactable>()) {
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

  Widget baseLayer(int floor, school.School school) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Building layer
          CustomPaint(
            painter: StructurePainter(
              structures: school.floors[floor].buildings,
              floor: floor,
            )
          ),
          // Interactable layer
          CustomPaint(
            painter: StructurePainter(
              structures: school.floors[floor].structures.whereType<Interactable>(),
              floor: floor,
            )
          ),
          // Inaccessible area layer
          CustomPaint(
            painter: StructurePainter(
              structures: school.floors[floor].inaccessible,
              floor: floor,
            )
          ),
          // Interactable label layer
          CustomPaint(
            painter: LabelPainter(
              structures: school.floors[floor].structures.whereType<Interactable>(),
              floor: floor
            )
          ),
          CustomPaint(painter: StaircasePainter(school, floor, 0.5))
        ],
      ),
    );
  }

  Widget buildingOverlay(double scale, int floor, school.School school) {
    // The scale at which the fade animation starts/ends
    final startFade = 4.0, endFade = 7.0;
    return Opacity(
      opacity: (1 - (scale.clamp(startFade, endFade) - startFade) / (endFade - startFade)).clamp(0, 0.9),
      child: ColoredBox(
        color: Colors.white,
        child: Stack(
          children: [
            CustomPaint(
              painter: StructurePainter(
                structures: school.floors[floor].buildings,
                floor: floor,
              ),
              size: Size.infinite,
            ),
            CustomPaint(
              painter: LabelPainter(
                structures: school.floors[floor].buildings,
                floor: floor
              ),
            )
          ],
        )
      )
    );
  }

  Widget pathPainter(int floor) {
    return ListenableBuilder(
      listenable: widget.controller.path,
      builder: (context, _) {
        if (widget.controller.path.value == null || !widget.controller.showPath) {
          return SizedBox.shrink();
        } else {
          return CustomPaint(painter: PathPainter(
            drawStart: widget.controller.drawStart,
            drawEnd: widget.controller.drawEnd,
            route: widget.controller.path.value!,
            floor: floor,
            transformations: widget.controller.transformationController
          ));
        }
      }
    );
  }

  Widget map(int floor, school.School school) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 150),
      child: Stack(
        key: ValueKey(floor),
        children: [
          baseLayer(floor, school),
          ListenableBuilder(
            listenable: widget.controller.transformationController,
            builder: (_, _) {
              final scale = widget.controller.transformationController.value.getMaxScaleOnAxis();
              return buildingOverlay(scale, floor, school);
            }
          ),
          pathPainter(floor),
          CustomPaint(painter: StaircasePainter(school, floor, 0.5)),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = ref.watch(mapDataProvider);

    if (widget.controller.focusOnRoomSelect) {
      ref.listen<Interactable?>(selectedRoomProvider, onRoomSelect);
    }

    return Center(
      child: school.when(
        data: (data) {
          return Container(
            color: Colors.white,
            child: InteractiveViewer(
              transformationController: widget.controller.transformationController,
              onInteractionStart: (_) {
                if (animationController.status == AnimationStatus.forward) {
                  cancelAnimation();
                }
              },
              minScale: 1,
              maxScale: 64,
              boundaryMargin: EdgeInsets.symmetric(horizontal: widget.width / 4, vertical: widget.height / 4),
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
                            map(selected.viewFloor, data.school),
                            // This draws out lines and nodes which are useful when debugging the map
                            //CustomPaint(painter: DebugPainter(data.school, selected.viewFloor)),
                            Marker(20.0, widget.controller.transformationController, data.school),
                          ],
                        );
                      },
                      loading: () => Loading(colour: ThemeColours.primary),
                      error: (err, stack) => Text("Oops: $err")
                    )
                  )
                ),
              )
            ),
          );
        },
        loading: () => Loading(colour: ThemeColours.primary),
        error: (err, stack) {
          Text("Oops: $err");
          return null;
        },
      ),
    );
  }
}