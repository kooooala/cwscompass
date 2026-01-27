import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/theme_colours.dart';
import 'package:cwscompass/widgets/info_sheet.dart';
import 'package:cwscompass/widgets/overlays/explore.dart';
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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  final selectedRoom = ValueNotifier<Room?>(null);

  MyHomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false ,
      onPopInvokedWithResult: (_, _) {
        // Unselect room with back button
        if (selectedRoom.value != null) {
          selectedRoom.value = null;
        }
      },
      child: Scaffold(
        body: Builder(
          builder: (context) =>
            Stack(children: [
              Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  MapCanvas(
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height,
                    focusOnTap: true,
                    onRoomTap: (room) => selectedRoom.value = room,
                    onBlankTap: () => selectedRoom.value = null,
                  )
                ]
                )
              ),
              ExploreOverlay(selectedRoom: selectedRoom)
            ]),
        ),
      )
    );
  }
}

