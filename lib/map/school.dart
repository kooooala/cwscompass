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
      if (coordinates[i].latitude == coordinates[i + 1].latitude && coordinates[i].longitude == coordinates[i + 1].longitude) {
        continue;
      }
      result += maths.haversineDistance(coordinates[i], coordinates[i + 1]);
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

    for (final room in rooms) {
      for (final entrance in room.entrances) {
        final coordinates = Coordinates(entrance.latitude, entrance.longitude);
        fullGraph[coordinates]!.add(entrance);
        fullGraph[entrance] = [coordinates];
      }
    }

    // Simplify the graph by 'collapsing' paths with no branches i.e. removing
    // intermediate nodes (nodes with degree 2)

    // Identify all nodes that are not intermediate (the ones we want to keep)
    final junctions = fullGraph.keys.where((n) => fullGraph[n]!.length != 2).toList();
    final visited = <List<Coordinates>>[];

    for (final junction in junctions) {
      final children = fullGraph[junction]!;

      for (final child in children) {
        // Skip over ones we have already traversed
        if (visited.any((edge) =>
          (edge[0] == junction && edge[1] == child) ||
          (edge[1] == junction && edge[0] == child))) {
          continue;
        }

        final edgeNodes = <Coordinates>[junction, child];
        var last = junction;
        var current = child;

        while (!junctions.contains(current)) {
          final next = fullGraph[current]!.firstWhere((n) => n != last);
          edgeNodes.add(next);
          last = current;
          current = next;
        }

        // We only need to add the start and end edges to visited because these
        // are the only ones that connect to a junction
        visited.add([edgeNodes.first, edgeNodes[1]]);
        visited.add([edgeNodes.last, edgeNodes[edgeNodes.length - 2]]);

        // Add the 'collapsed' path to our adjacency list
        final edge = Edge(edgeNodes);

        graph[edgeNodes.first] ??= <Edge>[];
        graph[edgeNodes.first]!.add(edge);

        graph[edgeNodes.last] ??= <Edge>[];
        graph[edgeNodes.last]!.add(edge);
      }
    }
  }

  Coordinates closestNode(Coordinates point) {
    double minimum = double.infinity;
    Coordinates closest = graph.keys.first;

    for (final node in graph.keys) {
      final distance = maths.euclideanDistance(point.toPoint(), node.toPoint());
      if (distance < minimum) {
        closest = node;
        minimum = distance;
      }
    }

    return closest;
  }
}