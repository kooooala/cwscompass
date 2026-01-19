import 'dart:ui';
import 'dart:math';
import 'package:cwscompass/entrance.dart';
import 'package:sqflite/sqflite.dart';

import 'common/maths.dart' as maths;
import 'coordinates.dart';

class Room {
  final int roomId;

  final Color colour;
  final String subject;
  final String number;
  final String? label;

  final List<Entrance> entrances;

  /// Coordinates of the room using the WGS 84 Web Mercator projection (map projection used by Google Maps).
  final List<Coordinates> coordinates;
  /// Coordinates of the room in the app map.
  final List<Point<double>> vertices;

  Point<double>? _centroid;

  Room(this.roomId, this.colour, this.subject, this.number, this.label, this.entrances, this.coordinates)
    : vertices = coordinates.map((c) => c.toPoint()).toList();

  Point<double> get centroid {
    if (_centroid != null) {
      return _centroid!;
    }

    _centroid = maths.centroid(vertices);
    return _centroid!;
  }

  static Future<List<int>> getRoomList(Database db) async {
    final queryResults = await db.query("rooms", columns: ["room_id"]);
    return queryResults.map((room) => room["room_id"] as int).toList();
  }

  static Future<Room> fromRoomId(Database db, int roomId) async {
    final roomData = (await db.query("rooms",
      columns: ["colour", "subject", "number", "label"],
      where: "room_id = ?",
      whereArgs: [roomId]
    ))[0];
    final number = roomData["number"] as String;
    final label = roomData["label"] as String;

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
      return Entrance(coordinates.latitude, coordinates.longitude, name);
    }));

    return Room(roomId,
      colour,
      roomData["subject"] as String,
      number,
      label == "None" ? null : label,
      entrances,
      coordinates);
  }
}
