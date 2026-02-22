import 'dart:math';
import 'package:collection/collection.dart';
import 'package:cwscompass/data/direction.dart';
import 'package:cwscompass/data/graph.dart';
import 'package:vector_math/vector_math.dart';

import 'package:cwscompass/data/edge.dart';
import 'package:cwscompass/data/floor.dart';
import 'package:cwscompass/data/structures/building.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/data/path.dart';
import 'package:cwscompass/data/staircase.dart';
import 'package:cwscompass/common/maths.dart' as maths;

class Route {
  final Coordinates start, end;
  final List<Direction> directions;
  final Edge path;

  Route(this.start, this.end, this.directions, this.path);
}

class School {
  final Graph graph = Graph({}, {});
  final List<Floor> floors = [];
  final List<Staircase> staircases;

  static Graph _simplifyGraph(Map<Coordinates, List<(Coordinates, String?)>> fullGraph) {
    // See section 2.5.1.2 for explanation and pseudo-code

    final graph = Graph({}, {});

    // Identify all nodes that are not intermediate (the ones we want to keep)
    final junctions = fullGraph.keys
        .where((n) => n is BuildingEntrance || fullGraph[n]!.length != 2)
        .toList();
    final visited = <List<Coordinates>>[];

    for (final junction in junctions) {
      final children = fullGraph[junction]!;

      for (final child in children) {
        // Skip over the ones we've already done
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
          for (final intermediateNode in edge.coordinates.sublist(
              1, edge.coordinates.length - 1)) {
            graph.intermediateNodeEdge[intermediateNode] = edge;
          }
        }

        graph.simplified[edgeNodes.first] ??= <EdgeWithLabel>[];
        graph.simplified[edgeNodes.first]!.add(edge);

        graph.simplified[edgeNodes.last] ??= <EdgeWithLabel>[];
        graph.simplified[edgeNodes.last]!.add(edge);
      }
    }

    return graph;
  }

  static Graph _floorGraph(List<Structure> structures, List<Path> paths) {
    final buildings = structures.whereType<Building>();
    final interactables = structures.whereType<Interactable>();

    Map<Coordinates, List<(Coordinates, String?)>> fullGraph = {};

    // Since building entrances are points that have the same coordinates as a
    // path vertex and are stored separately to paths, a dictionary is used
    // here to map a regular coordinates to a building entrance.
    Map<Coordinates, BuildingEntrance> coordinatesToBuildingEntrance = {};
    for (final building in buildings) {
      for (final entrance in building.entrances) {
        final coordinates = Coordinates(entrance.floor, entrance.latitude, entrance.longitude);
        coordinatesToBuildingEntrance[coordinates] = entrance;
      }
    }

    // Iterate through each path, and add each consecutive vertex pair to the graph
    for (final path in paths) {
      for (final (i, c1) in path.vertices.sublist(0, path.vertices.length - 1).indexed) {
        final c2 = path.vertices[i + 1];

        // Check if coordinates are building entrances
        final current = coordinatesToBuildingEntrance[c1] ?? c1;
        final next = coordinatesToBuildingEntrance[c2] ?? c2;

        fullGraph[current] ??= <(Coordinates, String?)>[];
        fullGraph[current]!.add((next, path.label));

        fullGraph[next] ??= <(Coordinates, String?)>[];
        fullGraph[next]!.add((current, path.label));
      }
    }

    // Add the entrances to the graph
    for (final interactable in interactables) {
      for (final entrance in interactable.entrances) {
        final coordinates = Coordinates(entrance.floor, entrance.latitude, entrance.longitude);
        fullGraph[coordinates]!.add((entrance, null));
        fullGraph[entrance] = [(coordinates, null)];
      }
    }

    return _simplifyGraph(fullGraph);
  }

  School(List<Structure> structures, List<Path> paths, this.staircases) {
    // Determine the no. of floors by getting the room with the highest floor value
    final floorCount = structures.reduce((a, b) => a.floor > b.floor ? a : b).floor + 1;
    for (int i = 0; i < floorCount; i++) {
      final floorStructures = structures.where((s) => s.floor == i).toList();
      final floorPaths = paths.where((p) => p.floor == i).toList();

      floors.add(Floor(floorStructures, _floorGraph(floorStructures, floorPaths)));
    }

    // Merge the floor graphs into one
    for (final floorGraph in floors.map((f) => f.graph)) {
      graph.simplified.addAll(floorGraph.simplified);
      graph.intermediateNodeEdge.addAll(floorGraph.intermediateNodeEdge);
    }

    // Join the floor graphs with staircases
    for (final staircase in staircases) {
      final landing1Node = graph.simplified[Coordinates(staircase.coordinates[0].floor, staircase.coordinates[0].latitude, staircase.coordinates[0].longitude)];
      final landing2Node = graph.simplified[Coordinates(staircase.coordinates[1].floor, staircase.coordinates[1].latitude, staircase.coordinates[1].longitude)];
      if (landing1Node == null || landing2Node == null) {
        throw Exception("Staircase with landings ${staircase.coordinates[0]} and ${staircase.coordinates[1]} is not connected to the rest of the graph");
      }
      landing1Node.add(staircase);
      landing2Node.add(staircase);
    }
  }

  Direction _getDirectionSameFloor(Coordinates previous, Coordinates current, Coordinates next) {
    // Calculate the signed angle between v1 (previous -> current) and v2 (current -> next)
    // Formula: https://wumbo.net/formulas/angle-between-two-vectors-2d/
    final v1 = Vector2(current.longitude - previous.longitude, current.latitude - previous.latitude);
    final v2 = Vector2(next.longitude - current.longitude, next.latitude - current.latitude);
    final crossProduct = v1.cross(v2);
    final dotProduct = v1.dot(v2);
    final angle = atan2(crossProduct, dotProduct);

    // See section 2.5.3.3 for graphics
    Turn turn;
    if (angle < -0.25 * pi) {
      turn = Turn.right;
    } else if (angle > 0.25 * pi) {
      turn = Turn.left;
    } else {
      turn = Turn.straight;
    }

    // Get the label from the first edge in the graph that contains current
    // Probably not the best way of doing this
    String? label;
    if (current is! Entrance) {
      label = graph.simplified[current]!.firstWhere((e) => e.coordinates.contains(next)).label;
    }
    return Direction(turn, label, current, 0);
  }

  Direction _getDirectionElevation(Coordinates current, Coordinates next) {
    final turn = next.floor < current.floor ? Turn.stairsDown : Turn.stairsUp;
    final label = staircases.firstWhere((staircase) => staircase.coordinates.contains(current)).label;
    return Direction(turn, label, current, 0);
  }

  Direction _getDirection(Coordinates previous, Coordinates current, Coordinates next) {
    if (current is BuildingEntrance) {
      // If next is in the building, it means we're entering the building
      final isEntering = current.building.intersects(next.point);
      return Direction(isEntering ? Turn.enterBuilding : Turn.exitBuilding, current.building.name, current, 0);
    } else if (current.floor != next.floor) {
      return _getDirectionElevation(current, next);
    } else {
      return _getDirectionSameFloor(previous, current, next);
    }
  }

  static double _heuristic(Coordinates c1, Coordinates c2) {
    // An additional cost is added to the distance for each floor change to make
    // sure the route finding won't get stuck exploring just one floor
    final floorChange = (c1.floor - c2.floor).abs();
    return maths.fastDistance(c1, c2) + floorChange * Staircase.cost;
  }

  Route _reconstruct(Map<Coordinates, Coordinates?> cameFrom, Coordinates start, Coordinates end) {
    Coordinates current = end;
    Coordinates? previous, next;
    final route = <Coordinates>[];
    List<Direction> directions = [Direction(Turn.destination, null, end, 0)];
    double distanceToNextJunction = 0;
    while (current != start) {
      if (previous != null) {
        distanceToNextJunction += maths.fastDistance(current, previous);
      }
      route.add(current);

      // Add direction if current is a junction
      if (graph.simplified.containsKey(current) && previous != null && next != null) {
        // Check if the junction is a junction only because of being connected to an entrance
        if (graph.simplified[current]!.where((e) => !e.coordinates.any((c) => c is Entrance)).length > 2) {
          directions.first.distance = distanceToNextJunction;
          // Insert the direction at the front of the list since we're working backwards from end to start
          directions.insert(0, _getDirection(next, current, previous));
          distanceToNextJunction = 0;
        }
      }

      previous = current;
      current = cameFrom[current]!;
      next = cameFrom[current];
    }
    route.add(start);

    return Route(start, end, directions, Edge(route.reversed.toList()));
  }

  Route shortestRoute(Coordinates start, Coordinates end) {
    // Use A* search algorithm to find the shortest route between two points;
    // implementation based on https://theory.stanford.edu/~amitp/GameProgramming/ImplementationNotes.html
    // See section 2.5.2 for explanation and pseudo-code
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

      for (final nextEdge in graph.simplified[current]!) {
        final newCost = costSoFar[current]! + nextEdge.distance;
        final next = nextEdge.coordinates.first == current ? nextEdge.coordinates.last : nextEdge.coordinates.first;
        if (!costSoFar.keys.contains(next) || newCost < costSoFar[next]!) {
          costSoFar[next] = newCost;
          final priority = newCost + _heuristic(next, end);
          frontier.add((next, priority));

          // Since an edge is made up of smaller intermediate edges, they will
          // have to be added to the list individually
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

    return _reconstruct(cameFrom, start, end);
  }

  Coordinates closestNode(Coordinates point) {
    double minimum = double.infinity;
    Coordinates closest = graph.simplified.keys.first;

    // Get the closest node that is on the same floor as point
    for (final node in floors[point.floor].graph.simplified.keys) {
      final distance = maths.fastDistance(point, node);
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
    Coordinates closestNonIntermediate = closestNode(point);
    if (closestNonIntermediate is Entrance) {
      closestNonIntermediate = closestNonIntermediate as Coordinates;
    }


    double minimum = maths.fastDistance(point, closestNonIntermediate);
    Coordinates closest = closestNonIntermediate;

    // Get the closest node that is on the same floor as point
    for (final edge in floors[point.floor].graph.simplified[closestNonIntermediate]!) {
      for (final node in edge.coordinates) {
        if (node.floor != point.floor) {
          continue;
        }

        final distance = maths.fastDistance(point, node);
        if (distance < minimum) {
          closest = node;
          minimum = distance;
        }
      }
    }

    return closest;
  }

  Route shortestRoutePairing(List<Coordinates> startNodes, List<Coordinates> endNodes) {
    Route? shortest;
    double shortestDistance = double.infinity;

    // This was added because rooms can have multiple entrances
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

  // Return a path that goes from the intermediate node to the regular node
  List<Coordinates> _intermediateToRegular(Coordinates intermediate, Coordinates regular) {
    final edge = graph.intermediateNodeEdge[intermediate]!;
    final index = edge.coordinates.indexOf(intermediate);
    // We want the path to start with intermediate so we reverse the edge if it starts with regular
    if (edge.coordinates.first == regular) {
      return edge.coordinates.sublist(0, index + 1).reversed.toList();
    } else {
      return edge.coordinates.sublist(index, edge.coordinates.length);
    }
  }

  Route _shortestRouteFromIntermediateNode(Coordinates start, List<Coordinates> endNodes) {
    Route shortestRoute;
    final startIsIntermediate = !graph.simplified.containsKey(start);

    if (startIsIntermediate) {
      final edge = graph.intermediateNodeEdge[start]!.coordinates;

      final route1 = shortestRoutePairing([edge.first], endNodes);
      final distance1 = route1.path.distance + Edge(_intermediateToRegular(start, route1.start)).distance;

      final route2 = shortestRoutePairing([edge.last], endNodes);
      final distance2 = route2.path.distance + Edge(_intermediateToRegular(start, route2.start)).distance;

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
      fullPath = _intermediateToRegular(start, shortestRoute.start) + fullPath.sublist(1);
    }

    return Route(start, shortestRoute.end, shortestRoute.directions, Edge(fullPath));
  }

  Route adjustRouteDisplay(Coordinates location, Route route) {
    // See section 2.5.5 for explanation and pseudo-code

    if (route.path.coordinates.length == 1) {
      final path = [location, route.path.coordinates.first];
      return Route(path.first, path.last, route.directions, Edge(path));
    }

    final closest = closestIntermediateNode(location);

    final coordinates = route.path.coordinates;
    final closestIndex = coordinates.indexOf(closest);

    double nextDistanceProportion;
    if (closest == coordinates.last) {
      nextDistanceProportion = 0;
    } else {
      nextDistanceProportion = maths.fastDistance(location, coordinates[closestIndex + 1])
          / maths.fastDistance(closest, coordinates[closestIndex + 1]);
    }

    double previousDistanceProportion;
    if (closest == coordinates.first) {
      if (maths.fastDistance(location, coordinates[1]) > maths.fastDistance(coordinates.first, coordinates[1])) {
        previousDistanceProportion = 0;
      } else {
        previousDistanceProportion = double.infinity;
      }
    } else {
      previousDistanceProportion = maths.fastDistance(location, coordinates[closestIndex - 1])
          / maths.fastDistance(closest, coordinates[closestIndex - 1]);
    }

    int lastDisplayedIndex;
    // Only adjust if the new node and the location are on the same floor
    if (previousDistanceProportion > nextDistanceProportion && coordinates[closestIndex + 1].floor == location.floor) {
      lastDisplayedIndex = closestIndex + 1;
    } else {
      lastDisplayedIndex = closestIndex;
    }

    final path = [location] + coordinates.sublist(lastDisplayedIndex, coordinates.length);
    return Route(path.first, path.last, route.directions, Edge(path));
  }

  Route locationToInteractable(Coordinates location, Interactable interactable) {
    final closestNode = closestIntermediateNode(location);
    final route = _shortestRouteFromIntermediateNode(closestNode, interactable.entrances);

    return adjustRouteDisplay(location, route);
  }
}