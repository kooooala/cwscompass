import 'dart:math';

import 'package:cwscompass/common/polygon.dart';

enum ZoomFocus {
  centroid,
  average
}

abstract class FocusRequest {}

class PolygonFocus extends FocusRequest {
  final Polygon polygon;
  final ZoomFocus zoomFocus;

  PolygonFocus(this.polygon, this.zoomFocus);
}

class PointFocus extends FocusRequest {
  final Point<double> focus;
  final double scale;

  PointFocus(this.focus, this.scale);
}
