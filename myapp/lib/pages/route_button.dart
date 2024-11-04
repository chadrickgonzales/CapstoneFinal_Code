import 'package:flutter/material.dart';

class RouteButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onPressed;

  const RouteButton({
    Key? key,
    required this.isVisible,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isVisible
        ? Positioned(
            bottom: 500,
            right: 20,
            child: FloatingActionButton(
              onPressed: onPressed,
              child: Icon(Icons.route),
            ),
          )
        : SizedBox.shrink(); // Return an empty widget when not visible
  }
}