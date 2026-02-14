import 'package:cwscompass/building.dart';
import 'package:cwscompass/structure.dart';
import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/location.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/map/school.dart';
import 'package:cwscompass/staircase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'path.dart';
import 'room.dart';

final mapDataProvider = FutureProvider<MapData>((ref) async {
  final mapData = MapData("map.db");
  await mapData.load();

  return mapData;
});

class MapData {
  final String dbName;

  late Database database;
  late School school;

  MapData(this.dbName);

  Future load() async {
    final directory = await getTemporaryDirectory();
    final path = join(directory.path, dbName);

    final data = await rootBundle.load("assets/$dbName");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(path).writeAsBytes(bytes, flush:true);

    database = await openDatabase(path);

    final pathList = await Path.getPathList(database);
    final paths = await Future.wait(pathList.map((path) async => await Path.fromPathId(database, path)));

    final roomList = await Room.getRoomList(database);
    final rooms = await Future.wait(roomList.map((room) async => await Room.fromRoomId(database, room)));

    final buildingList = await Building.getBuildingList(database);
    final buildings = await Future.wait(buildingList.map((building) async => await Building.fromBuildingId(database, building)));

    final staircaseList = await Staircase.getStaircaseList(database);
    final staircases = await Future.wait(staircaseList.map((staircase) async => await Staircase.fromStaircaseId(database, staircase)));

    school = School(rooms, buildings, paths, staircases);
  }
}