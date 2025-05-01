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
    const double maxBarWidth = 250.0; // Increase the bar width
    const double nameWidth = 80.0;

    // Color Palette for bars: Can be expanded as needed
    List<Color> barColors = [
      Colors.blue.shade700,
      Colors.red.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
      Colors.indigo.shade700,
      Colors.amber.shade700,
      Colors.pink.shade700,
      Colors.cyan.shade700,
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(votesSummary.length, (index) {
          double vote = votesSummary[index];
          double barWidth = maxVote > 0 ? (vote / maxVote) * maxBarWidth : 0;

          List<String> nameParts = taggedUsers[index].split(' ');
          String firstName =
              nameParts.isNotEmpty ? nameParts.first : taggedUsers[index];
          String secondName =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          // Cycle through the color palette dynamically
          Color barColor = barColors[index % barColors.length];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name column with fixed width.
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
                // Bar section expands based on vote count.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barMaxWidth = constraints.maxWidth;
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
                              color: barColor, // Apply the dynamic color
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
                                  color: Colors.grey,
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
