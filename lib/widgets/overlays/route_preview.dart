import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/polygon.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:cwscompass/map/school.dart' as school;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoutePreview extends ConsumerStatefulWidget {
  final Room initialEnd;
  late final MapCanvasController canvasController;
  
  RoutePreview({super.key, required this.initialEnd});

  @override
  ConsumerState<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends ConsumerState<RoutePreview> {
  Room? start, end;
  late school.Route route;

  (school.Route, Coordinates, Coordinates) calculateRoute() {
    final school = ref.read(mapDataProvider).value!.school;
    final location = ref.read(locationProvider).value!;
    final locationNode = school.closestNode(Coordinates(location.latitude, location.longitude));
    final startNodes =
    start == null
        ? <Coordinates>[locationNode]
        : start!.entrances;
    final endNodes =
    end == null
        ? <Coordinates>[locationNode]
        : end!.entrances;

    return school.shortestRoutePairing(startNodes, endNodes);
  }

  void updateRoute() {
    // Stop if the current location is selected for both start & end
    if (start == null && end == null) {
      return;
    }

    final shortestRoute = calculateRoute();
    final routePolygon = Polygon(shortestRoute.$1.coordinates.map((c) => c.point).toList());
    widget.canvasController.focus(routePolygon, ZoomFocus.average);
    widget.canvasController.path.value = (shortestRoute.$1, shortestRoute.$3);
    setState(() {
      route = shortestRoute.$1;
    });
  }
  
  @override
  void initState() {
    super.initState();
    end = widget.initialEnd;
    final shortestRoute = calculateRoute();
    widget.canvasController = MapCanvasController(
      focusOnTap: false,
      focusOnRoomSelect: false,
      zoomToPath: true,
      showPath: true,
      transformationController: ref.read(transformationControllerProvider),
    );
    widget.canvasController.path.value = (shortestRoute.$1, shortestRoute.$3);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapCanvas(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          controller: widget.canvasController
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: MediaQuery.paddingOf(context).top + 16.0, horizontal: 28.0),
          child: Stack(
            children: [
              Material(
                borderRadius: BorderRadius.circular(24.0),
                color: Colors.white,
                elevation: 4,
                child: Wrap(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final result = await Navigator.of(context).push<Room?>(MaterialPageRoute(builder: (context) => SearchPage()));
                        setState(() {
                          start = result;
                        });
                        updateRoute();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Icon(
                                Icons.circle_outlined,
                                size: 20.0,
                                color: ThemeColours.primary
                              ),
                            ),
                            Text(
                              start != null ? start!.name.capitalise() : "Your location",
                              style: TextStyle(
                                  fontSize: 16.0
                              ),
                            ),
                            Spacer()
                          ],
                        )
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(
                        thickness: 1.0,
                        color: ThemeColours.divider,
                        height: 0,
                      )
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final result = await Navigator.of(context).push<Room?>(MaterialPageRoute(builder: (context) => SearchPage()));
                        setState(() {
                          end = result;
                        });
                        updateRoute();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 20.0,
                                color: ThemeColours.primary
                              ),
                            ),
                            Text(
                              end != null ? end!.name.capitalise() : "Your location",
                              style: TextStyle(
                                fontSize: 16.0
                              ),
                            )
                          ],
                        )
                      ),
                    )
                  ]
                )
              )
            ],)
        )
      ]
    );
  }
}