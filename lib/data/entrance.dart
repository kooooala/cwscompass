import 'package:cwscompass/data/structures/building.dart';
import 'package:cwscompass/data/coordinates.dart';

class Entrance extends Coordinates {
  final String? label;

  Entrance(super.floor, super.latitude, super.longitude, this.label);
}

class BuildingEntrance extends Coordinates {
  final Building building;

  BuildingEntrance(this.building, super.floor, super.latitude, super.longitude);
}