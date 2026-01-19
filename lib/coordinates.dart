import 'package:equatable/equatable.dart';
import 'dart:math';

class Coordinates extends Equatable {
  // TODO: Implement floors

  final double latitude;
  final double longitude;

  const Coordinates(this.latitude, this.longitude);

  @override
  List<Object> get props => [latitude, longitude];

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