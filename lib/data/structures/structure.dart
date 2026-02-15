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
    final distanceFunction = precise ? maths.haversineDistance : maths.equirectangularDistance;
    return distanceFunction(coordinates, maths.pointToCoordinates(centroid, floor));
  }

  // Check if point is inside polygon by using the ray casting algorithm: https://people.utm.my/shahabuddin/?p=6277
  bool intersects(Point<double> point) {
    // Quickly check if point is within bounding box
    if (point.x < boundingBox.topLeft.x || point.x > boundingBox.bottomRight.x ||
        point.y < boundingBox.topLeft.y || point.y > boundingBox.bottomRight.y) {
      return false;
    }

    int intersections = 0;

    for (int i = 0; i < coordinates.length; i++) {
      final current = coordinates[i].point;
      final next = coordinates[(i + 1) % coordinates.length].point;

      if (((current.y > point.y) != (next.y > point.y)) && (point.x < (next.x - current.x) * (point.y - current.y) / (next.y - current.y) + current.x)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }
}

abstract class Interactable<T extends Structure> extends Structure {
  final String name;
  final String description;

  final List<Entrance> entrances;

  MapEntry<String, T> get searchEntry;

  Interactable(super.floor, super.colour, super.coordinates, this.name, this.description, this.entrances);
}