import 'package:flutter/material.dart';

class NeoButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isVoted; // Controls the voted appearance
  final bool isDisabled; // Disables the button if true
  final int pricePerVote; // If > 0, shows ₦price instead of "Vote"
  final String text; // Optional fallback text

  const NeoButton({
    super.key,
    required this.onTap,
    required this.isVoted,
    required this.isDisabled,
    required this.pricePerVote,
    this.text = "Vote",
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double width = 60;
    const double height = 30;

    final bool isInactive = widget.isDisabled || widget.isVoted;

    final backgroundColor =
        isInactive ? Colors.grey.shade500 : Colors.green[900];

    final fontWeight = isInactive ? FontWeight.normal : FontWeight.bold;

    final List<BoxShadow> boxShadows = isInactive
        ? <BoxShadow>[] // No shadows if inactive
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
                const BoxShadow(
                  color: Colors.green,
                  offset: Offset(-2, -2),
                  blurRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 5,
                ),
              ];

    final String displayText = widget.pricePerVote > 0
        ? '₦${widget.pricePerVote}'
        : (widget.isVoted ? 'Voted' : widget.text);

    return GestureDetector(
      onTapDown: (_) {
        if (!isInactive) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (!isInactive) {
          setState(() => _isPressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!isInactive) {
          setState(() => _isPressed = false);
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
            displayText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: fontWeight,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
