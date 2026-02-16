import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/location.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/rounded_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InteractableList extends ConsumerWidget {
  final List<Interactable> interactables;

  final void Function(Interactable interactable) onTap;

  const InteractableList({super.key, required this.interactables, this.onTap = defaultRoomTap});

  static void defaultRoomTap(Interactable room) {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final length = interactables.isEmpty ? 5 : interactables.length;

    return RoundedList(
      radius: 12.0,
      children: List<Widget>.generate(length, (i) {
        final interactable = interactables.isNotEmpty ? interactables[i] : null;
        return GestureDetector(
          onTap: () {
            if (interactables.isNotEmpty) {
              onTap(interactable!);
            }
          },
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
                    interactables.isEmpty ? "Loading..." : interactable!.name.capitalise(),
                    style: TextStyle(
                        color: ThemeColours.darkText,
                        fontSize: 18.0
                    )
                  ),
                  Text(
                    interactables.isEmpty ? "" : interactable!.shortDescription.capitalise(),
                    style: TextStyle(
                        color: ThemeColours.darkTextTint,
                        fontSize: 14.0
                    )
                  ),
                  Spacer(),
                  location.when<Widget>(
                    data: (coordinates) {
                      if (interactables.isNotEmpty) {
                        return Text("${interactable!.distanceFrom(Coordinates(0, coordinates.latitude, coordinates.longitude)).round()}m");
                      } else {
                        return Text("");
                      }
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