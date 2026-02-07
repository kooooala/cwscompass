import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/polygon.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/overlays/navigation.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:cwscompass/map/school.dart' as school;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoutePreview extends ConsumerStatefulWidget {
  final Room initialEnd;
  late final MapCanvasController canvasController;
  
  RoutePreview({super.key, required this.initialEnd});

  @override
  ConsumerState<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends ConsumerState<RoutePreview> {
  Room? start;
  late Room end;
  late school.Route route;

  double swapRotation = 0.0;

  void rotateSwap() {
    setState(() => swapRotation += 0.5);
  }

  school.Route calculateRoute() {
    final mapData = ref.read(mapDataProvider).value!;

    school.Route shortestRoute;
    if (start == null) {
      final location = ref.read(locationProvider).value!;
      shortestRoute = mapData.school.locationToRoom(Coordinates(location.latitude, location.longitude), end);
    } else {
      shortestRoute = mapData.school.shortestRoutePairing(start!.entrances, end.entrances);
    }

    return shortestRoute;
  }

  void updateRoute(bool focus) {
    final shortestRoute = calculateRoute();

    if (focus) {
      final routePolygon = Polygon(shortestRoute.path.coordinates.map((c) => c.point).toList());
      widget.canvasController.focus(routePolygon, ZoomFocus.average);
    }
    widget.canvasController.path.value = shortestRoute;
    setState(() {
      route = shortestRoute;
    });
  }
  
  @override
  void initState() {
    super.initState();
    end = widget.initialEnd;
    final shortestRoute = calculateRoute();
    widget.canvasController = MapCanvasController(
      drawStart: true,
      drawEnd: true,
      zoomToPath: true,
      showPath: true,
      maxAnimationScale: 16.0,
      focusYOffset: 0,
      transformationController: ref.read(transformationControllerProvider),
    );
    route = shortestRoute;
    widget.canvasController.path.value = shortestRoute;
  }

  void onLocationUpdate(Position position) {
    if (start != null) {
      return;
    }

    updateRoute(false);
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 16.0, left: 28.0, right: 48.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Hero(
                    tag: "search-bar",
                    child: Material(
                        borderRadius: BorderRadius.circular(24.0),
                        color: Colors.white,
                        elevation: 4,
                        child: Wrap(
                            children: [
                              GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final result = await Navigator.of(context).push<SearchResult>(
                                        MaterialPageRoute(
                                            builder: (context) => SearchPage(myLocationSelectable: true)
                                        )
                                    );
                                    switch (result) {
                                      case SearchResultNone _:
                                        return;
                                      case SearchResultDeviceLocation _:
                                        setState(() => start = null);
                                        break;
                                      case SearchResultRoom r:
                                        setState(() => start = r.room);
                                        break;
                                    }
                                    updateRoute(true);
                                  },
                                  child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: AnimatedSwitcher(
                                          duration: Duration(milliseconds: 300),
                                          child: Row(
                                            key: ValueKey(start),
                                            mainAxisAlignment: MainAxisAlignment.start,
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
                                                start != null ? start!.name.capitalise() : "My location",
                                                style: TextStyle(
                                                    color: ThemeColours.darkTextTint,
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.w600
                                                ),
                                              ),
                                              Spacer()
                                            ],
                                          )
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
                                  final result = await Navigator.of(context).push<SearchResult>(
                                      MaterialPageRoute(
                                          builder: (context) => SearchPage(myLocationSelectable: false)
                                      )
                                  );
                                  switch (result) {
                                    case SearchResultNone _:
                                    case SearchResultDeviceLocation _:
                                      return;
                                    case SearchResultRoom r:
                                      setState(() => end = r.room);
                                      break;
                                  }
                                  updateRoute(true);
                                },
                                child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: AnimatedSwitcher(
                                        duration: Duration(milliseconds: 300),
                                        child: Row(
                                          key: ValueKey(end),
                                          mainAxisAlignment: MainAxisAlignment.start,
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
                                              end.name.capitalise(),
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: ThemeColours.darkTextTint,
                                                  fontWeight: FontWeight.w600
                                              ),
                                            )
                                          ],
                                        )
                                    )
                                ),
                              )
                            ]
                        )
                    )
                  ),
                ]
              ),
            ),
            Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Navigation(initialRoute: route, endRoom: end)
                      )
                    );
                  },
                  child: Material(
                    color: ThemeColours.accent,
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(24.0),
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Wrap(
                          direction: Axis.horizontal,
                          spacing: 12.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Go",
                              style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.w900,
                                  color: ThemeColours.lightText
                              ),
                            ),
                            Transform.flip(
                              flipX: true,
                              child: PhosphorIcon(
                                PhosphorIconsFill.navigationArrow,
                                color: ThemeColours.lightText,
                                size: 20.0,
                              )
                            )
                          ],
                        )
                    ),
                  )
                )
              )
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 28.0,
                right: 28.0,
                bottom: MediaQuery.paddingOf(context).bottom + 16.0,
              ),
              child: RouteInfo(route: route, endRoom: end)
            )
          ]
        ),
        Positioned(
            top: MediaQuery.paddingOf(context).top + 40.0,
            right: 23.0,
            child: GestureDetector(
              onTap: () {
                if (start == null) {
                  
                  return;
                }

                setState(() {
                  final temp = start;
                  start = end;
                  end = temp!;
                });
                rotateSwap();
              },
              child: Container(
                height: 46.0,
                width: 46.0,
                decoration: BoxDecoration(
                    color: start != null ? ThemeColours.accent : ThemeColours.disabled,
                    boxShadow: [BoxShadow(
                        offset: Offset(0, 3),
                        blurRadius: 4.0,
                        color: Colors.black.withAlpha(64)
                    )],
                    shape: BoxShape.circle
                ),
                child: AnimatedRotation(
                    turns: swapRotation,
                    duration: Duration(milliseconds: 150),
                    curve: Curves.easeInOutSine,
                    child: PhosphorIcon(
                      PhosphorIconsBold.arrowsDownUp,
                      size: 24.0,
                      color: Colors.white,
                    )
                ),
              ),
            )
        )
      ]
    );
  }
}

class RouteInfo extends StatelessWidget {
  final school.Route route;
  final Room? endRoom;

  const RouteInfo({super.key, required this.route, required this.endRoom});

  @override
  Widget build(BuildContext context) {
    const walkingSpeed = 3;
    final travelTime = route.path.distance / walkingSpeed;
    final travelTimeMin = (travelTime / 60).round();
    final eta = DateTime.now().add(Duration(seconds: travelTime.round()));
    final formattedEta = DateFormat.Hm().format(eta);
    final endName = endRoom == null ? "my location" : endRoom!.name.capitalise();

    return Material(
      borderRadius: BorderRadius.circular(24.0),
      color: ThemeColours.primary,
      elevation: 4,
      child: Wrap(
        children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Row(
                    key: UniqueKey(),
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "To $endName",
                                style: TextStyle(
                                    color: ThemeColours.lightText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700
                                )
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "${travelTimeMin < 1 ? "< 1" : travelTimeMin} min",
                                  style: TextStyle(
                                      color: ThemeColours.lightText,
                                      fontSize: 26.0,
                                      fontWeight: FontWeight.w900
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                        "/ ETA $formattedEta",
                                        style: TextStyle(
                                            color: ThemeColours.lightTextTint,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w600
                                        )
                                    )
                                )
                              ],
                            )
                          ]
                      ),
                      Spacer(),
                      Text(
                        "${route.path.distance.round()}m",
                        style: TextStyle(
                            color: ThemeColours.lightText,
                            fontSize: 24.0,
                            fontWeight: FontWeight.w900
                        ),
                      )
                    ],
                  )
              )
          )
        ],
      ),
    );
  }
}