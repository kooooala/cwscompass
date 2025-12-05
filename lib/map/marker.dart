import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class Marker extends ConsumerWidget {
  final double size;

  const Marker(this.size, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    return location.when(
      data: (position) {
        print("Marker updated");
        final point = Coordinates(position.latitude, position.longitude).toPoint();
        final accuracy = position.accuracy;
        return Stack(children: [
          Positioned(top: point.y - size / 2, left: point.x - size / 2, child: Icon(Icons.circle_rounded, color: Colors.blue, size: size,))
        ]);
      },
      loading: () => const SizedBox.shrink(),
      error: (object, stack) => const SizedBox.shrink(),
    );
  }
}