import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/room_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

class SearchPage extends ConsumerWidget {
  final controller = SearchController();

  final searchResults = ValueNotifier<List<Room>>([]);

  SearchPage({super.key});

  void search(String query, List<Room> rooms) async {
    final roomEntries = Map.fromEntries(rooms.map((room) => room.searchEntry));
    final results = extractAll(
      query: query,
      choices: roomEntries.keys.toList(),
      cutoff: 50,
    );

    searchResults.value = results.map((key) => roomEntries[key.choice]!).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.watch(mapDataProvider);

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
              spacing: 16.0,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 16.0),
                  child: Hero(
                    tag: "search-bar",
                    child: SearchBar(
                      autoFocus: true,
                      leading: GestureDetector(
                        onTap: Navigator.of(context).pop,
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
                      onChanged: (value) => search(value, data.school.rooms),
                      backgroundColor: WidgetStateProperty.resolveWith((_) => Colors.white),
                      padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 12.0)),
                    )
                  )
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: searchResults,
                    builder: (context, value, _) {
                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 150),
                        child: ListView(
                          key: ValueKey(value),
                          padding: EdgeInsets.zero,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                value.isNotEmpty ? "Results" : "All rooms",
                                style: TextStyle(
                                  color: ThemeColours.lightText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24.0
                                )
                              )
                            ),
                            RoomList(
                              rooms: value.isNotEmpty ? value : data.school.rooms,
                              onRoomTap: (room) => Navigator.of(context).pop(room),
                            )
                          ]
                        )
                      );
                    }
                  )
                )
              ]
            );
          },
          loading: () => CircularProgressIndicator(),
          error: (err, stack) => Text("Oops: $err")
        )
      )
    );
  }
}