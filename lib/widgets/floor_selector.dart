import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FloorSelector extends ConsumerStatefulWidget {
  final bool locationChangeable;

  const FloorSelector({super.key, this.locationChangeable = true});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FloorSelectorState();
}

class _FloorSelectorState extends ConsumerState<FloorSelector> {
  @override
  Widget build(BuildContext context) {
    return ref.watch(selectedFloorProvider).when(
      data: (selected) {
        return Material(
          borderRadius: BorderRadius.circular(28.0),
          elevation: 4,
          color: ThemeColours.accent,
          child: Padding(
            padding: EdgeInsets.all(6.0),
            child: Column(
              spacing: 8.0,
              children: List.generate(selected.floorCount, (i) {
                final floor = selected.floorCount - 1 - i;
                final text = floor == 0 ? "G" : floor.toString();
                final textWidget = Text(
                  text,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                    color: floor == selected.viewFloor ? ThemeColours.accent : Colors.white
                  )
                );

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedFloorProvider.notifier).setView(floor);
                    if (widget.locationChangeable) {
                      ref.read(selectedFloorProvider.notifier).setLocation(floor);
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 150),
                    child: Container(
                      key: ValueKey((floor == selected.viewFloor, floor)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: floor == selected.viewFloor ? Colors.white : ThemeColours.accent
                      ),
                      width: 36.0,
                      height: 36.0,
                      child: Center(
                        child: textWidget
                      )
                    )
                  )
                );
              }),
            )
          ),
        );
      },
      loading: () => SizedBox.shrink(),
      error: (err, stack) => Text("Oops: $err"),
    );
  }
}