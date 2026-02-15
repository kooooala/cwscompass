import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/map/school.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/widgets/floor_selector.dart';
import 'package:cwscompass/widgets/rounded_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

Widget turnToIcon(Turn turn, Color colour, double size) {
  final icon = switch (turn) {
    Turn.left => PhosphorIconsBold.arrowBendUpLeft,
    Turn.right => PhosphorIconsBold.arrowBendUpRight,
    Turn.straight => PhosphorIconsBold.arrowUp,
    Turn.enterBuilding => PhosphorIconsBold.signIn,
    Turn.exitBuilding => PhosphorIconsBold.signOut,
    Turn.destination => Icons.location_on_rounded,
    Turn.stairsUp || Turn.stairsDown => PhosphorIconsBold.steps,
  };

  return Stack(
    children: [
      PhosphorIcon(
        icon,
        color: colour,
        size: size,
      )
    ],
  );
}

String directionToString(Direction direction, String destName) {
  String string = switch (direction.turn) {
    Turn.left => "Turn left",
    Turn.right => "Turn right",
    Turn.straight => "Continue straight",
    Turn.enterBuilding => "Enter ${(direction.coordinates as BuildingEntrance).building.name}",
    Turn.exitBuilding => "Exit ${(direction.coordinates as BuildingEntrance).building.name}",
    Turn.destination => destName.capitalise(),
    Turn.stairsDown => "Go downstairs to ${floorToString(direction.coordinates.floor)}/F",
    Turn.stairsUp => "Go upstairs to ${floorToString(direction.coordinates.floor)}/F",
  };

  if (direction.label != null) {
    final label = direction.label!.capitalise();
    switch (direction.turn) {
      case Turn.left || Turn.right:
        string += "onto $label";
        break;
      case Turn.straight:
        string += "on $label";
        break;
      default:
        break;
    }
  }

  return string;
}

class DirectionSheet extends StatelessWidget {
  final List<Direction> directions;
  final Interactable endRoom;

  const DirectionSheet({super.key, required this.directions, required this.endRoom});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final maxSize = (height - MediaQuery.paddingOf(context).top) / height;

    return SheetViewport(
        child: Sheet(
            decoration: MaterialSheetDecoration(
                size: SheetSize.stretch,
                color: ThemeColours.primary,
                borderRadius: BorderRadius.circular(24.0),
                shadowColor: Colors.black
            ),
            scrollConfiguration: SheetScrollConfiguration(),
            initialOffset: SheetOffset(0.3),
            snapGrid: MultiSnapGrid(
                snaps: [SheetOffset(0.3), SheetOffset(maxSize)]
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
                },
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                        spacing: 8.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Directions",
                              style: TextStyle(
                                  color: ThemeColours.lightText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28.0
                              )
                          ),
                          directions.isNotEmpty
                              ? NextDirectionCard(direction: directions.first, endRoom: endRoom,)
                              : SizedBox.shrink(),
                          Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: directions.length > 1
                                ? DirectionList(directions: directions, endRoom: endRoom,)
                                : SizedBox.shrink()
                          )
                        ]
                    )
                )
            )
        )
    );
  }
}

class NextDirectionCard extends ConsumerWidget {
  final Direction direction;
  final Interactable endRoom;

  const NextDirectionCard({super.key, required this.direction, required this.endRoom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      borderRadius: BorderRadius.circular(16.0),
      color: Colors.white,
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            spacing: 16.0,
            children: [
              Material(
                borderRadius: BorderRadius.circular(12.0),
                elevation: 4,
                color: ThemeColours.accent,
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: turnToIcon(direction.turn, ThemeColours.lightText, 28.0)
                ),
              ),
              Text(
                directionToString(direction, endRoom.name),
                style: TextStyle(
                    color: ThemeColours.darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 24.0
                ),
              ),
              Spacer(),
              Text(
                "${direction.distance.round()}m",
                style: TextStyle(
                    color: ThemeColours.darkTextTint,
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0
                ),
              )
            ],
          )
      ),
    );
  }
}

class DirectionList extends StatelessWidget {
  final List<Direction> directions;
  final Interactable endRoom;

  const DirectionList({super.key, required this.directions, required this.endRoom});

  @override
  Widget build(BuildContext context) {
    return RoundedList(
      radius: 16.0,
      children: List<Widget>.generate(
        directions.length - 1,
        (i) {
          final direction = directions[i + 1];

          double distance = 0;
          for (int j = 0; j <= i + 1; j++) {
            distance += directions[j].distance;
          }

          return Material(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                spacing: 8.0,
                children: [
                  turnToIcon(direction.turn, ThemeColours.accent, 16.0),
                  Text(
                    directionToString(direction, endRoom.name),
                    style: TextStyle(
                        color: ThemeColours.darkTextTint,
                        fontSize: 16.0
                    ),
                  ),
                  Spacer(),
                  Text(
                      "${distance.round()}m",
                      style: TextStyle(
                        color: ThemeColours.darkTextTint,
                        fontSize: 16.0,
                      )
                  )
                ],
              )
            ),
          );
        }
      )
    );
  }
}