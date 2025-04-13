import 'package:flutter/material.dart';

class MyHorizontalBarGraph extends StatelessWidget {
  final List<double> votesSummary;
  final List<String> taggedUsers;

  const MyHorizontalBarGraph({
    super.key,
    required this.votesSummary,
    required this.taggedUsers,
  });

  @override
  Widget build(BuildContext context) {
    // Find the maximum vote count to scale the bars.
    double maxVote = votesSummary.isNotEmpty
        ? votesSummary.reduce((a, b) => a > b ? a : b)
        : 1;
    // Increase the maximum bar width to extend the length of the graph.
    const double maxBarWidth = 250.0;
    // Define the fixed width for the name container.
    const double nameWidth = 80.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(votesSummary.length, (index) {
          double vote = votesSummary[index];
          // Calculate proportional width for the bar.
          double barWidth = maxVote > 0 ? (vote / maxVote) * maxBarWidth : 0;

          // Split the tagged user's name into two parts if possible.
          List<String> nameParts = taggedUsers[index].split(' ');
          String firstName =
              nameParts.isNotEmpty ? nameParts.first : taggedUsers[index];
          String secondName =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fixed width for name column.
                SizedBox(
                  width: nameWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (secondName.isNotEmpty)
                        Text(
                          secondName,
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bar section expands to available space.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barMaxWidth = constraints.maxWidth;
                      // Calculate bar width proportionally.
                      double vote = votesSummary[index];
                      double barWidth =
                          maxVote > 0 ? (vote / maxVote) * barMaxWidth : 0;

                      return Stack(
                        children: [
                          Container(
                            height: 20,
                            width: barWidth,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade700,
                                  Colors.cyan,
                                  Colors.cyanAccent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Text(
                                vote.toInt().toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  // Color for highest vote is purple (adjust if needed).
                                  color: vote == maxVote
                                      ? Colors.purple
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
