import 'package:cwscompass/widgets/map/canvas.dart';
import 'package:cwscompass/widgets/pages/explore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  debugPaintSizeEnabled = false;
  debugRepaintRainbowEnabled = false;

  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CWS Compass',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.nunitoTextTheme()
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
          builder: (context) => Explore()
        ),
      )
    );
  }
}
