import 'package:cwscompass/common/capital_extension.dart';
import 'package:cwscompass/common/theme_colours.dart';
import 'package:cwscompass/data/school.dart' as school;
import 'package:cwscompass/data/structures/structure.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RouteInfo extends StatelessWidget {
  final school.Route route;
  final Interactable? endRoom;

  const RouteInfo({super.key, required this.route, required this.endRoom});

  @override
  Widget build(BuildContext context) {
    const walkingSpeed = 1.3;
    final travelTime = route.path.distance / walkingSpeed;
    final travelTimeMin = (travelTime / 60).round();
    final eta = DateTime.now().add(Duration(seconds: travelTime.round()));
    final formattedEta = DateFormat.Hm().format(eta);
    final endName = endRoom == null ? "my location" : endRoom!.name.capitalise();

    return Material(
      borderRadius: BorderRadius.circular(24.0),
      color: ThemeColours.primary,
      elevation: 4,
      child: Wrap(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Row(
                key: ValueKey(route.start.hashCode + route.end.hashCode),
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "To $endName",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: ThemeColours.lightText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700
                          )
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${travelTimeMin < 1 ? "< 1" : travelTimeMin} min",
                              style: TextStyle(
                                color: ThemeColours.lightText,
                                fontSize: 26.0,
                                fontWeight: FontWeight.w900
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "/ ETA $formattedEta",
                                style: TextStyle(
                                  color: ThemeColours.lightTextTint,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600
                                )
                              )
                            )
                          ],
                        )
                      ]
                    )
                  ),
                  Text(
                    "${route.path.distance.round()}m",
                    style: TextStyle(
                      color: ThemeColours.lightText,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w900
                    ),
                  )
                ],
              )
            )
          )
        ],
      ),
    );
  }
}