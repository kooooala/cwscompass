import 'package:cwscompass/common/maths.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

class Coordinates extends Equatable {
  // TODO: Implement floors

  final double latitude;
  final double longitude;

  final Point<double> point;

  Coordinates(this.latitude, this.longitude) : point = coordinatesToPoint(latitude, longitude);

  @override
  List<Object> get props => [latitude, longitude];

  static Future<Coordinates> fromCoordinatesId(Database db, int coordinatesId) async {
    final result = (await db.query("coordinates",
        columns: ["latitude", "longitude"],
        where: "coordinates_id = ?",
        whereArgs: [coordinatesId]))[0];
    return Coordinates(result["latitude"] as double, result["longitude"] as double);
  }
}