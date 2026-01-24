import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  debugPaintSizeEnabled = false;

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget { 
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.familjenGroteskTextTheme()
      ),
      home: const MyHomePage(title: "Flutter Demo Home Page"),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Builder(
        builder: (context) =>
          Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    MapCanvas(
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height,
                      onRoomTap: (room) {
                        Scaffold.of(context).showBottomSheet((context) =>
                          TapRegion(
                            onTapOutside: (_) => Navigator.of(context).pop(),
                            child: Container(
                              height: 400,
                              width: double.infinity,
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${room.subject} room ${room.number}",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary
                                    )
                                  )
                                ]
                              )
                            )
                          )
                        );
                      },
                    )
                  ]
                )
              ),
              FakeSearchBar(),
            ]
          )
      ),
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