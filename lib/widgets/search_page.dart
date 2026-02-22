import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/loading.dart';
import 'package:cwscompass/data/location.dart';
import 'package:cwscompass/widgets/map/canvas.dart';
import 'package:cwscompass/data/map_data.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/widgets/room_list.dart';
import 'package:cwscompass/widgets/rounded_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

abstract class SearchResult {}

class SearchResultNone extends SearchResult {}
class SearchResultDeviceLocation extends SearchResult {}
class SearchResultInteractable extends SearchResult {
  final Interactable interactable;

  SearchResultInteractable(this.interactable);
}

class SearchPage extends ConsumerWidget {
  final searchResults = ValueNotifier<List<Interactable>>([]);
  final bool myLocationSelectable;

  SearchPage({super.key, this.myLocationSelectable = false});

  void search(String query, Iterable<Interactable> interactables) async {
    final roomEntries = Map.fromEntries(interactables.map((i) => i.searchEntry));
    final results = extractAllSorted(
      query: query,
      choices: roomEntries.keys.toList(),
      cutoff: 60,
    );

    searchResults.value = results.map((key) => roomEntries[key.choice]! as Interactable).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.watch(mapDataProvider);

    Widget myLocationButton;
    if (myLocationSelectable) {
      myLocationButton = Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop<SearchResult>(SearchResultDeviceLocation()),
          child: RoundedList(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                color: Colors.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.my_location,
                        size: 16.0,
                        color: ThemeColours.primary,
                      )
                    ),
                    Text(
                      "My location",
                      style: TextStyle(
                        color: ThemeColours.darkText,
                        fontSize: 18.0
                      ),
                    )
                  ],
                )
              )
            ]
          ),
        )
      );
    } else {
      myLocationButton = SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: ThemeColours.secondary,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: mapData.when(
          data: (data) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 16.0),
                  child: Hero(
                    tag: "search-bar",
                    child: SearchBar(
                      autoFocus: true,
                      leading: GestureDetector(
                        onTap: () => Navigator.of(context).pop<SearchResult>(SearchResultNone()),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 32.0,
                          color: ThemeColours.primary
                        )
                      ),
                      trailing: [
                        Icon(
                          Icons.search_rounded,
                          size: 32.0,
                          color: ThemeColours.primary)
                      ],
                      onChanged: (value) => search(value, data.school.floors.map((f) => f.structures.whereType<Interactable>().toList()).reduce((a, b) => a + b)),
                      backgroundColor: WidgetStateProperty.resolveWith((_) => Colors.white),
                      padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 12.0)),
                    )
                  )
                ),
                myLocationButton,
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: searchResults,
                    builder: (context, value, _) => AnimatedSwitcher(
                      duration: Duration(milliseconds: 150),
                      child: ListView(
                        key: ValueKey(value),
                        padding: EdgeInsets.zero,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              value.isNotEmpty ? "Results" : "Nearby",
                              style: TextStyle(
                                color: ThemeColours.lightText,
                                fontWeight: FontWeight.w800,
                                fontSize: 24.0
                              )
                            )
                          ),
                          ref.watch(nearbyInteractablesProvider).when(
                            data: (nearbyRooms) => InteractableList(
                              interactables: value.isNotEmpty ? value : nearbyRooms,
                              onTap: (room) => Navigator.of(context).pop<SearchResult>(SearchResultInteractable(room)),
                            ),
                            loading: () => Loading(colour: Colors.white),
                            error: (err, stack) => Text("Oops: $err"),
                          )
                        ]
                      )
                    )
                  )
                )
              ]
            );
          },
          loading: () => Loading(colour: Colors.white),
          error: (err, stack) => Text("Oops: $err")
        )
      )
    );
  }
}