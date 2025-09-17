import 'package:cwscompass/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'map_canvas.dart';

void main() {
  runApp(const MyApp());
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  final Rect rect = Offset(50, 50) & Size(150, 150);
  Color color = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<Database> openDatabaseFromAssets() async {
    final directory = await getTemporaryDirectory();
    final path = join(directory.path, "map.db");

    final data = await rootBundle.load("assets/map.db");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(path).writeAsBytes(bytes, flush:true);

    return await openDatabase(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              child: CustomPaint(
                painter: MapCanvas(rect, color),
                size: Size(480, 720),
              ),
              onTapDown: (TapDownDetails details) async {
                if (rect.contains(details.localPosition)) {
                  setState(() {
                    color = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
                  });
                  print("Rectangle tapped");
                  final db = await openDatabaseFromAssets();
                  final room = await Room.fromRoomId(db, 1391733255107376182);
                  print(room);
                }
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
