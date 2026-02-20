import 'dart:ui';

import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/data/entrance.dart';
import 'package:cwscompass/data/school.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/structures/structure.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum ToiletType {
  gents, ladies, genderNeutral, accessible, staff
}

class Toilet extends Interactable<Toilet> {
  final ToiletType type;

  @override
  MapEntry<String, Toilet> get searchEntry => MapEntry("toilet$name${toiletTypeString(type)}${Floor.floorString(floor)}", this);

  Toilet(int floor, Color colour, List<Coordinates> coordinates, String? name, Entrance entrance, this.type)
      : super(floor, colour, coordinates, name ?? toiletName(type), "${toiletTypeString(type)} • ${Floor.floorString(floor)}", toiletTypeString(type), [entrance]);

  static String toiletName(ToiletType type) {
    return "${toiletTypeString(type)} toilet";
  }

  static IconData toiletTypeIcon(ToiletType type) {
    return switch (type) {
      ToiletType.gents => Icons.man,
      ToiletType.ladies => Icons.woman,
      ToiletType.genderNeutral => Icons.wc,
      ToiletType.accessible => Icons.accessible,
      ToiletType.staff => Icons.wc
    };
  }

  static Color toiletTypeColour(ToiletType type) {
    return switch (type) {
      ToiletType.gents => ThemeColours.maleToilet,
      ToiletType.ladies => ThemeColours.femaleToilet,
      _ => ThemeColours.darkText
    };
  }

  static String toiletTypeString(ToiletType type) {
    if (type == ToiletType.genderNeutral) {
      return "gender neutral";
    } else {
      return type.name;
    }
  }
}