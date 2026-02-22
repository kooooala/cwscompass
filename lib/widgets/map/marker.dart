import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/data/coordinates.dart';
import 'package:cwscompass/data/location.dart';
import 'package:cwscompass/widgets/map/canvas.dart';
import 'package:cwscompass/data/school.dart';
import 'package:cwscompass/widgets/map/selected_floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class Marker extends ConsumerWidget {
  final double size;
  final TransformationController transformations;

  final School school;

  const Marker(this.size, this.transformations, this.school, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(locationProvider).when(
      data: (location) => ref.watch(selectedFloorProvider).when(
        data: (selected) {
          if (location.floor != selected.viewFloor) {
            return const SizedBox.shrink();
          }

          final point = location.point;
          return ListenableBuilder(
            listenable: transformations,
            builder: (_, _) {
              final scale = transformations.value.getMaxScaleOnAxis();
              return Positioned(
                top: point.y,
                left: point.x,
                child: FractionalTranslation(
                  translation: Offset(-0.5, -0.5),
                  child: Transform.scale(
                    scale: 1.0 / scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PhysicalModel(
                          shape: BoxShape.circle,
                          color: ThemeColours.primary,
                          elevation: 1.0 / scale,
                          child: SizedBox(width: size, height: size),
                        ),
                        Container(
                          width: size * 0.6,
                          height: size * 0.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white
                          ),
                        )
                      ]
                    )
                  ),
                ),
              );
            }
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (object, stack) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (object, stack) => const SizedBox.shrink(),
    );
  }
}