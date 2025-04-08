import 'package:flutter/material.dart';

class MobileScreenLayout extends StatelessWidget {
  final Widget child;
  const MobileScreenLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // For mobile, simply return the provided child.
    return Scaffold(
      body: child,
    );
  }
}
