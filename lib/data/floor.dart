import 'package:cwscompass/data/graph.dart';
import 'package:cwscompass/data/structures/building.dart';
import 'package:cwscompass/data/structures/inaccessible.dart';
import 'package:cwscompass/data/structures/room.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/data/structures/toilet.dart';

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

  static String floorChar(int floor) => floor == 0 ? "G" : floor.toString();

  static String floorString(int floor) => "${floorChar(floor)}/F";
}