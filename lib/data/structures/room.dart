import 'dart:ui';
import 'package:cwscompass/data/floor.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/data/coordinates.dart';

class Room extends Interactable<Room> {
  final String subject;
  final String? number;
  final String? label;

  @override
  MapEntry<String, Room> get searchEntry => MapEntry("room$subject$number$label${Floor.floorString(floor)}", this);

  Room(int floor, Color colour, this.subject, this.number, this.label, List<Entrance> entrances, List<Coordinates> coordinates)
      : super(floor, colour, coordinates, label ?? "room $number", "$subject • ${Floor.floorString(floor)}", subject, entrances);
}
