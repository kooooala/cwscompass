import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/data/map_data.dart';
import 'package:cwscompass/widgets/overlays/explore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  debugPaintSizeEnabled = false;
  debugRepaintRainbowEnabled = false;

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CWS Compass',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme()
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  MyHomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  late final MapCanvasController canvasController;

  @override
  void initState() {
    super.initState();
    canvasController = MapCanvasController(
      focusOnTap: true,
      focusOnRoomSelect: true,
      roomSelectable: true,
      transformationController: ref.read(transformationControllerProvider)
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false ,
        onPopInvokedWithResult: (_, _) {
          // Unselect room with back button
          if (ref.read(selectedRoomProvider) != null) {
            ref.read(selectedRoomProvider.notifier).set(null);
          }
        },
        child: Scaffold(
          body: Builder(
            builder: (context) => ExploreOverlay()
          ),
        )
    );
  }
}
