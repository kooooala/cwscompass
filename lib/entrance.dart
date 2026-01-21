import 'package:cwscompass/coordinates.dart';

class Entrance extends Coordinates {
  final String? label;

  Entrance(super.latitude, super.longitude, this.label);
}