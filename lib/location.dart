import 'dart:async';

import 'package:cwscompass/coordinates.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationProvider = FutureProvider<Location>((ref) async {
  final location = Location();
  await location.load();
  return location;
});

class Location {
  late bool serviceEnabled;
  late LocationPermission permission;

  late Position position;

  late StreamSubscription<Position> stream;

  Future load() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();

    if (!serviceEnabled || (permission != LocationPermission.always && permission != LocationPermission.whileInUse)) {
      return Future.error("Unable to get location");
    }

    position = await Geolocator.getCurrentPosition();
    Geolocator.getPositionStream().listen((position) {
      this.position = position;
    });
  }
}
