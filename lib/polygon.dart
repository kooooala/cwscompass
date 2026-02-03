import 'dart:math';

import 'package:cwscompass/common/bounding_box.dart';

class Polygon {
  final List<Point<double>> vertices;
  final BoundingBox boundingBox;

  Polygon(this.vertices) : boundingBox = BoundingBox.fromVertices(vertices);
}