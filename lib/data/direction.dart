import 'package:cwscompass/data/coordinates.dart';

enum Turn {
  left, right, straight, enterBuilding, exitBuilding, destination, stairsUp, stairsDown
}

class Direction {
  final Turn turn;
  final String? label;
  final Coordinates coordinates;

  double distance;

  Direction(this.turn, this.label, this.coordinates, this.distance);
}