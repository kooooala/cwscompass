import 'package:sqflite/sqflite.dart';

import 'coordinates.dart';

class Room {
  final int roomId;

  final int colour;
  final String subject;
  final String number;
  final String? label;

  final List<Coordinates> vertices;

  Room(this.roomId, this.colour, this.subject, this.number, this.label, this.vertices);

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

    return Room(roomId,
      roomData["colour"] as int,
      roomData["subject"] as String,
      roomData["number"] as String,
      label == "None" ? null : label,
      coordinates);
  }
}