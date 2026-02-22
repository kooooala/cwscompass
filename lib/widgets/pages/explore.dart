import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/map/canvas.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/widgets/floor_selector.dart';
import 'package:cwscompass/widgets/info_sheet.dart';
import 'package:cwscompass/widgets/map/selected_floor.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedRoomProvider = NotifierProvider<SelectedRoomNotifier, Interactable?>(SelectedRoomNotifier.new);

class SelectedRoomNotifier extends Notifier<Interactable?> {
  @override
  Interactable? build() {
    // Initial value
    return null;
  }

  void set(Interactable? room) {
    state = room;

    if (room != null) {
      ref.read(selectedFloorProvider.notifier).setView(room.floor);
    }
  }
}

class Explore extends ConsumerWidget {
  const Explore({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasController = MapCanvasController(
        focusOnTap: true,
        focusOnRoomSelect: true,
        roomSelectable: true,
        transformationController: ref.read(transformationControllerProvider)
    );
    return Stack(
      children: [
        MapCanvas(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          controller: canvasController
        ),
        Column(
          children: [
            FakeSearchBar(),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 32.0, right: 28.0),
                child: FloorSelector()
              ),
            )
          ]
        ),
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
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 16.0, left: 28.0, right: 28.0),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.of(context).push<SearchResult>(MaterialPageRoute(builder: (context) => SearchPage()));
          if (result is SearchResultInteractable) {
            ref.read(selectedRoomProvider.notifier).set(result.interactable);
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