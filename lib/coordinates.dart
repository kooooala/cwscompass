import 'dart:math';

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates(this.latitude, this.longitude);

  Point<double> toPoint() => Point<double>(longitude, latitude);
}