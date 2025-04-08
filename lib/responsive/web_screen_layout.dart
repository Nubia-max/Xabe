import 'package:flutter/material.dart';
import 'web_padding_wrapper.dart';

class WebScreenLayout extends StatelessWidget {
  final Widget child;
  const WebScreenLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // On the web, show a permanent side drawer and wrap content with extra padding.
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: WebPaddingWrapper(child: child),
          ),
        ],
      ),
    );
  }
}
