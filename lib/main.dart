import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_data.dart';

void main() async {
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
                data: (mapData) => Expanded(child: ListView.builder(
                  itemCount: mapData.rooms.length,
                  itemBuilder: (BuildContext context, int index) {
                    final colour = mapData.rooms[index].colour;
                    return ListTile(
                      tileColor: Color.fromARGB(0xFF, colour >> 16, (colour >> 8) & 0xFF, colour & 0xFF),
                      title: Text("${mapData.rooms[index].number} ${mapData.rooms[index].subject}"),
                    );
                  },
                )),
                loading: () => CircularProgressIndicator(),
                error: (err, stack) => Text("Oops: $err"),
              )
            ]
          )
        )
    );
  }
}