import 'package:flutter/material.dart';

class NeoButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final bool isVoted; // Control the "voted" state

  const NeoButton({
    Key? key,
    required this.onTap,
    this.text = "Vote",
    this.isVoted = false,
  }) : super(key: key);

  @override
  _NeoButtonState createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double width = 60;
    const double height = 30;

    final backgroundColor =
        widget.isVoted ? Colors.grey.shade500 : Colors.green[900];
    final fontWeight = widget.isVoted ? FontWeight.normal : FontWeight.bold;
    final List<BoxShadow> boxShadows = widget.isVoted
        ? <BoxShadow>[] // No shadows if already voted.
        : _isPressed
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.greenAccent,
                  offset: const Offset(4, 4),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.grey.shade800,
                  offset: const Offset(-2, -2),
                  blurRadius: 1,
                  spreadRadius: 1,
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.green,
                  offset: const Offset(-2, -2),
                  blurRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black,
                  offset: const Offset(2, 2),
                  blurRadius: 5,
                ),
              ];

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isVoted) {
          setState(() {
            _isPressed = true;
          });
        }
      },
      onTapUp: (_) {
        if (!widget.isVoted) {
          setState(() {
            _isPressed = false;
          });
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!widget.isVoted) {
          setState(() {
            _isPressed = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: boxShadows,
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
