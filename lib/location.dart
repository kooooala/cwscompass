import 'dart:async';

import 'package:cwscompass/coordinates.dart';
import 'package:cwscompass/map/canvas.dart';
import 'package:cwscompass/room.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_data.dart';

final rawLocationProvider = StreamProvider.autoDispose<Coordinates>((ref) async* {
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
    yield Coordinates(-1, value.latitude, value.longitude);
  }
});

final locationProvider = FutureProvider.autoDispose<Coordinates>((ref) async {
  final location = await ref.watch(rawLocationProvider.future);
  final floor = await ref.watch(selectedFloorProvider.future);
  return Coordinates(floor.locationFloor, location.latitude, location.longitude);
});

final nearbyRoomsProvider = FutureProvider.autoDispose<List<Room>>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final mapData = await ref.watch(mapDataProvider.future);

  mapData.school.rooms[location.floor].sort((a, b) {
    return a.distanceFrom(location).compareTo(b.distanceFrom(location));
  });
  debugPrint("Nearby room list updated.");
  return mapData.school.rooms[location.floor].sublist(0, 5);
});