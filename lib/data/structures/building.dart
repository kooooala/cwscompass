import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/data/structures/structure.dart';

class Building extends Structure {
  late final List<BuildingEntrance> entrances;

  final String name;

  Building(super.floor, super.colour, super.coordinates, this.name, List<Entrance> entrances) {
    this.entrances = entrances.map((e) => BuildingEntrance(this, e.floor, e.latitude, e.longitude)).toList();
  }
}