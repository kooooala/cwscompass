import 'dart:ui';
import 'dart:math';
import 'package:cwscompass/structure.dart';
import 'package:cwscompass/common/bounding_box.dart';
import 'package:cwscompass/entrance.dart';
import 'package:cwscompass/polygon.dart';
import 'package:sqflite/sqflite.dart';

import 'common/maths.dart' as maths;
import 'coordinates.dart';

class Room extends Structure {
  final String subject;
  final String? number;
  final String? label;

  late final MapEntry<String, Room> searchEntry = MapEntry("room$subject$number$label", this);

  Room(int floor, Color colour, this.subject, this.number, this.label, List<Entrance> entrances, List<Coordinates> coordinates)
      : super(floor, colour, label ?? "room $number", entrances, coordinates);

  static Future<List<int>> getRoomList(Database db) async {
    final queryResults = await db.query("rooms",
      columns: ["room_id"],
      where: "type = ?",
      whereArgs: ["room"]
    );
    return queryResults.map((room) => room["room_id"] as int).toList();
  }

  static Future<Room> fromRoomId(Database db, int roomId) async {
    final roomData = (await db.query("rooms",
      columns: ["floor", "colour", "subject", "number", "label"],
      where: "room_id = ?",
      whereArgs: [roomId]
    ))[0];
    final number = roomData["number"] as String;
    final label = roomData["label"] as String;
    final floor = roomData["floor"] as int;

    final vertices = await db.query("room_vertices",
      columns: ["coordinates"],
      where: "room = ?",
      whereArgs: [roomId],
      orderBy: "sequence"
    );

    final coordinates = await Future.wait(vertices.map((vertex) async =>
        Coordinates.fromCoordinatesId(db, vertex["coordinates"] as int)));

    final colourHex = roomData["colour"] as int;
    final colour = Color.fromARGB(0xFF, colourHex >> 16, (colourHex >> 8) & 0xFF, colourHex & 0xFF);

    final entranceData = await db.query("room_entrances",
      columns: ["label", "coordinates"],
      where: "room = ?",
      whereArgs: [roomId]
    );
    final entrances = await Future.wait(entranceData.map((entrance) async {
      final coordinates = await Coordinates.fromCoordinatesId(db, entrance["coordinates"] as int);
      final name = entrance["label"] as String == "None" ? null : label;
      return Entrance(floor, coordinates.latitude, coordinates.longitude, name);
    }));

    return Room(
      floor,
      colour,
      roomData["subject"] as String,
      number == "None" ? null : number,
      label == "None" ? null : label,
      entrances,
      coordinates
    );
  }
}
