import 'package:flutter/material.dart';

class FloatingActionButtonOverlay1 extends StatelessWidget {
  final bool showFAB;
  final VoidCallback onPressed;

  FloatingActionButtonOverlay1({required this.showFAB, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 180.0,
      right: 16.0,
      child: Visibility(
        visible: showFAB,
        child: FloatingActionButton(
          onPressed: onPressed,
          child: Icon(Icons.close),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }
}