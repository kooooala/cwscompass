import 'dart:math';
import 'dart:ui';

import 'package:cwscompass/coordinates.dart';

/// Computes the area of a polygon using the shoelace formula.
double polygonArea(List<Point<double>> vertices) {
  double sum = 0;
  for (var i = 0; i < vertices.length; i++) {
    sum += vertices[i].x * vertices[(i + 1) % vertices.length].y - vertices[(i + 1) % vertices.length].x * vertices[i].y;
  }
  final area = sum / 2;
  return area;
}

/// Computes the geometric centre of a polygon (centroid) by dividing the polygon into triangles, using the formula found at https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
Point<double> centroid(List<Point<double>> vertices) {
  final area = polygonArea(vertices);
  double x = 0, y = 0;

  for (var i = 0; i < vertices.length; i++) {
    final current = vertices[i], next = vertices[(i + 1) % vertices.length];
    x += (current.x + next.x) * (current.x * next.y - next.x * current.y);
    y += (current.y + next.y) * (current.x * next.y - next.x * current.y);
  }
  x /= 6 * area;
  y /= 6 * area;

  return Point<double>(x, y);
}

/// Computes the contrast ratio between [c1] and [c2] using WCAG's contrast ratio guidelines: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html#key-terms
double contrastRatio(Color c1, Color c2) {
  return (c1.computeLuminance() + 0.05) / (c2.computeLuminance() + 0.05);
}

const int earthRadius = 6_371_000; // in metres

/// Computes the distance between two coordinates
double haversineDistance(Coordinates c1, Coordinates c2) {
  // Haversine formula from https://www.movable-type.co.uk/scripts/latlong.html
  final double phi1 = c1.latitude * pi / 180;
  final double phi2 = c2.latitude * pi / 180;
  final double phiDiff = (c2.latitude - c1.latitude) * pi / 180;
  final double lambdaDiff = (c2.longitude - c1.longitude) * pi / 180;

  final double a = pow(sin(phiDiff / 2), 2) + cos(phi1) * cos(phi2) * pow(sin(lambdaDiff / 2), 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

/// Computes an approximate of the distance between the two coordinates; only
/// suitable for short distances but much quicker
double equirectangularDistance(Coordinates c1, Coordinates c2) {
  // Formula also from https://www.movable-type.co.uk/scripts/latlong.html with
  //
  final meanLat = (c1.latitude + c2.latitude) * pi / 180 / 2;
  final x = (c2.longitude - c1.longitude) * pi / 180 * cos(meanLat);
  final y = (c2.latitude - c1.latitude) * pi / 180;
  return earthRadius * sqrt(pow(x, 2) + pow(y, 2));
}

double pythagoras(Point p1, Point p2) {
  return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

Point<double> coordinatesToPoint(double latitude, double longitude) {
  final topLeft = Point<double>(-1.79278594, 51.55157938);
  final bottomRight = Point<double>(-1.78508911, 51.54750466);

  final canvasSize = 512;

  final width = bottomRight.x - topLeft.x;
  final height = topLeft.y - bottomRight.y;

  final dx = (longitude - topLeft.x) / width * canvasSize;
  final dy = ((1 - (latitude - bottomRight.y) / height) * canvasSize); // with latitude, positive = up

  return Point<double>(dx, dy);
}