import 'dart:async';
import 'package:flutter/material.dart';

class ElectionTime extends StatefulWidget {
  final DateTime electionEndTime;

  const ElectionTime({super.key, required this.electionEndTime});

  @override
  _ElectionTimeState createState() => _ElectionTimeState();
}

class _ElectionTimeState extends State<ElectionTime> {
  late Duration _timeRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (!mounted) return;

    setState(() {
      _timeRemaining = widget.electionEndTime.difference(now);
      if (_timeRemaining.isNegative) {
        _timeRemaining = Duration.zero;
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours.remainder(60));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeRemaining > Duration.zero
          ? _formatDuration(_timeRemaining)
          : "Election Over",
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
