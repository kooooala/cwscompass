import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/school.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class Marker extends ConsumerWidget {
  final double size;

  final School school;

  const Marker(this.size, this.school, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    return location.when(
      data: (coordinates) {
        // TODO: Implement pathfinding across floors
        final closest = school.closestNode(coordinates);
        print("Closest node: ${closest.latitude}, ${closest.longitude}");
        final point = coordinates.point;
        return Stack(children: [
          Positioned(top: point.y - size / 2, left: point.x - size / 2, child: Icon(Icons.circle_rounded, color: Colors.blue, size: size,))
        ]);
      },
      loading: () => const SizedBox.shrink(),
      error: (object, stack) => const SizedBox.shrink(),
    );
  }
}