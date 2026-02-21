import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/staircase.dart';

class Edge {
  final List<Coordinates> coordinates;
  late final double distance;

  Edge(this.coordinates) {
    distance = calculateDistance();
  }

  double calculateDistance() {
    double result = 0;
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

class EdgeWithLabel extends Edge {
  final String? label;

  EdgeWithLabel(super.coordinates, this.label);
}