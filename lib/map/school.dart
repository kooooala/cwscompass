import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/path.dart';
import 'package:cwscompass/common/maths.dart' as maths;

import 'package:collection/collection.dart';

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

typedef Route = Edge;

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
      final distance = maths.equirectangularDistance(point, node);
      if (distance < minimum) {
        closest = node;
        minimum = distance;
      }
    }

    return closest;
  }

  Route shortestRoute(Coordinates start, Coordinates goal) {
    // Use A* search algorithm to find the shortest route between two points;
    // implementation based on https://theory.stanford.edu/~amitp/GameProgramming/ImplementationNotes.html
    final frontier = PriorityQueue<(Coordinates, double)>((a, b) => a.$2.compareTo(b.$2));
    frontier.add((start, 0));
    final cameFrom = <Coordinates, Coordinates?>{};
    final costSoFar = <Coordinates, double>{};
    cameFrom[start] = null;
    costSoFar[start] = 0;

    while (frontier.isNotEmpty) {
      final current = frontier.removeFirst().$1;

      if (current == goal) {
        break;
      }

      for (final nextEdge in graph[current]!) {
        final newCost = costSoFar[current]! + nextEdge.distance;
        final next = nextEdge.coordinates.first == current ? nextEdge.coordinates.last : nextEdge.coordinates.first;
        if (!costSoFar.keys.contains(next) || newCost < costSoFar[next]!) {
          costSoFar[next] = newCost;
          // Use the distance from the goal as the heuristic function
          final priority = newCost + maths.equirectangularDistance(next, goal);
          frontier.add((next, priority));

          // Since an edge is made up of smaller intermediate edges, they will
          // have all to be added to the list individually
          List<Coordinates> intermediates = nextEdge.coordinates;
          if (nextEdge.coordinates.first == current) {
            intermediates = intermediates.reversed.toList();
          }
          for (var i = 0; i < intermediates.length - 1; i++) {
            cameFrom[intermediates[i]] = intermediates[i + 1];
          }
        }
      }
    }

    // Reconstruct shortest route
    Coordinates current = goal;
    final route = <Coordinates>[];
    while (current != start) {
      route.add(current);
      current = cameFrom[current]!;
    }
    route.add(start);

    return Route(route);
  }
}