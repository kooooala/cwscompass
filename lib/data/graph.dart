import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/edge.dart';

class Graph {
  final Map<Coordinates, List<EdgeWithLabel>> simplified;
  final Map<Coordinates, Edge> intermediateNodeEdge;

  Graph(this.simplified, this.intermediateNodeEdge);
}