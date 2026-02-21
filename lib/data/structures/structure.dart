import 'dart:math';

import 'package:cwscompass/common/maths.dart' as maths;
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/common/polygon.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class Structure extends Polygon {
  final int floor;

  final Color colour;

  Point<double>? _centroid;

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

abstract class Interactable<T extends Structure> extends Structure {
  final String name;
  final String description;
  final String shortDescription;

  final List<Entrance> entrances;

  MapEntry<String, T> get searchEntry;

  Interactable(super.floor, super.colour, super.coordinates, this.name, this.description, this.shortDescription, this.entrances);
}