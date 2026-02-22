import 'package:cwscompass/data/structures/building.dart';
import 'package:cwscompass/data/structures/inaccessible.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/structures/toilet.dart';
import 'package:cwscompass/data/school.dart';
import 'package:cwscompass/data/staircase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'entrance.dart';
import 'path.dart';
import 'structures/room.dart';

// Load the map data from map.db
final mapDataProvider = FutureProvider<MapData>((ref) async {
  ref.keepAlive();

  final mapData = MapData("map.db");
  await mapData.load();

  return mapData;
});

class MapData {
  final String dbName;

  late Database _database;
  late School school;

  // Dictionary/map that maps coordinatesId -> parsed coordinates
  late Map<int, Coordinates> _coordinates;

  MapData(this.dbName);

  // Read from the coordinates table and use the data to populate _coordinates
  Future<void> parseCoordinates() async {
    final results = await _database.query("coordinates",
        columns: ["coordinates_id", "latitude", "longitude", "floor"]
    );
    
    _coordinates = Map.fromEntries(results.map((row) =>
      MapEntry(
        row["coordinates_id"] as int,
        Coordinates(
          row["floor"] as int,
          row["latitude"] as double,
          row["longitude"] as double
        )
      )
    ));
  }
  
  Future<Structure> parseStructure(Map<String, Object?> structureData) async {
    final structureId = structureData["structure_id"] as int;

    final floor = structureData["floor"] as int;
    
    final colourHex = structureData["colour"] as int;
    // Colour is stored in the database in the format: RRRR RRRR  GGGG GGGG  BBBB BBBB (each character represents a bit)
    final colour = Color.fromARGB(0xFF, colourHex >> 16, (colourHex >> 8) & 0xFF, colourHex & 0xFF);

    final vertices = await _database.query("structure_vertices",
      columns: ["coordinates"],
      where: "structure = ?",
      whereArgs: [structureId],
      orderBy: "sequence"
    );

    // The lambda function passed to map extracts the coordinates column from the structure vertex and use it as a key to look up the coordinates
    return Structure(floor, colour, vertices.map((v) => _coordinates[v["coordinates"] as int]!).toList());
  }

  Future<List<Entrance>> parseEntrances(int structureId, String structureLabel) async {
    final entranceData = await _database.query("entrances",
        columns: ["label", "coordinates"],
        where: "structure = ?",
        whereArgs: [structureId]
    );

    final entrances = entranceData.map((entrance) {
      final coordinates = _coordinates[entrance["coordinates"] as int]!;
      final name = entrance["label"] as String == "None" ? null : structureLabel;
      return Entrance(coordinates.floor, coordinates.latitude, coordinates.longitude, name);
    }).toList();

    return entrances;
  }
  
  Future<Room> parseRoom(Map<String, Object?> roomData) async {
    final structureId = roomData["structure_id"] as int;
    final structure = await parseStructure(roomData);

    final number = roomData["number"] as String;
    final label = roomData["label"] as String;

    final entrances = await parseEntrances(structureId, label);

    return Room(
      structure.floor,
      structure.colour,
      roomData["subject"] as String,
      // "None" is how null data is stored in the database, due to the conversion script being written in Python
      number == "None" ? null : number,
      label == "None" ? null : label,
      entrances,
      structure.coordinates,
    );
  }

  Future<Toilet> parseToilet(Map<String, Object?> toiletData) async {
    final structureId = toiletData["structure_id"] as int;
    final structure = await parseStructure(toiletData);

    final type = switch (toiletData["toilet_type"] as String) {
      "male" => ToiletType.gents,
      "female" => ToiletType.ladies,
      "gender_neutral" => ToiletType.genderNeutral,
      "accessible" => ToiletType.accessible,
      "staff" => ToiletType.staff,
      _ => throw Exception("Unknown toilet type")
    };

    final label = toiletData["label"] as String;

    final entrance = await parseEntrances(structureId, label);

    return Toilet(
      structure.floor,
      structure.colour,
      structure.coordinates,
      label == "None" ? null : label,
      entrance.first, // There should be only one entrance (it's a toilet)
      type
    );
  }

  Future<Building> parseBuilding(Map<String, Object?> buildingData) async {
    final structureId = buildingData["structure_id"] as int;
    final structure = await parseStructure(buildingData);

    final label = buildingData["label"] as String;

    final entrances = await parseEntrances(structureId, label);

    return Building(
      structure.floor,
      structure.colour,
      structure.coordinates,
      label,
      entrances
    );
  }

  Future<List<Structure>> parseStructures() async {
    final results = await _database.query("structures");

    List<Structure> structures = [];
    for (final row in results) {
      switch (row["type"] as String) {
        case "room":
          structures.add(await parseRoom(row));
          break;
        case "building":
          structures.add(await parseBuilding(row));
          break;
        case "inaccessible":
          // I didn't write a specific function to parse inaccessible areas since they are just structures
          final structure = await parseStructure(row);
          structures.add(Inaccessible(structure.floor, structure.colour, structure.coordinates));
          break;
        case "toilet":
          structures.add(await parseToilet(row));
          break;
      }
    }

    return structures;
  }

  Future load() async {
    // Copy the database file from assets to the temporary directory and open it
    final directory = await getTemporaryDirectory();
    final path = join(directory.path, dbName);

    final data = await rootBundle.load("assets/$dbName");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(path).writeAsBytes(bytes, flush:true);

    _database = await openDatabase(path);

    await parseCoordinates();

    final pathList = await Path.getPathList(_database);
    // Future.wait takes in a list of futures and waits for them complete, returning their results in a list
    final paths = await Future.wait(pathList.map((path) async => await Path.fromPathId(_database, path)));

    final structures = await parseStructures();

    final staircaseList = await Staircase.getStaircaseList(_database);
    final staircases = await Future.wait(staircaseList.map((staircase) async => await Staircase.fromStaircaseId(_database, staircase)));

    school = School(structures, paths, staircases);
  }
}