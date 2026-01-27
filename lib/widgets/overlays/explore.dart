import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/info_sheet.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:flutter/material.dart';

class ExploreOverlay extends StatelessWidget {
  final ValueNotifier<Room?> selectedRoom;

  const ExploreOverlay({super.key, required this.selectedRoom});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FakeSearchBar(),
        InfoSheet(selectedRoom: selectedRoom)
      ],
    );
  }
}

class FakeSearchBar extends StatelessWidget {
  const FakeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: MediaQuery.paddingOf(context).top + 16.0, horizontal: 28.0),
        child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => SearchPage())),
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