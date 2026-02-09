import 'dart:ui';
import 'dart:math';
import 'package:cwscompass/common/bounding_box.dart';
import 'package:cwscompass/entrance.dart';
import 'package:cwscompass/polygon.dart';
import 'package:sqflite/sqflite.dart';

import 'common/maths.dart' as maths;
import 'coordinates.dart';

class Room extends Polygon {
  final int roomId;

  final int floor;

  final Color colour;
  final String subject;
  final String? number;
  final String? label;
  final String name;

  late final MapEntry<String, Room> searchEntry = MapEntry("room$subject$number$label", this);

  final List<Entrance> entrances;

  /// Coordinates of the room using the WGS 84 Web Mercator projection (map projection used by Google Maps).
  final List<Coordinates> coordinates;

  Point<double>? _centroid;

  Room(this.roomId, this.floor, this.colour, this.subject, this.number, this.label, this.entrances, this.coordinates)
    : name = label ?? "room $number",
      super(coordinates.map((c) => c.point).toList());

  Point<double> get centroid {
    if (_centroid != null) {
      return _centroid!;
    }

    _centroid = maths.centroid(this);
    return _centroid!;
  }

  double distanceFrom(Coordinates coordinates, {bool precise = false}) {
    final distanceFunction = precise ? maths.haversineDistance : maths.equirectangularDistance;
    return distanceFunction(coordinates, maths.pointToCoordinates(centroid, floor));
  }

  // Check if point is inside polygon by using the ray casting algorithm: https://people.utm.my/shahabuddin/?p=6277
  bool intersects(Point<double> point) {
    // Quickly check if point is within bounding box
    if (point.x < boundingBox.topLeft.x || point.x > boundingBox.bottomRight.x ||
      point.y < boundingBox.topLeft.y || point.y > boundingBox.bottomRight.y) {
      return false;
    }

    int intersections = 0;

    for (int i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];

      if (((current.y > point.y) != (next.y > point.y)) && (point.x < (next.x - current.x) * (point.y - current.y) / (next.y - current.y) + current.x)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }

  static Future<List<int>> getRoomList(Database db) async {
    final queryResults = await db.query("rooms", columns: ["room_id"]);
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

    return Room(roomId,
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
