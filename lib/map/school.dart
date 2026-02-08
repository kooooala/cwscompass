import 'dart:math';

import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/entrance.dart';
import 'package:cwscompass/room.dart';
import 'package:cwscompass/path.dart';
import 'package:cwscompass/common/maths.dart' as maths;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math.dart';

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
      result += maths.equirectangularDistance(coordinates[i], coordinates[i + 1]);
    }
    return result;
  }
}

class EdgeWithLabel extends Edge {
  final String? label;

  EdgeWithLabel(super.coordinates, this.label);
}

class Route {
  final Coordinates start, end;
  final List<Direction> directions;
  final Edge path;

  Route(this.start, this.end, this.directions, this.path);
}

enum Turn {
  left, right, straight, destination
}

class Direction {
  final Turn turn;
  final String? label;
  final Coordinates coordinates;

  double distance;

  Direction(this.turn, this.label, this.coordinates, this.distance);
}

class School {
  final Map<Coordinates, List<EdgeWithLabel>> graph = {};
  // A map of the edge each intermediate node belongs to
  final Map<Coordinates, Edge> intermediateNodeEdge = {};
  final List<Room> rooms;

  School(this.rooms, List<Path> _paths) {
    Map<Coordinates, List<(Coordinates, String?)>> fullGraph = {};

    for (final path in _paths) {
      for (final (i, vertex) in path.vertices.sublist(0, path.vertices.length - 1).indexed) {
        final next = path.vertices[i + 1];

        fullGraph[vertex] ??= <(Coordinates, String?)>[];
        fullGraph[vertex]!.add((next, path.label));

        fullGraph[next] ??= <(Coordinates, String?)>[];
        fullGraph[next]!.add((vertex, path.label));
      }
    }

    for (final room in rooms) {
      for (final entrance in room.entrances) {
        final coordinates = Coordinates(entrance.latitude, entrance.longitude);
        fullGraph[coordinates]!.add((entrance, null));
        fullGraph[entrance] = [(coordinates, null)];
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
          (edge[0] == junction && edge[1] == child.$1) ||
          (edge[1] == junction && edge[0] == child.$1))) {
          continue;
        }

        final edgeNodes = <Coordinates>[junction, child.$1];
        var last = junction;
        var current = child;

        while (!junctions.contains(current.$1)) {
          final next = fullGraph[current.$1]!.firstWhere((n) => n.$1 != last);
          edgeNodes.add(next.$1);
          last = current.$1;
          current = next;
        }

        // We only need to add the start and end edges to visited because these
        // are the only ones that connect to a junction
        visited.add([edgeNodes.first, edgeNodes[1]]);
        visited.add([edgeNodes.last, edgeNodes[edgeNodes.length - 2]]);

        // Add the 'collapsed' path to our adjacency list
        final edge = EdgeWithLabel(edgeNodes, child.$2);

        if (edge.coordinates.length > 2) {
          for (final intermediateNode in edge.coordinates.sublist(1, edge.coordinates.length - 1)) {
            intermediateNodeEdge[intermediateNode] = edge;
          }
        }

        graph[edgeNodes.first] ??= <EdgeWithLabel>[];
        graph[edgeNodes.first]!.add(edge);

        graph[edgeNodes.last] ??= <EdgeWithLabel>[];
        graph[edgeNodes.last]!.add(edge);
      }
    }
  }

  Coordinates closestNode(Coordinates point) {
    double minimum = double.infinity;
    Coordinates closest = graph.keys.first;

    for (final node in graph.keys) {
      if (node is Entrance) {
        continue;
      }

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

  Direction getDirection(Coordinates previous, Coordinates current, Coordinates next) {
    final vector1 = Vector2(current.longitude - previous.longitude, current.latitude - previous.latitude);
    final vector2 = Vector2(next.longitude - current.longitude, next.latitude - current.latitude);
    final crossProduct = vector1.cross(vector2);
    final dotProduct = vector1.dot(vector2);
    final angle = atan2(crossProduct, dotProduct);

    Turn turn;
    if (angle < 0 - 0.1 * pi) {
      turn = Turn.left;
    } else if (angle > 0 + 0.1 * pi) {
      turn = Turn.right;
    } else {
      turn = Turn.straight;
    }

    final label = graph[current]!.firstWhere((e) => e.coordinates.contains(next)).label;
    return Direction(turn, label, current, 0);
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
    Coordinates? previous, next;
    final route = <Coordinates>[];
    List<Direction> directions = [Direction(Turn.destination, null, end, 0)];
    double distanceToNextJunction = 0;
    while (current != start) {
      if (previous != null) {
        distanceToNextJunction += maths.equirectangularDistance(current, previous);
      }
      route.add(current);

      // Add direction if current is a junction
      if (graph.containsKey(current) && previous != null && next != null) {
        if (graph[current]!.where((e) => e.coordinates.any((c) => c is Entrance)).isEmpty) {
          directions.first.distance = distanceToNextJunction;
          directions.insert(0, getDirection(previous, current, next));
          distanceToNextJunction = 0;
        }
      }

      previous = current;
      current = cameFrom[previous]!;
      next = cameFrom[current];
    }
    route.add(start);

    return Route(start, end, directions.toList(), Edge(route.reversed.toList()));
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

    return Route(start, shortestRoute.end, shortestRoute.directions, Edge(fullPath));
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
    return Route(path.first, path.last, route.directions, Edge(path));
  }

  Route locationToRoom(Coordinates location, Room room) {
    final closestNode = closestIntermediateNode(location);
    final route = shortestRouteFromIntermediateNode(closestNode, room.entrances);

    return adjustRouteDisplay(location, route);
  }
}