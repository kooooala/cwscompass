import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/map_data.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationProvider = StreamProvider.autoDispose<Coordinates>((ref) async* {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (!serviceEnabled || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw Exception("Unable to get location");
  }

  final stream = Geolocator.getPositionStream();

  await for (final value in stream) {
    final selected = ref.read(selectedFloorProvider).value;
    final floor = selected ?? FloorSelection(0, 0, 1);

    final location = Coordinates(floor.locationFloor, value.latitude, value.longitude);

    ref.read(mapDataProvider).whenData((mapData) {
      mapData.school.rooms[floor.locationFloor].sort((a, b) {
        return a.distanceFrom(location).compareTo(b.distanceFrom(location));
      });
      mapData.nearbyRooms = mapData.school.rooms[floor.locationFloor].sublist(0, 5);
      debugPrint("Nearby room list updated.");
    });

    yield location;
  }
});