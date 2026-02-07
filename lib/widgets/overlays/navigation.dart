import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/widgets/direction_sheet.dart';
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
  late school.Route displayRoute;

  @override
  void initState() {
    super.initState();
    widget.canvasController = MapCanvasController(
      showPath: true,
      drawStart: false,
      drawEnd: true,
      maxAnimationScale: 16.0,
      transformationController: ref.read(transformationControllerProvider),
    );
    route = widget.initialRoute;
    widget.canvasController.path.value = route;
  }

  void updateDirections() {
    displayRoute.directions.removeWhere((c) => !displayRoute.path.coordinates.contains(c.coordinates));
    ref.watch(locationProvider).whenData((position) {
      final location = Coordinates(position.latitude, position.longitude);

      if (displayRoute.directions.isEmpty) {
        return;
      }

      displayRoute.directions.first.distance = equirectangularDistance(location, displayRoute.directions.first.coordinates);
    });
  }

  void updateDisplayRoute(school.Route newRoute) {
    setState(() {
      displayRoute = newRoute;
    });
    updateDirections();
    widget.canvasController.path.value = displayRoute;
  }
  
  void onLocationUpdate(Position position) {
    ref.watch(mapDataProvider).whenData((data) {
      final location = Coordinates(position.latitude, position.longitude);
      final closestNode = data.school.closestIntermediateNode(location);

      // Recalculate route if closest node is not in the route
      if (!route.path.coordinates.contains(closestNode)) {
        final newRoute = data.school.locationToRoom(location, widget.endRoom);
        setState(() => route = newRoute);
        updateDisplayRoute(newRoute);
        debugPrint("Route recalculated");
        return;
      }

      final displayRoute = data.school.adjustRouteDisplay(location, route);
      updateDisplayRoute(displayRoute);
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
        ),
        DirectionSheet(directions: displayRoute.directions, endRoom: widget.endRoom,)
      ],
    );
  }
}