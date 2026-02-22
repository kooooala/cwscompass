import 'dart:ui';
import 'package:cwscompass/data/floor.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/data/coordinates.dart';

// A room is an interactable that is not a toilet (eg. classroom, office, canteen, etc.)
class Room extends Interactable<Room> {
  final String subject;
  final String? number;
  final String? label;

  // Subject, room number, and the label are included in the search entry
  @override
  MapEntry<String, Room> get searchEntry => MapEntry("room$subject$number$label${Floor.floorString(floor)}", this);

  // If the label is null, the room name is generated from the room number
  Room(int floor, Color colour, this.subject, this.number, this.label, List<Entrance> entrances, List<Coordinates> coordinates)
      : super(floor, colour, coordinates, label ?? "room $number", "$subject • ${Floor.floorString(floor)}", subject, entrances);
}
