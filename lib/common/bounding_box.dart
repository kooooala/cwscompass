import 'dart:math';

class BoundingBox {
  final Point<double> topLeft;
  final Point<double> bottomRight;

  const BoundingBox(this.topLeft, this.bottomRight);

  factory BoundingBox.fromVertices(List<Point<double>> vertices) {
    final xList = vertices.map((v) => v.x), yList = vertices.map((v) => v.y);
    final topLeft = Point(xList.reduce(min), yList.reduce(min));
    final bottomRight = Point(xList.reduce(max), yList.reduce(max));
    return BoundingBox(topLeft, bottomRight);
  }
}