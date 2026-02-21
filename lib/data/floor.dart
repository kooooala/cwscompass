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