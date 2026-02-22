import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/edge.dart';

class Graph {
  final Map<Coordinates, List<EdgeWithLabel>> simplified;
  // A dictionary (map) that maps intermediate nodes (the ones that are simplified out from the graph) to the edge they belong to
  final Map<Coordinates, Edge> intermediateNodeEdge;

  Graph(this.simplified, this.intermediateNodeEdge);
}