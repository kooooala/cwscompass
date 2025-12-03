import 'dart:ui';
import 'dart:math';
import 'package:sqflite/sqflite.dart';

import 'coordinates.dart';

class Room {
  final int roomId;

  final Color colour;
  final String subject;
  final String number;
  final String? label;

  // coordinates of the room using the WGS 84 Web Mercator projection
  final List<Coordinates> coordinates;
  // coordinates of the room in the app map
  final List<Point<double>> vertices;

  late double _area = 0;
  late Point<double>? _centroid = null;

  Room(this.roomId, this.colour, this.subject, this.number, this.label, this.coordinates)
    : vertices = coordinates.map((c) => c.toPoint()).toList();

  double get area {
    if (_area != 0) {
      return _area;
    }

    // computes the area of a polygon using the shoelace formula
    double sum = 0;
    for (var i = 0; i < vertices.length; i++) {
      sum += vertices[i].x * vertices[(i + 1) % vertices.length].y - vertices[(i + 1) % vertices.length].x * vertices[i].y;
    }
    _area = sum / 2;
    return _area;
  }

  Point<double> get centroid {
    if (_centroid != null) {
      return _centroid!;
    }

    double x = 0, y = 0;
    for (var i = 0; i < vertices.length; i++) {
      final current = vertices[i], next = vertices[(i + 1) % vertices.length];
      x += (current.x + next.x) * (current.x * next.y - next.x * current.y);
      y += (current.y + next.y) * (current.x * next.y - next.x * current.y);
    }
    x /= 6 * area;
    y /= 6 * area;

    _centroid = Point<double>(x, y);
    print("$x, $y");
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
    final label = roomData["label"] as String;

    final vertices = await db.query("room_vertices",
      columns: ["coordinates"],
      where: "room = ?",
      whereArgs: [roomId],
      orderBy: "sequence"
    );

    final coordinates = await Future.wait(vertices.map((vertex) async {
      final result = (await db.query("coordinates",
        columns: ["latitude", "longitude"],
        where: "coordinates_id = ?",
        whereArgs: [vertex["coordinates"] as int]))[0];
      return Coordinates(result["latitude"] as double, result["longitude"] as double);
    }));

    final colourHex = roomData["colour"] as int;
    final colour = Color.fromARGB(0xFF, colourHex >> 16, (colourHex >> 8) & 0xFF, colourHex & 0xFF);

    return Room(roomId,
      colour,
      roomData["subject"] as String,
      roomData["number"] as String,
      label == "None" ? null : label,
      coordinates);
  }
}
