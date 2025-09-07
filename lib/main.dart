import 'package:flutter/material.dart';
import 'dart:math' as math;

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
              onTapDown: (TapDownDetails details) {
                if (rect.contains(details.localPosition)) {
                  setState(() {
                    color = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
                  });
                  print("Rectangle tapped");
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
