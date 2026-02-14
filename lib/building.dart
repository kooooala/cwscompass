import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/entrance.dart';
import 'package:cwscompass/structure.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class Building extends Structure {
  Building(super.floor, super.colour, super.name, super.entrances, super.coordinates);

  static Future<List<int>> getBuildingList(Database db) async {
    final queryResults = await db.query("rooms",
        columns: ["room_id"],
        where: "type = ?",
        whereArgs: ["building"]
    );
    return queryResults.map((room) => room["room_id"] as int).toList();
  }

  static Future<Building> fromBuildingId(Database db, int buildingId) async {
    final roomData = (await db.query("rooms",
        columns: ["floor", "colour", "label"],
        where: "room_id = ?",
        whereArgs: [buildingId]
    ))[0];
    final floor = roomData["floor"] as int;
    final label = roomData["label"] as String;

    final vertices = await db.query("room_vertices",
        columns: ["coordinates"],
        where: "room = ?",
        whereArgs: [buildingId],
        orderBy: "sequence"
    );

    final coordinates = await Future.wait(vertices.map((vertex) async =>
        Coordinates.fromCoordinatesId(db, vertex["coordinates"] as int)));

    final colourHex = roomData["colour"] as int;
    final colour = Color.fromARGB(0xFF, colourHex >> 16, (colourHex >> 8) & 0xFF, colourHex & 0xFF);

    final entranceData = await db.query("room_entrances",
        columns: ["label", "coordinates"],
        where: "room = ?",
        whereArgs: [buildingId]
    );
    final entrances = await Future.wait(entranceData.map((entrance) async {
      final coordinates = await Coordinates.fromCoordinatesId(db, entrance["coordinates"] as int);
      final name = entrance["label"] as String == "None" ? null : label;
      return Entrance(floor, coordinates.latitude, coordinates.longitude, name);
    }));

    return Building(
        floor,
        colour,
        label,
        entrances,
        coordinates
    );
  }
}