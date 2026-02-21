import 'dart:math';
import 'dart:ui';

import 'package:cwscompass/common/bounding_box.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/common/polygon.dart';

/// Computes the area of a polygon using the shoelace formula.
double polygonArea(Polygon polygon) {
  final vertices = polygon.coordinates.map((c) => c.point).toList();
  double sum = 0;
  for (var i = 0; i < vertices.length; i++) {
    sum += vertices[i].x * vertices[(i + 1) % vertices.length].y - vertices[(i + 1) % vertices.length].x * vertices[i].y;
  }
  final area = sum / 2;
  return area;
}

/// Computes the geometric centre of a polygon (centroid) by dividing the polygon into triangles, using the formula found at https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
Point<double> centroid(Polygon polygon) {
  final area = polygonArea(polygon);
  double x = 0, y = 0;

  final vertices = polygon.coordinates.map((c) => c.point).toList();
  for (var i = 0; i < vertices.length; i++) {
    final current = vertices[i], next = vertices[(i + 1) % vertices.length];
    x += (current.x + next.x) * (current.x * next.y - next.x * current.y);
    y += (current.y + next.y) * (current.x * next.y - next.x * current.y);
  }
  x /= 6 * area;
  y /= 6 * area;

  return Point<double>(x, y);
}

/// Computes the arithmetic mean of the vertices of [polygon]
Point<double> average(Polygon polygon) {
  final xMean = polygon.coordinates.map((v) => v.point.x).reduce((a, b) => a + b) / polygon.coordinates.length;
  final yMean = polygon.coordinates.map((v) => v.point.y).reduce((a, b) => a + b) / polygon.coordinates.length;
  return Point(xMean, yMean);
}

/// Computes the contrast ratio between [c1] and [c2] using WCAG's contrast ratio guidelines: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html#key-terms
double contrastRatio(Color c1, Color c2) {
  return (c1.computeLuminance() + 0.05) / (c2.computeLuminance() + 0.05);
}

const int earthRadius = 6_378_137; // in metres

/// Computes the distance between two coordinates
/// This is more precise than fastDistance() (which uses equirectangular
/// distance) but is also more computationally expensive
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
double fastDistance(Coordinates c1, Coordinates c2) {
  // Formula also from https://www.movable-type.co.uk/scripts/latlong.html with
  final meanLat = (c1.latitude + c2.latitude) * pi / 180 / 2;
  final x = (c2.longitude - c1.longitude) * pi / 180 * cos(meanLat);
  final y = (c2.latitude - c1.latitude) * pi / 180;
  return earthRadius * sqrt(pow(x, 2) + pow(y, 2));
}

double pythagoras(Point p1, Point p2) {
  return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

Point<double> epsg4326To3857(double latitude, double longitude) {
  // Formula from https://developers.auravant.com/en/blog/2022/09/09/post-3/. The 20037508.34 used in the article is the same as pi * radius of earth
  double x = longitude * pi / 180 * earthRadius;
  double y = log(tan(((90 + latitude) * pi) / 360)) / (pi / 180);
  y = y * pi / 180 * earthRadius;

  return Point(x, y);
}

Coordinates epsg3857To4326(double latitude, double longitude, int floor) {
  double x = (longitude * 180) / (pi * earthRadius);
  double y = (latitude * 180) / (pi * earthRadius);
  y = atan(pow(e, y * pi / 180)) * 360 / pi - 90;
  return Coordinates(floor, y, x);
}

const double topLeftLat = 51.552167, topLeftLong = -1.791815;
const double bottomRightLat = 51.548247, bottomRightLong = -1.786249;

BoundingBox canvasBounds = BoundingBox(
  Coordinates(0, topLeftLat, topLeftLong).point,
  Coordinates(0, bottomRightLat, bottomRightLong).point
);

const canvasSize = 512;

Point<double> coordinatesToPoint(double latitude, double longitude) {
  final topLeft = epsg4326To3857(topLeftLat, topLeftLong);
  final bottomRight = epsg4326To3857(bottomRightLat, bottomRightLong);

  final width = bottomRight.x - topLeft.x;
  final height = topLeft.y - bottomRight.y;

  final maxAxis = max(width, height);

  final epsg3857 = epsg4326To3857(latitude, longitude);

  final dx = (epsg3857.x - topLeft.x) / maxAxis * canvasSize;
  final dy = ((1 - (epsg3857.y - bottomRight.y) / maxAxis) * canvasSize); // with latitude, positive = up

  return Point<double>(dx, dy);
}

Coordinates pointToCoordinates(Point<double> point, int floor) {
  final topLeft = epsg4326To3857(topLeftLat, topLeftLong);
  final bottomRight = epsg4326To3857(bottomRightLat, bottomRightLong);

  final width = bottomRight.x - topLeft.x;
  final height = topLeft.y - bottomRight.y;
  final maxAxis = max(width, height);

  final dx = (point.x * maxAxis / canvasSize) + topLeft.x;
  final dy = (1 - (point.y / canvasSize)) * maxAxis + bottomRight.y;

  return epsg3857To4326(dy, dx, floor);
}

double computeZoomScale(Polygon polygon, double width, double height) {
  final topLeft = polygon.boundingBox.topLeft, bottomRight = polygon.boundingBox.bottomRight;

  final xScale = width / (bottomRight.x - topLeft.x);
  final yScale = height / (bottomRight.y - topLeft.y);

  final scale = xScale > yScale ? yScale : xScale;
  return scale * 0.5;
}