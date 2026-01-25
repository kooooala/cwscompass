import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationProvider = StreamProvider.autoDispose<Position>((ref) async* {
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
    yield value;
  }
});

