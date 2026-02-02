import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/overlays/explore.dart';
import 'package:cwscompass/widgets/overlays/route_preview.dart';
import 'package:cwscompass/widgets/room_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class InfoSheet extends ConsumerStatefulWidget {
  const InfoSheet({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => InfoSheetState();
}

class InfoSheetState extends ConsumerState<InfoSheet> {
  late final SheetController controller;

  static const nearbySize = 0.5, minSize = 0.25;
  double currentSize = nearbySize;

  void animateSizeChange(double newSize) {
    currentSize = newSize;
    controller.animateTo(
        SheetOffset(newSize),
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOut
    );
  }

  void onRoomSelect(Room? previous, Room? next) {
    final newSize = next == null ? nearbySize : minSize;
    animateSizeChange(newSize);
  }

  @override
  void initState() {
    super.initState();
    controller = SheetController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final maxSize = (height - MediaQuery.paddingOf(context).top) / height;

    final snapSizes = [minSize, nearbySize, maxSize].map((s) => SheetOffset(s)).toList();
    currentSize = nearbySize;

    ref.listen<Room?>(selectedRoomProvider, onRoomSelect);

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
            // Expand the info sheet when it's tapped
            animateSizeChange(switch (currentSize) {
              nearbySize => minSize,
              minSize => nearbySize,
              _ => minSize
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Builder(builder: (context) {
              final selectedRoom = ref.watch(selectedRoomProvider);

              Widget content;
              if (selectedRoom == null) {
                content = NoneSelected(
                  key: ValueKey(selectedRoom)
                );
              } else {
                content = RoomInfo(
                  room: selectedRoom,
                  key: ValueKey(selectedRoom)
                );
              }

              return AnimatedSwitcher(
                duration: Duration(milliseconds: 150),
                child: content
              );
            })
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
        Row(
          children: [
            Text(
              room.name.capitalise(),
              style: TextStyle(
                color: ThemeColours.lightText,
                fontWeight: FontWeight.w900,
                fontSize: 28.0
              )
            ),
            Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => RoutePreview(initialDest: room,)));
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((_) => ThemeColours.accent),
                foregroundColor: WidgetStateProperty.resolveWith((_) => Colors.white),
                iconColor: WidgetStateProperty.resolveWith((_) => Colors.white),
                iconAlignment: IconAlignment.end,
              ),
              label: Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text(
                  "Go",
                  style: TextStyle(
                    fontWeight: FontWeight.w900
                  ),
                ),
              ),
              icon: Icon(Icons.turn_right_rounded),
            )
          ],
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

                // Limit the number of nearby rooms shown to 10
                final end = rooms.length > 5 ? 5 : rooms.length;
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