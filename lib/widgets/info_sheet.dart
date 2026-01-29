import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/room_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class InfoSheet extends StatefulWidget {
  final ValueNotifier<Room?> selectedRoom;

  const InfoSheet({super.key, required this.selectedRoom});

  @override
  State<StatefulWidget> createState() => InfoSheetState();
}

class InfoSheetState extends State<InfoSheet> {
  late final SheetController controller;

  static const nearbySize = 0.5, minSize = 0.25;

  void animateSizeChange(SheetOffset newSize) {
    controller.animateTo(
        newSize,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOut
    );
  }

  void onRoomSelect() {
    final newSize = widget.selectedRoom.value == null ? nearbySize : minSize;
    animateSizeChange(SheetOffset(newSize));
  }

  @override
  void initState() {
    super.initState();
    controller = SheetController();
    widget.selectedRoom.addListener(onRoomSelect);
  }

  @override
  void didUpdateWidget(InfoSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // In case the parent widget is rebuilt and a new selectedRoom object is created
    if (oldWidget.selectedRoom != widget.selectedRoom) {
      oldWidget.selectedRoom.removeListener(onRoomSelect);
      widget.selectedRoom.addListener(onRoomSelect);
      onRoomSelect();
    }
  }

  @override
  void dispose() {
    widget.selectedRoom.removeListener(onRoomSelect);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final maxSize = (height - MediaQuery.paddingOf(context).top) / height;

    final snapSizes = [minSize, nearbySize, maxSize].map((s) => SheetOffset(s)).toList();

    return SheetViewport(
        child: Sheet(
            controller: controller,
            decoration: MaterialSheetDecoration(
                size: SheetSize.stretch,
                color: ThemeColours.primary,
                borderRadius: BorderRadius.circular(24.0),
                shadowColor: Colors.black
            ),
            scrollConfiguration: SheetScrollConfiguration(),
            initialOffset: snapSizes[1],
            snapGrid: MultiSnapGrid(
                snaps: snapSizes
            ),
            physics: ClampingSheetPhysics(
                spring: SpringDescription(
                    mass: 1,
                    stiffness: 1000,
                    damping: 100
                )
            ),
            child: GestureDetector(
                onTap: () {
                  // Expand the room card when it's tapped
                  if (widget.selectedRoom.value != null) {
                    animateSizeChange(snapSizes[1]);
                  }
                },
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: ValueListenableBuilder(
                        valueListenable: widget.selectedRoom,
                        builder: (context, value, _) {
                          Widget widget;
                          if (value == null) {
                            widget = NoneSelected(
                              key: ValueKey(value),
                            );
                          } else {
                            widget = RoomInfo(
                                key: ValueKey(value),
                                room: value
                            );
                          }

                          return AnimatedSwitcher(
                              duration: Duration(milliseconds: 150),
                              child: widget
                          );
                        }
                    )
                )
            )
        )
    );
  }
}

class RoomInfo extends StatelessWidget {
  final Room room;

  const RoomInfo({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text(
          "Room ${room.number}",
          style: TextStyle(
            color: ThemeColours.lightText,
            fontWeight: FontWeight.w900,
            fontSize: 28.0
          )
        ),
        Text(
          "${room.subject.capitalise()} • Building",
          style: TextStyle(
            color: ThemeColours.lightTextTint,
            fontWeight: FontWeight.w800,
            fontSize: 16.0
          ),
        ),
        Text(
          "No upcoming lessons",
          style: TextStyle(
            color: ThemeColours.lightText,
            fontWeight: FontWeight.w800,
            fontSize: 20.0
          )
        )
      ],
    );
  }
}

class NoneSelected extends ConsumerWidget {
  const NoneSelected({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.watch(mapDataProvider);
    final location = ref.watch(locationProvider);

    return location.when(
      data: (locationData) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child:  Text(
                  "Nearby",
                  style: TextStyle(
                      color: ThemeColours.lightText,
                      fontWeight: FontWeight.w900,
                      fontSize: 28.0
                  )
              ),
            ),
            mapData.when(
              data: (data) {
                final rooms = data.school.rooms;
                rooms.sort((a, b) {
                  final coordinates = Coordinates(locationData.latitude, locationData.longitude);
                  return a.distanceFrom(coordinates).compareTo(b.distanceFrom(coordinates));
                });

                // Limit the number of nearby rooms shown to 10
                final end = rooms.length > 10 ? 10 : rooms.length;
                return RoomList(
                  rooms: rooms.sublist(0, end),
                );
              },
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text("Oops: $err")
            )
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text("Oops: $err")
    );
  }
}