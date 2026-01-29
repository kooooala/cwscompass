import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/widgets/overlays/explore.dart';
import 'package:cwscompass/widgets/overlays/route_preview.dart';
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
      title: 'CWS Compass',
      theme: ThemeData(
        textTheme: GoogleFonts.familjenGroteskTextTheme()
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  late final MapCanvasController canvasController;

  MyHomePage({super.key}) {
    canvasController = MapCanvasController(
        focusOnTap: true,
        focusOnRoomSelect: true,
    );
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false ,
      onPopInvokedWithResult: (_, _) {
        // Unselect room with back button
        if (ref.watch(selectedRoomProvider) != null) {
          ref.read(selectedRoomProvider.notifier).set(null);
        }
      },
      child: Scaffold(
        body: Builder(
          builder: (context) =>
            Stack(children: [
              MapCanvas(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height,
                controller: canvasController
              ),
              ExploreOverlay(canvasController: canvasController)
            ]),
        ),
      )
    );
  }
}

