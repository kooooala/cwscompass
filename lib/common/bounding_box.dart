import 'dart:math';

class BoundingBox {
  final Point<double> topLeft;
  final Point<double> bottomRight;

  const BoundingBox(this.topLeft, this.bottomRight);

  factory BoundingBox.fromVertices(List<Point<double>> vertices) {
    final xList = vertices.map((v) => v.x), yList = vertices.map((v) => v.y);
    // Get top left corner by getting the combining the minimum x and minimum y
    final topLeft = Point(xList.reduce(min), yList.reduce(min));
    // Get bottom right corner by getting the combining the maximum x and maximum y
    final bottomRight = Point(xList.reduce(max), yList.reduce(max));
    return BoundingBox(topLeft, bottomRight);
  }

  bool contains(Point<double> point) {
    return point.x > topLeft.x && point.x < bottomRight.x &&
        point.y > topLeft.y && point.y < bottomRight.y;
  }
}