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

class Route {
  final Coordinates start, end;
  final Edge path;

  Route(this.start, this.end, this.path);
}

class School {
  final Map<Coordinates, List<Edge>> graph = {};
  // A map of the edge each intermediate node belongs to
  final Map<Coordinates, Edge> intermediateNodeEdge = {};
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

        if (edge.coordinates.length > 2) {
          for (final intermediateNode in edge.coordinates.sublist(1, edge.coordinates.length - 1)) {
            intermediateNodeEdge[intermediateNode] = edge;
          }
        }

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

  Coordinates closestIntermediateNode(Coordinates point) {
    // Find the closest non-intermediate node to point, then iterate
    // through its adjacent edges and from their nodes return the node closest
    // to point
    final closestNonIntermediate = closestNode(point);

    double minimum = maths.equirectangularDistance(point, closestNonIntermediate);
    Coordinates closest = closestNonIntermediate;

    for (final edge in graph[closestNonIntermediate]!) {
      for (final node in edge.coordinates) {
        final distance = maths.equirectangularDistance(point, node);
        if (distance < minimum) {
          closest = node;
          minimum = distance;
        }
      }
    }

    return closest;
  }

  Route shortestRoute(Coordinates start, Coordinates end) {
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

      if (current == end) {
        break;
      }

      for (final nextEdge in graph[current]!) {
        final newCost = costSoFar[current]! + nextEdge.distance;
        final next = nextEdge.coordinates.first == current ? nextEdge.coordinates.last : nextEdge.coordinates.first;
        if (!costSoFar.keys.contains(next) || newCost < costSoFar[next]!) {
          costSoFar[next] = newCost;
          // Use the distance from the end node as the heuristic function
          final priority = newCost + maths.equirectangularDistance(next, end);
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
    Coordinates current = end;
    final route = <Coordinates>[];
    while (current != start) {
      route.add(current);
      current = cameFrom[current]!;
    }
    route.add(start);

    return Route(start, end, Edge(route.reversed.toList()));
  }

  Route shortestRoutePairing(List<Coordinates> startNodes, List<Coordinates> endNodes) {
    Route? shortest;
    double shortestDistance = double.infinity;

    for (final startNode in startNodes) {
      for (final endNode in endNodes) {
        final route = shortestRoute(startNode, endNode);
        if (route.path.distance < shortestDistance) {
          shortest = route;
          shortestDistance = route.path.distance;
        }
      }
    }

    return shortest!;
  }

  List<Coordinates> intermediateToRegular(Coordinates intermediate, Coordinates regular) {
    final edge = intermediateNodeEdge[intermediate]!;
    final index = edge.coordinates.indexOf(intermediate);
    if (edge.coordinates.first == regular) {
      return edge.coordinates.sublist(0, index + 1).reversed.toList();
    } else {
      return edge.coordinates.sublist(index, edge.coordinates.length);
    }
  }

  Route shortestRouteFromIntermediateNode(Coordinates start, List<Coordinates> endNodes) {
    Route shortestRoute;
    final startIsIntermediate = !graph.containsKey(start);

    if (startIsIntermediate) {
      final edge = intermediateNodeEdge[start]!.coordinates;

      final route1 = shortestRoutePairing([edge.first], endNodes);
      final distance1 = route1.path.distance + Edge(intermediateToRegular(start, route1.start)).distance;

      final route2 = shortestRoutePairing([edge.last], endNodes);
      final distance2 = route2.path.distance + Edge(intermediateToRegular(start, route2.start)).distance;

      if (distance1 < distance2) {
        shortestRoute = route1;
      } else {
        shortestRoute = route2;
      }
    } else {
      shortestRoute = shortestRoutePairing([start], endNodes);
    }

    List<Coordinates> fullPath = shortestRoute.path.coordinates;
    if (startIsIntermediate) {
      fullPath = intermediateToRegular(start, shortestRoute.start) + fullPath.sublist(1);
    }

    return Route(start, shortestRoute.end, Edge(fullPath));
  }

  Route adjustRouteDisplay(Coordinates location, Route route) {
    final closestNode = closestIntermediateNode(location);

    final coordinates = route.path.coordinates;
    final closestNodeIndex = coordinates.indexOf(closestNode);

    double nextDistanceProportion;
    if (closestNode == coordinates.last) {
      nextDistanceProportion = 0;
    } else {
      nextDistanceProportion = maths.equirectangularDistance(location, coordinates[closestNodeIndex + 1])
          / maths.equirectangularDistance(closestNode, coordinates[closestNodeIndex + 1]);
    }

    double previousDistanceProportion;
    if (closestNode == coordinates.first) {
      if (maths.equirectangularDistance(location, coordinates[1]) > maths.equirectangularDistance(coordinates.first, coordinates[1])) {
        previousDistanceProportion = 0;
      } else {
        previousDistanceProportion = double.infinity;
      }
    } else {
      previousDistanceProportion = maths.equirectangularDistance(location, coordinates[closestNodeIndex - 1])
          / maths.equirectangularDistance(closestNode, coordinates[closestNodeIndex - 1]);
    }

    int lastDisplayNodeIndex;
    if (previousDistanceProportion > nextDistanceProportion) {
      lastDisplayNodeIndex = closestNodeIndex + 1;
    } else {
      lastDisplayNodeIndex = closestNodeIndex;
    }

    final path = [location] + coordinates.sublist(lastDisplayNodeIndex, coordinates.length);
    return Route(path.first, path.last, Edge(path));
  }

  Route locationToRoom(Coordinates location, Room room) {
    final closestNode = closestIntermediateNode(location);
    final route = shortestRouteFromIntermediateNode(closestNode, room.entrances);

    return adjustRouteDisplay(location, route);
  }
}