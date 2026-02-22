import 'dart:async';

import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:cwscompass/widgets/map/selected_floor.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_data.dart';

// Use the Geolocator library to get the device's current location. This is not used by other parts of the program as it does not have floor data.
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

// Combine the current location from rawLocationProvider and the currently selected floor
final locationProvider = FutureProvider.autoDispose<Coordinates>((ref) async {
  final location = await ref.watch(rawLocationProvider.future);
  final floor = await ref.watch(selectedFloorProvider.future);
  return Coordinates(floor.locationFloor, location.latitude, location.longitude);
});

// Listen to the current location and provide a list of 5 interactables closest to the current location
final nearbyInteractablesProvider = FutureProvider.autoDispose<List<Interactable>>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final mapData = await ref.watch(mapDataProvider.future);

  final interactables = mapData.school.floors[location.floor].structures.whereType<Interactable>().toList();
  interactables.sort((a, b) {
    return a.distanceFrom(location).compareTo(b.distanceFrom(location));
  });
  debugPrint("Nearby room list updated.");
  return interactables.sublist(0, 5);
});