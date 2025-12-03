import 'dart:math';

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates(this.latitude, this.longitude);

  Point<double> toPoint() {
    final topLeft = Point<double>(-1.79278594, 51.55157938);
    final bottomRight = Point<double>(-1.78508911, 51.54750466);

    final canvasSize = 512;

    final width = bottomRight.x - topLeft.x;
    final height = topLeft.y - bottomRight.y;

    final dx = (longitude - topLeft.x) / width * canvasSize;
    final dy = ((1 - (latitude - bottomRight.y) / height) * canvasSize); // with latitude, positive = up

    return Point<double>(dx, dy);
  }
}