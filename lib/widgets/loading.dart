import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final Color colour;
  
  const Loading({super.key, required this.colour});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: colour)
      ],
    );
  }
}