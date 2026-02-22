import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/data/location.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/exit_button.dart';
import 'package:cwscompass/widgets/map/canvas.dart';
import 'package:cwscompass/data/map_data.dart';
import 'package:cwscompass/common/polygon.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/widgets/floor_selector.dart';
import 'package:cwscompass/widgets/map/selected_floor.dart';
import 'package:cwscompass/widgets/map/zoom_focus.dart';
import 'package:cwscompass/widgets/pages/explore.dart';
import 'package:cwscompass/widgets/pages/navigation.dart';
import 'package:cwscompass/widgets/route_info.dart';
import 'package:cwscompass/widgets/pages/search_page.dart';
import 'package:cwscompass/data/school.dart' as school;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoutePreview extends ConsumerStatefulWidget {
  final Interactable initialEnd;
  late final MapCanvasController canvasController;
  
  RoutePreview({super.key, required this.initialEnd});

  @override
  ConsumerState<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends ConsumerState<RoutePreview> {
  Interactable? start;
  late Interactable end;
  late school.Route route;

  double swapRotation = 0.0;

  void _rotateSwap() {
    setState(() => swapRotation += 0.5);
  }

  school.Route _calculateRoute() {
    final mapData = ref.read(mapDataProvider).value!;

    school.Route shortestRoute;
    if (start == null) {
      final location = ref.read(locationProvider).value!;
      shortestRoute = mapData.school.locationToInteractable(location, end);
    } else {
      shortestRoute = mapData.school.shortestRoutePairing(start!.entrances, end.entrances);
    }

    return shortestRoute;
  }

  void _updateRoute(bool focus) {
    final shortestRoute = _calculateRoute();

    if (focus) {
      final routePolygon = Polygon(shortestRoute.path.coordinates);
      widget.canvasController.focusPolygon(routePolygon, ZoomFocus.average);
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
    final shortestRoute = _calculateRoute();
    widget.canvasController = MapCanvasController(
      drawStart: true,
      drawEnd: true,
      zoomToPath: true,
      showPath: true,
      roomSelectable: true,
      maxAnimationScale: 16.0,
      focusYOffset: 0,
      transformationController: ref.read(transformationControllerProvider),
    );
    route = shortestRoute;
    widget.canvasController.path.value = shortestRoute;
    ref.read(locationProvider).whenData((location) {
      ref.read(selectedFloorProvider.notifier).setView(location.floor);
    });
  }

  void _onLocationUpdate(_) {
    _updateRoute(false);
  }

  void _onRoomSelect(_, Interactable? interactable) {
    if (interactable == null) {
      return;
    }

    setState(() => end = interactable);
    _updateRoute(true);
  }

  Widget _routePicker() {
    return Material(
      borderRadius: BorderRadius.circular(24.0),
      color: Colors.white,
      elevation: 4,
      child: Wrap(
        children: [
          // Start location picker
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
                case SearchResultInteractable r:
                  setState(() => start = r.interactable);
                  break;
              }
              _updateRoute(true);
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
          // Divider between start and end
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              thickness: 1.0,
              color: ThemeColours.divider,
              height: 0,
            )
          ),
          // End location picker
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
                  // You can't navigate to your current location
                  return;
                case SearchResultInteractable r:
                  setState(() => end = r.interactable);
                  break;
              }
              _updateRoute(true);
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
    );
  }

  Widget _goButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Navigation(initialRoute: route, end: end)
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
    );
  }

  Widget _swapButton() {
    return GestureDetector(
      onTap: () {
        if (start == null) {
          return;
        }

        setState(() {
          final temp = start;
          start = end;
          end = temp!;
        });
        _rotateSwap();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationProvider).whenData(_onLocationUpdate);
    ref.listen<Interactable?>(selectedRoomProvider, _onRoomSelect);

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
            // Route picker
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 16.0, left: 28.0, right: 48.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Hero(
                    tag: "search-bar",
                    child: _routePicker()
                  ),
                ]
              ),
            ),
            // Exit button
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
            Spacer(),
            // Go button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                child: _goButton()
              )
            ),
            // Route info card
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
        // Swap button
        Positioned(
          top: MediaQuery.paddingOf(context).top + 40.0,
          right: 23.0,
          child: _swapButton()
        )
      ]
    );
  }
}
