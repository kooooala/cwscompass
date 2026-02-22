import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/direction.dart';
import 'package:cwscompass/data/staircase.dart';

// A path (list of coordinates) with its distance
class Edge {
  final List<Coordinates> coordinates;
  late final double distance;

  Edge(this.coordinates) {
    // Distance is calculated when the object is instantiated
    distance = calculateDistance();
  }

  double calculateDistance() {
    double result = 0;
    // Iterate through each path segment and add up their distances
    for (int i = 0; i < coordinates.length - 1; i++) {
      if (coordinates[i] == coordinates[i + 1]) {
        continue;
      }

      if (coordinates[i].floor != coordinates[i + 1].floor) {
        result += Staircase.cost;
      }
      result += maths.fastDistance(coordinates[i], coordinates[i + 1]);
    }
    return result;
  }
}

// This is separated out since edge is also used by the route object which doesn't have a name/label
class EdgeWithLabel extends Edge {
  final String? label;

  EdgeWithLabel(super.coordinates, this.label);
}