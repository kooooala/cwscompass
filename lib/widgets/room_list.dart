import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/rounded_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomList extends ConsumerWidget {
  final List<Room> rooms;

  final void Function(Room room) onRoomTap;

  const RoomList({super.key, required this.rooms, this.onRoomTap = defaultRoomTap});

  static void defaultRoomTap(Room room) {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    return RoundedList(
      radius: 12.0,
      children: List<Widget>.generate(rooms.length, (i) {
        final room = rooms[i];
        return GestureDetector(
          onTap: () => onRoomTap(room),
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 8.0,
                children: [
                  Text(
                    room.name.capitalise(),
                    style: TextStyle(
                        color: ThemeColours.darkText,
                        fontSize: 18.0
                    )
                  ),
                  Text(
                    room.subject.capitalise(),
                    style: TextStyle(
                        color: ThemeColours.darkTextTint,
                        fontSize: 14.0
                    )
                  ),
                  Spacer(),
                  location.when<Widget>(
                    data: (coordinates) {
                      return Text("${room.distanceFrom(Coordinates(coordinates.latitude, coordinates.longitude)).round()}m");
                    },
                    loading: () => Text(""),
                    error: (_, _) => Text(""),
                  )
                ]
              )
            )
          )
        );
      })
    );
  }
}