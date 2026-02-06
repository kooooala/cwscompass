import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/widgets/overlays/route_preview.dart';
import 'package:cwscompass/map/school.dart' as school;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class Navigation extends ConsumerStatefulWidget{
  late final MapCanvasController canvasController;
  final school.Route initialRoute;
  final Room endRoom;

  Navigation({super.key, required this.initialRoute, required this.endRoom});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NavigationState();
}

class _NavigationState extends ConsumerState<Navigation> {
  late school.Route route;

  @override
  void initState() {
    super.initState();
    widget.canvasController = MapCanvasController(
      showPath: true,
      drawStart: true,
      drawEnd: true,
      maxAnimationScale: 16.0,
      transformationController: ref.read(transformationControllerProvider),
    );
    route = widget.initialRoute;
    widget.canvasController.path.value = route;
  }

  void updateRoute(school.Route newRoute) {
    setState(() {
      route = newRoute;
    });
    widget.canvasController.drawStart = false;
    widget.canvasController.path.value = route;
  }
  
  void onLocationUpdate(Position position) {
    ref.watch(mapDataProvider).whenData((data) {
      final location = Coordinates(position.latitude, position.longitude);
      final closestNode = data.school.closestNode(location);

      // Recalculate route if closest node is not in the route
      if (!route.path.coordinates.contains(closestNode)) {
        final newRoute = data.school.shortestRoutePairing([closestNode], widget.endRoom.entrances);
        updateRoute(newRoute);
        debugPrint("Route recalculated");
        return;
      }

      List<Coordinates> coordinates = route.path.coordinates;

      if (route.start != route.path.coordinates.first) {
        coordinates = route.path.coordinates.reversed.toList();
      }

      double shortestDistance = double.infinity;
      List<Coordinates> closestEdge = [];
      int closestEdgeIndex = -1;
      for (int i = 0; i < coordinates.length - 1; i++) {
        if (!pointIntersectsLine(location.point, coordinates[i].point, coordinates[i + 1].point)) {
          continue;
        }

        final distance = pointDistanceToLineWithinSegment(location.point, coordinates[i].point, coordinates[i + 1].point);
        if (distance < shortestDistance) {
          shortestDistance = distance;
          closestEdge = [coordinates[i], coordinates[i + 1]];
          closestEdgeIndex = i + 1;
        }
      }

      if (shortestDistance == double.infinity) {
        return;
      }

      // Remove the edges between the start and the one we're closest to
      final updatedCoordinates = coordinates.sublist(closestEdgeIndex, coordinates.length);
      final newRoute = school.Route(updatedCoordinates.first, route.end, school.Edge(updatedCoordinates));
      widget.canvasController.path.value = newRoute;
      updateRoute(newRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationProvider).whenData(onLocationUpdate);

    return Stack(
      children: [
        MapCanvas(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            controller: widget.canvasController
        ),
        Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 28.0,
                right: 28.0,
                top: MediaQuery.paddingOf(context).top + 16.0
              ),
              child: RouteInfo(route: route, endRoom: widget.endRoom),
            )
          ],
        )
      ],
    );
  }
}