import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'room.dart';

final mapDataProvider = FutureProvider<MapData>((ref) async {
  final mapData = MapData("map.db");
  await mapData.load();
  return mapData;
});

class MapData {
  final String dbName;

  late Database database;
  late List<Room> rooms;

  MapData(this.dbName);

  Future load() async {
    final directory = await getTemporaryDirectory();
    final path = join(directory.path, dbName);

    final data = await rootBundle.load("assets/$dbName");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(path).writeAsBytes(bytes, flush:true);

    database = await openDatabase(path);

    final roomList = await Room.getRoomList(database);
    rooms = await Future.wait(roomList.map((room) async => await Room.fromRoomId(database, room)));
  }
}