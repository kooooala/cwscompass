import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:flutter/material.dart';

class RoutePreview extends StatefulWidget {
  final Room initialDest;
  final MapCanvasController canvasController;
  
  const RoutePreview({super.key, required this.initialDest, required this.canvasController});

  @override
  State<RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends State<RoutePreview> {
  Room? start, dest;
  
  @override
  void initState() {
    super.initState();
    dest = widget.initialDest;
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withAlpha(32),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )]
                ),
                child: Wrap(
                    children: [
                      GestureDetector(
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
                                    start != null ? "Room ${start!.number}" : "Your location",
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
                                  dest != null ? "Room ${dest!.number}" : "Your location",
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