import 'dart:math';

import 'package:cwscompass/common/bounding_box.dart';
import 'package:cwscompass/data/coordinates.dart';

class Polygon {
  final List<Coordinates> coordinates;
  final BoundingBox boundingBox;

  Polygon(this.coordinates) : boundingBox = BoundingBox.fromVertices(coordinates.map((c) => c.point).toList());

  // Check if point is inside polygon by using the ray casting algorithm: https://people.utm.my/shahabuddin/?p=6277
  bool intersects(Point<double> point) {
    // Quickly check if point is within bounding box
    if (!boundingBox.contains(point)) {
      return false;
    }

    int intersections = 0;

    for (int i = 0; i < coordinates.length; i++) {
      final current = coordinates[i].point;
      final next = coordinates[(i + 1) % coordinates.length].point;

      // Check if point is between current and next vertically
      if ((current.y > point.y) == (next.y > point.y)) {
        continue;
      }

      // Since we know point is between current and next vertically, we can now linearly interpolate
      // x from y
      final x = current.x + (next.x - current.x) * (point.y - current.y) / (next.y - current.y);
      if (point.x < x) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }
}