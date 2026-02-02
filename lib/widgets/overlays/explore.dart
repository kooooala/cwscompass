import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/info_sheet.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedRoomProvider = NotifierProvider<SelectedRoomNotifier, Room?>(SelectedRoomNotifier.new);

class SelectedRoomNotifier extends Notifier<Room?> {
  @override
  Room? build() {
    // Initial value
    return null;
  }

  void set(Room? room) {
    state = room;
  }
}

class ExploreOverlay extends StatelessWidget {
  const ExploreOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FakeSearchBar(),
        InfoSheet()
      ],
    );
  }
}

class FakeSearchBar extends ConsumerWidget {
  const FakeSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.paddingOf(context).top + 16.0, horizontal: 28.0),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.of(context).push<Room?>(MaterialPageRoute(builder: (context) => SearchPage()));

          if (result != null) {
            ref.read(selectedRoomProvider.notifier).set(result);
          }
        },
        child: Hero(
          tag: "search-bar",
          child: Material(
            elevation: 4,
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 32.0,
                      color: ThemeColours.primary
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(
                      Icons.search_rounded,
                      size: 32.0,
                      color: ThemeColours.primary
                    ),
                  ),
                ]
              ),
            )
          )
        )
      )
    );
  }
}