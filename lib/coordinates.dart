import 'package:cwscompass/common/maths.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

class Coordinates extends Equatable {
  final int floor;

  final double latitude;
  final double longitude;

  final Point<double> point;

  Coordinates(this.floor, this.latitude, this.longitude) : point = coordinatesToPoint(latitude, longitude);

  @override
  List<Object> get props => [latitude, longitude];

  @override
  String toString() => "($latitude, $longitude)";

  static Future<Coordinates> fromCoordinatesId(Database db, int coordinatesId) async {
    final result = (await db.query("coordinates",
        columns: ["latitude", "longitude", "floor"],
        where: "coordinates_id = ?",
        whereArgs: [coordinatesId]))[0];
    return Coordinates(result["floor"] as int, result["latitude"] as double, result["longitude"] as double);
  }
}