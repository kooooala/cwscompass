import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/location.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/exit_button.dart';
import 'package:cwscompass/widgets/map/canvas.dart';
import 'package:cwscompass/data/map_data.dart';
import 'package:cwscompass/widgets/direction_sheet.dart';
import 'package:cwscompass/widgets/floor_selector.dart';
import 'package:cwscompass/data/school.dart' as school;
import 'package:cwscompass/widgets/route_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Navigation extends ConsumerStatefulWidget{
  late final MapCanvasController canvasController;
  final school.Route initialRoute;
  final Interactable end;

  Navigation({super.key, required this.initialRoute, required this.end});

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

  void _updateDirections() {
    displayRoute.directions.removeWhere((c) => !displayRoute.path.coordinates.contains(c.coordinates));
    ref.watch(locationProvider).whenData((location) {
      if (displayRoute.directions.isEmpty) {
        return;
      }

      double firstDistance = fastDistance(location, displayRoute.path.coordinates[1]);
      Coordinates node = displayRoute.path.coordinates[1];
      int i = 1;
      while (node != displayRoute.directions.first.coordinates) {
        firstDistance += fastDistance(displayRoute.path.coordinates[i], displayRoute.path.coordinates[i + 1]);
        node = displayRoute.path.coordinates[i + 1];
        i++;
      }
      displayRoute.directions.first.distance = firstDistance;
    });
  }

  void _updateDisplayRoute(school.Route newRoute) {
    setState(() {
      displayRoute = newRoute;
    });
    _updateDirections();
    widget.canvasController.path.value = displayRoute;
  }
  
  void _onLocationUpdate(Coordinates location) {
    ref.watch(mapDataProvider).whenData((data) {
      final closestNode = data.school.closestIntermediateNode(location);

      // Recalculate route if closest node is not in the route
      if (!route.path.coordinates.contains(closestNode)) {
        final newRoute = data.school.locationToInteractable(location, widget.end);
        setState(() => route = newRoute);
        _updateDisplayRoute(newRoute);
        debugPrint("Route recalculated");
        return;
      }

      final displayRoute = data.school.adjustRouteDisplay(location, route);
      _updateDisplayRoute(displayRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationProvider).whenData(_onLocationUpdate);

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
              child: RouteInfo(route: displayRoute, endRoom: widget.end),
            ),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 32.0, horizontal: 28.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start ,
                children: [
                  ExitButton(),
                  Spacer(),
                  FloorSelector(locationChangeable: false)
                ],
              ),
            ),
          ],
        ),
        DirectionSheet(directions: displayRoute.directions, endRoom: widget.end,)
      ],
    );
  }
}