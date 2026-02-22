import 'package:cwscompass/data/coordinates.dart';

enum Turn {
  left, right, straight, enterBuilding, exitBuilding, destination, stairsUp, stairsDown
}

class Direction {
  final Turn turn;
  // Stores any text associated with the turn. At the moment this is only used for path names (when turn = left | right | straight), but it can be extended to support other information for other types of turns.
  final String? label;
  // The coordinates where this direction applies.
  final Coordinates coordinates;

  double distance;

  Direction(this.turn, this.label, this.coordinates, this.distance);
}