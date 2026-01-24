import 'package:cwscompass/common/maths.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/map_data.dart';
import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/widgets/rounded_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import '../location.dart';
import '../theme_colours.dart';

class SearchPage extends ConsumerWidget {
  final controller = SearchController();

  final ValueNotifier<List<Room>> searchResults = ValueNotifier<List<Room>>([]);

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
                            RoomList(rooms: value.isNotEmpty ? value : data.school.rooms)
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

class RoomList extends ConsumerWidget {
  final List<Room> rooms;

  const RoomList({super.key, required this.rooms});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    return RoundedList(
      radius: 12.0,
      children: List<Widget>.generate(rooms.length, (i) {
        final room = rooms[i];
        return Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8.0,
              children: [
                Text(
                  "Room ${room.number}",
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
                    return Text("${haversineDistance(Coordinates(coordinates.latitude, coordinates.longitude), pointToCoordinates(room.centroid)).round()}m");
                  },
                  loading: () => Text(""),
                  error: (_, _) => Text(""),
                )
              ]
            )
          )
        );
      })
    );
  }
}