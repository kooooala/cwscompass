import 'package:cwscompass/map/canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_data.dart';

void main() async {
  debugPaintSizeEnabled = false;

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget { 
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
    final data = ref.watch(mapDataProvider);

    return Scaffold(
      body: Builder(
        builder: (context) => //SafeArea(
          //child:
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                data.when(
                  data: (_) => MapCanvas(
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
                                Text("${room.subject} room ${room.number}", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                              ]
                            )
                          )
                        )
                      );
                    },
                  ),
                  loading: () => CircularProgressIndicator(),
                  error: (err, stack) => Text("Oops: $err"),
                )
              ]
            )
          )
        //)
      )
    );
  }
}