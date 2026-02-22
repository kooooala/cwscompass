import 'dart:math';

import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/common/polygon.dart';
import 'package:flutter/material.dart';

// This corresponds to the structure table in the database and is the parent of Building, Room, Toilet and Inaccessible
class Structure extends Polygon {
  final int floor;

  final Color colour;

  Point<double>? _centroid;

  // Centroid only gets calculated when needed
  Point<double> get centroid {
    if (_centroid != null) {
      return _centroid!;
    }

    _centroid = maths.centroid(this);
    return _centroid!;
  }

  Structure(this.floor, this.colour, super.coordinates);

  double distanceFrom(Coordinates coordinates, {bool precise = false}) {
    final distanceFunction = precise ? maths.haversineDistance : maths.fastDistance;
    return distanceFunction(coordinates, maths.pointToCoordinates(centroid, floor));
  }
}

// An interactable is a structure that has an entrance and thus can be navigated to. It can be selected from the map and the search entry allows it to be searched.
abstract class Interactable<T extends Structure> extends Structure {
  final String name;
  final String description;
  final String shortDescription;

  final List<Entrance> entrances;

  MapEntry<String, T> get searchEntry;

  Interactable(super.floor, super.colour, super.coordinates, this.name, this.description, this.shortDescription, this.entrances);
}