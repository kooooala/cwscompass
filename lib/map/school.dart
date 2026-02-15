import 'dart:io';
import 'dart:math';

import 'package:cwscompass/data/structures/building.dart';
import 'package:cwscompass/data/structures/inaccessible.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/data/path.dart';
import 'package:cwscompass/common/maths.dart' as maths;

import 'package:collection/collection.dart';
import 'package:cwscompass/data/staircase.dart';
import 'package:cwscompass/data/structures/toilet.dart';
import 'package:vector_math/vector_math.dart';

class Route {
  final Coordinates start, end;
  final List<Direction> directions;
  final Edge path;

  Route(this.start, this.end, this.directions, this.path);
}

enum Turn {
  left, right, straight, enterBuilding, exitBuilding, destination, stairsUp, stairsDown
}

class Direction {
  final Turn turn;
  final String? label;
  final Coordinates coordinates;

  double distance;

  Direction(this.turn, this.label, this.coordinates, this.distance);
}

class Edge {
  final List<Coordinates> coordinates;
  late final double distance;

  Edge(this.coordinates, double? distance) {
    this.distance = distance ?? calculateDistance();
  }

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

  EdgeWithLabel(super.coordinates, super.distance, this.label);
}

class Graph {
  final Map<Coordinates, List<EdgeWithLabel>> simplified;
  final Map<Coordinates, Edge> intermediateNodeEdge;

  Graph(this.simplified, this.intermediateNodeEdge);
}

class Floor {
  final List<Structure> structures;
  Graph graph;

  final List<Room> rooms;
  final List<Building> buildings;
  final List<Inaccessible> inaccessible;
  final List<Toilet> toilets;

  Floor(this.structures, this.graph)
      : rooms = structures.whereType<Room>().toList(),
        buildings = structures.whereType<Building>().toList(),
        inaccessible = structures.whereType<Inaccessible>().toList(),
        toilets = structures.whereType<Toilet>().toList();

  static String floorString(int floor) {
    String result;
    if (floor == 0) {
      result = "G";
    } else {
      result = floor.toString();
    }
    result += "/F";

    return result;
  }
}

class School {
  final Graph graph = Graph({}, {});
  final List<Floor> floors = [];
  final List<Staircase> staircases;

  static Graph simplifyGraph(Map<Coordinates, List<(Coordinates, String?)>> fullGraph) {
    final graph = Graph({}, {});

    // Simplify the graph by 'collapsing' paths with no branches i.e. removing
    // intermediate nodes (nodes with degree 2)

    // Identify all nodes that are not intermediate (the ones we want to keep)
    final junctions = fullGraph.keys
        .where((n) => n is BuildingEntrance || fullGraph[n]!.length != 2)
        .toList();
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
        final edge = EdgeWithLabel(edgeNodes, null, child.$2);

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

  static Graph floorGraph(List<Structure> structures, List<Path> paths) {
    final buildings = structures.whereType<Building>();
    final interactables = structures.whereType<Interactable>();

    Map<Coordinates, List<(Coordinates, String?)>> fullGraph = {};
    Map<Coordinates, BuildingEntrance> coordinatesToBuildingEntrance = {};
    for (final building in buildings) {
      for (final entrance in building.entrances) {
        final coordinates = Coordinates(entrance.floor, entrance.latitude, entrance.longitude);
        coordinatesToBuildingEntrance[coordinates] = entrance;
      }
    }

    for (final path in paths) {
      for (final (i, c1) in path.vertices.sublist(0, path.vertices.length - 1).indexed) {
        final c2 = path.vertices[i + 1];

        final current = coordinatesToBuildingEntrance[c1] ?? c1;
        final next = coordinatesToBuildingEntrance[c2] ?? c2;

        fullGraph[current] ??= <(Coordinates, String?)>[];
        fullGraph[current]!.add((next, path.label));

        fullGraph[next] ??= <(Coordinates, String?)>[];
        fullGraph[next]!.add((current, path.label));
      }
    }

    for (final interactable in interactables) {
      for (final entrance in interactable.entrances) {
        final coordinates = Coordinates(entrance.floor, entrance.latitude, entrance.longitude);
        fullGraph[coordinates]!.add((entrance, null));
        fullGraph[entrance] = [(coordinates, null)];
      }
    }

    return simplifyGraph(fullGraph);
  }

  School(List<Structure> structures, List<Path> paths, this.staircases) {
    // Determine the no. of floors by getting the room with the highest floor value
    final floorCount = structures.reduce((a, b) => a.floor > b.floor ? a : b).floor + 1;
    for (int i = 0; i < floorCount; i++) {
      final floorStructures = structures.where((s) => s.floor == i).toList();
      final floorPaths = paths.where((p) => p.floor == i).toList();

      floors.add(Floor(floorStructures, floorGraph(floorStructures, floorPaths)));
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

  Direction getDirectionSameFloor(Coordinates previous, Coordinates current, Coordinates next) {
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

    String? label;
    if (current is! Entrance) {
      label = graph.simplified[current]!.firstWhere((e) => e.coordinates.contains(next)).label;
    }
    return Direction(turn, label, current, 0);
  }

  Direction getDirectionElevation(Coordinates current, Coordinates next) {
    final turn = next.floor > current.floor ? Turn.stairsDown : Turn.stairsUp;
    final label = staircases.firstWhere((staircase) => staircase.coordinates.contains(current)).label;
    return Direction(turn, label, current, 0);
  }

  Direction getDirection(Coordinates previous, Coordinates current, Coordinates next) {
    if (current is BuildingEntrance) {
      final isEntering = current.building.intersects(previous.point);
      return Direction(isEntering ? Turn.enterBuilding : Turn.exitBuilding, current.building.name, current, 0);
    } else if (current.floor != next.floor) {
      return getDirectionElevation(current, next);
    } else {
      return getDirectionSameFloor(previous, current, next);
    }
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

      for (final nextEdge in graph.simplified[current]!) {
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
      if (graph.simplified.containsKey(current) && previous != null && next != null) {
        if (graph.simplified[current]!.where((e) => e.coordinates.any((c) => c is Entrance)).isEmpty) {
          directions.first.distance = distanceToNextJunction;
          directions.insert(0, getDirection(previous, current, next));
          distanceToNextJunction = 0;
        }
      }

      previous = current;
      if (cameFrom[current] == null) {
        int i = 0;
      }
      current = cameFrom[current]!;
      next = cameFrom[current];
    }
    route.add(start);

    return Route(start, end, directions.toList(), Edge(route.reversed.toList(), null));
  }

  Coordinates closestNode(Coordinates point) {
    double minimum = double.infinity;
    Coordinates closest = graph.simplified.keys.first;

    // Get the closest node that is on the same floor as point
    for (final node in floors[point.floor].graph.simplified.keys) {
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
    Coordinates closestNonIntermediate = closestNode(point);
    if (closestNonIntermediate is Entrance) {
      closestNonIntermediate = closestNonIntermediate as Coordinates;
    }


    double minimum = maths.equirectangularDistance(point, closestNonIntermediate);
    Coordinates closest = closestNonIntermediate;

    // Get the closest node that is on the same floor as point
    for (final edge in floors[point.floor].graph.simplified[closestNonIntermediate]!) {
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
    final edge = graph.intermediateNodeEdge[intermediate]!;
    final index = edge.coordinates.indexOf(intermediate);
    if (edge.coordinates.first == regular) {
      return edge.coordinates.sublist(0, index + 1).reversed.toList();
    } else {
      return edge.coordinates.sublist(index, edge.coordinates.length);
    }
  }

  Route shortestRouteFromIntermediateNode(Coordinates start, List<Coordinates> endNodes) {
    Route shortestRoute;
    final startIsIntermediate = !graph.simplified.containsKey(start);

    if (startIsIntermediate) {
      final edge = graph.intermediateNodeEdge[start]!.coordinates;

      final route1 = shortestRoutePairing([edge.first], endNodes);
      final distance1 = route1.path.distance + Edge(intermediateToRegular(start, route1.start), null).distance;

      final route2 = shortestRoutePairing([edge.last], endNodes);
      final distance2 = route2.path.distance + Edge(intermediateToRegular(start, route2.start), null).distance;

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

    return Route(start, shortestRoute.end, shortestRoute.directions, Edge(fullPath, null));
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
    // Only adjust if the new node and the location are on the same floor
    if (previousDistanceProportion > nextDistanceProportion && coordinates[closestNodeIndex + 1].floor == location.floor) {
      lastDisplayNodeIndex = closestNodeIndex + 1;
    } else {
      lastDisplayNodeIndex = closestNodeIndex;
    }

    final path = [location] + coordinates.sublist(lastDisplayNodeIndex, coordinates.length);
    return Route(path.first, path.last, route.directions, Edge(path, null));
  }

  Route locationToRoom(Coordinates location, Interactable interactable) {
    final closestNode = closestIntermediateNode(location);
    final route = shortestRouteFromIntermediateNode(closestNode, interactable.entrances);

    return adjustRouteDisplay(location, route);
  }
}