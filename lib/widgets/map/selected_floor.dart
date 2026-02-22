import 'dart:async';

import 'package:cwscompass/data/map_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FloorSelection {
  // View floor is the floor the map canvas is displaying
  // Location floor is the floor the location is on
  // The two are same most of the time except when in the route preview page, where changing the floor with the FloorSelector widget changes only the view floor to allow the user to select any room on the map.
  final int viewFloor, locationFloor;
  final int floorCount;

  FloorSelection(this.viewFloor, this.locationFloor, this.floorCount);
}

class SelectedFloorProvider extends AsyncNotifier<FloorSelection> {
  @override
  FutureOr<FloorSelection> build() async {
    final data = await ref.watch(mapDataProvider.future);
    return FloorSelection(0, 0, data.school.floors.length);
  }

  void setView(int floor) {
    final old = state.value;

    if (old != null) {
      state = AsyncData(FloorSelection(floor, old.locationFloor, old.floorCount));
    }
  }

  void setLocation(int floor) {
    final old = state.value;

    if (old != null) {
      state = AsyncData(FloorSelection(old.viewFloor, floor, old.floorCount));
    }
  }
}

final selectedFloorProvider = AsyncNotifierProvider<SelectedFloorProvider, FloorSelection>(SelectedFloorProvider.new);