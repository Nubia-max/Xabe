import 'package:flutter/material.dart';

class WebPaddingWrapper extends StatelessWidget {
  final Widget child;
  const WebPaddingWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 700) {
      return Center(
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(5),
          child: child,
        ),
      );
    }
    return child;
  }
}
