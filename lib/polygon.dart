import 'dart:math';

import 'package:cwscompass/common/bounding_box.dart';
import 'package:cwscompass/coordinates.dart';

class Polygon {
  final List<Coordinates> coordinates;
  final BoundingBox boundingBox;

  Polygon(this.coordinates) : boundingBox = BoundingBox.fromVertices(coordinates.map((c) => c.point).toList());
}