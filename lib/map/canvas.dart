import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/labelPainter.dart';
import 'package:cwscompass/map/marker.dart';
import 'package:cwscompass/map/roomPainter.dart';
import 'package:cwscompass/map_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapCanvas extends ConsumerWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.read(mapDataProvider);

    return Center(
      child: mapData.when(
        data: (data) =>
            InteractiveViewer(
              minScale: 0.1,
              maxScale: 64,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment(0.8, 1),
                    colors: <Color>[
                      Color(0xfff9f9f9),
                      Color(0xffd4dad6),
                      Color(0xffafbbb6),
                      Color(0xff8b9d9b),
                      Color(0xff698083),
                      Color(0xff49636f),
                      Color(0xff2c475c),
                      Color(0xff142b4e),
                    ], // Gradient from https://learnui.design/tools/gradient-generator.html
                    tileMode: TileMode.mirror,
                  ),
                ),
                child: SizedBox(
                    width: 512,
                    height: 512,
                    child: Stack(
                        children: <Widget>[
                          RepaintBoundary(
                            child: CustomPaint(painter: RoomPainter(data)),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(painter: LabelPainter(data)),
                          ),
                          Marker(2)
                        ]
                    )
                ),
              ),
            ),
        loading: () => CircularProgressIndicator(),
        error: (err, stack) => Text("Oops: $err"),
      ),
    );
  }
}