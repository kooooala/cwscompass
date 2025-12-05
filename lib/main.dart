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
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              data.when(
                data: (_) => MapCanvas(),
                loading: () => CircularProgressIndicator(),
                error: (err, stack) => Text("Oops: $err"),
              )
            ]
          )
        )
    );
  }
}