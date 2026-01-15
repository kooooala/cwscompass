import 'dart:ui';
import 'dart:math';
import 'package:sqflite/sqflite.dart';

import 'coordinates.dart';

class Path {
  final String? label;
  final List<Coordinates> vertices;

  Path(this.label, this.vertices);

  static Future<List<int>> getPathList(Database db) async {
    final queryResults = await db.query("paths", columns: ["path_id"]);
    return queryResults.map((path) => path["path_id"] as int).toList();
  }

  static Future<Path> fromPathId(Database db, int pathId) async {
    final pathData = (await db.query("paths",
      columns: ["label"],
      where: "path_id = ?",
      whereArgs: [pathId]
    ))[0];
    final label = pathData["label"] as String;

    final vertices = await db.query("path_vertices",
      columns: ["coordinates", "floor"],
      where: "path = ?",
      whereArgs: [pathId],
      orderBy: "sequence"
    );

    final coordinates = await Future.wait(vertices.map((vertex) async {
      final result = (await db.query("coordinates",
          columns: ["latitude", "longitude"],
          where: "coordinates_id = ?",
          whereArgs: [vertex["coordinates"] as int]))[0];
      return Coordinates(result["latitude"] as double, result["longitude"] as double);
    }));

    return Path(label == "None" ? null : label, coordinates);
  }
}