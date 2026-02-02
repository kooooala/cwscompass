import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoutePreview extends ConsumerStatefulWidget {
  final Room initialDest;
  late final MapCanvasController canvasController;
  
  RoutePreview({super.key, required this.initialDest});

  @override
  ConsumerState<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends ConsumerState<RoutePreview> {
  Room? start, dest;
  
  @override
  void initState() {
    super.initState();
    dest = widget.initialDest;
    widget.canvasController = MapCanvasController(
      transformationController: ref.read(transformationControllerProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.canvasController.focusOnTap = false;
    widget.canvasController.focusOnRoomSelect = false;
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
                          dest = result;
                        });
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
                              dest != null ? dest!.name.capitalise() : "Your location",
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