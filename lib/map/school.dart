import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/path.dart';
import 'package:cwscompass/common/maths.dart' as maths;

class Edge {
  final List<Coordinates> coordinates;
  late final double distance = calculateDistance();

  Edge(this.coordinates);

  double calculateDistance() {
    double result = 0;
    for (int i = 0; i < coordinates.length - 1; i++) {
      result += maths.coordinatesDistance(coordinates[i], coordinates[i + 1]);
    }
    return result;
  }
}

class School {
  final Map<Coordinates, List<Edge>> graph = {};
  final List<Room> rooms;

  School(this.rooms, List<Path> _paths) {
    Map<Coordinates, List<Coordinates>> fullGraph = {};

    for (final path in _paths) {
      for (final (i, vertex) in path.vertices.sublist(0, path.vertices.length - 1).indexed) {
        final next = path.vertices[i + 1];

        fullGraph[vertex] ??= <Coordinates>[];
        fullGraph[vertex]!.add(next);

        fullGraph[next] ??= <Coordinates>[];
        fullGraph[next]!.add(vertex);
      }
    }

    // Simplify the graph by 'collapsing' paths with no branches i.e. removing
    // intermediate nodes (nodes with degree 2)

    // Find a node with degree > 2 to use as the root node
    final root = fullGraph.keys.firstWhere((c) => fullGraph[c] != null && fullGraph[c]!.length > 2);

    final unvisited = <Coordinates>[];
    unvisited.addAll(fullGraph[root]!);
    final visited = <Coordinates>[root];

    Coordinates edgeStart = root;

    while (unvisited.isNotEmpty) {
      Coordinates current = unvisited.removeLast();
      if (visited.contains(current)) {
        continue;
      }
      visited.add(current);

      final children = fullGraph[current]!;
      List<Coordinates> edgeNodes = [edgeStart, current];

      // If the current node is not an intermediate or end node, save it and add
      // all its children to the stack
      if (children.length > 2) {
        edgeStart = current;
        unvisited.addAll(children);
      }

      // if the urrent node is an intermediate node, we want to traverse the
      // path until we find a non-intermediate node
      if (children.length == 2) {
        Coordinates next;
        do {
          next = fullGraph[current]!.firstWhere((c) => !edgeNodes.contains(c));
          visited.add(current);
          edgeNodes.add(next);
          current = next;
        } while (fullGraph[current]!.length == 2);

        visited.add(next);
        unvisited.addAll(fullGraph[next]!);
      }

      // Add the 'collapsed' edge to our adjacency list
      final edge = Edge(edgeNodes);

      graph[edgeNodes.first] ??= <Edge>[];
      graph[edgeNodes.first]!.add(edge);

      graph[edgeNodes.last] ??= <Edge>[];
      graph[edgeNodes.last]!.add(edge);
    }
  }
}