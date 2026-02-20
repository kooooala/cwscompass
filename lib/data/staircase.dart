import 'package:cwscompass/data/school.dart';
import 'package:sqflite/sqflite.dart';

import 'coordinates.dart';

class Landing extends Coordinates {
  final String? label;

  Landing(super.floor, super.latitude, super.longitude, this.label);
}

class Staircase extends EdgeWithLabel {
  static double cost = 10.0;

  Staircase(List<Coordinates> coordinates, String? label)
      : super(coordinates, label);

  static Future<List<int>> getStaircaseList(Database db) async {
    final queryResults = await db.query("staircases", columns: ["staircase_id"]);
    return queryResults.map((staircase) => staircase["staircase_id"] as int).toList();
  }

  static Future<Staircase> fromStaircaseId(Database db, int staircaseId) async {
    final staircaseData = (await db.query(
      "staircases",
      columns: ["label", "landing1", "landing2"],
      where: "staircase_id = ?",
      whereArgs: [staircaseId]
    ))[0];

    final label = staircaseData["label"] as String;
    final landingCoordinates = [
      staircaseData["landing1"] as int,
      staircaseData["landing2"] as int,
    ];

    final landings = (await Future.wait(landingCoordinates.map((landing) {
      return Coordinates.fromCoordinatesId(db, landing);
    })));

    return Staircase(landings, label == "None" ? null : label);
  }
}