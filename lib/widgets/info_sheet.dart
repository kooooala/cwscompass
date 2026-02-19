import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/loading.dart';
import 'package:cwscompass/data/location.dart';
import 'package:cwscompass/widgets/map/canvas.dart';
import 'package:cwscompass/data/map_data.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/widgets/pages/explore.dart';
import 'package:cwscompass/widgets/pages/route_preview.dart';
import 'package:cwscompass/widgets/room_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class InfoSheet extends ConsumerStatefulWidget {
  const InfoSheet({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => InfoSheetState();
}

class InfoSheetState extends ConsumerState<InfoSheet> {
  final SheetController controller = SheetController();

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

  void onRoomSelect(Interactable? previous, Interactable? next) {
    final newSize = next == null ? nearbySize : minSize;
    animateSizeChange(newSize);
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

    ref.listen<Interactable?>(selectedRoomProvider, onRoomSelect);

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
                content = InteractableInfo(
                  interactable: selectedRoom,
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

class InteractableInfo extends StatelessWidget {
  final Interactable interactable;

  const InteractableInfo({super.key, required this.interactable});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                  interactable.name.capitalise(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: ThemeColours.lightText,
                      fontWeight: FontWeight.w900,
                      fontSize: 28.0
                  )
              )
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => RoutePreview(initialEnd: interactable,)));
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
                  "Directions",
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              icon: PhosphorIcon(PhosphorIconsBold.arrowBendUpRight),
            )
          ],
        ),
        Text(
          interactable.description.capitalise(),
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
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: ref.watch(nearbyRoomsProvider).when(
            data: (nearbyRooms) => InteractableList(
              key: ValueKey(nearbyRooms[0].floor),
              onTap: (room) {
                ref.read(selectedRoomProvider.notifier).set(room);
              },
              interactables: nearbyRooms,
            ),
            loading: () => InteractableList(
              key: ValueKey(0),
              interactables: [],
            ),
            error: (err, stack) => Text("Oops: $err")
          )
        )
      ],
    );
  }
}