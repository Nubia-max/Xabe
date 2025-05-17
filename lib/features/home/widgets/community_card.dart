import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/features/home/widgets/community_box.dart';
import 'package:xabe/features/posts/controller/post_controller.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';

class CommunityCard extends StatelessWidget {
  final Community community;

  const CommunityCard({super.key, required this.community});

  /// Navigate to the community screen with a filter parameter.
  void navigateToCommunityWithFilter(String filter) {
    // Navigate to the route "/X/:name" with a parameter "filter".
    Get.toNamed('/X/${community.id}', parameters: {'filter': filter});
  }

  /// Navigate to the add-post screen for a given post type.
  void navigateToType(String type) {
    Get.toNamed('/add-post/$type', parameters: {'community': community.name});
  }

  /// Helper to format a Duration into a short string like "2h 10m"
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    String formatted = '';
    if (hours > 0) formatted += '${hours}h ';
    formatted += '${minutes}m';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final bool isModerator = authController.isModerator(community);

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with fixed height.
            SizedBox(
              height: 40, // Fixed header height to avoid increasing card height
              child: Stack(
                children: [
                  // Community name and more options.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        community.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (community.communityType == 'premium') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (value) {
                          if (value == 'campaign') {
                            navigateToType('carousel2');
                          } else if (value == 'elections') {
                            navigateToType('carousel');
                          } else if (value == 'thumbnails') {
                            Get.toNamed('/add-thumbnails',
                                parameters: {'community': community.id});
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'campaign',
                              child: Row(
                                children: const [
                                  SizedBox(width: 8),
                                  Text('Campaign here'),
                                ],
                              ),
                            ),
                            if (isModerator)
                              PopupMenuItem<String>(
                                value: 'elections',
                                child: Row(
                                  children: const [
                                    SizedBox(width: 8),
                                    Text('Conduct elections'),
                                  ],
                                ),
                              ),
                            if (isModerator)
                              PopupMenuItem<String>(
                                value: 'thumbnails',
                                child: Row(
                                  children: const [
                                    Icon(Icons.image, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text('Thumbnails'),
                                  ],
                                ),
                              ),
                          ];
                        },
                      ),
                    ],
                  ),
                  // Election hint text positioned at the bottom left of the header.
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: FutureBuilder<List<Post>>(
                      future: Get.find<PostController>()
                          .getPostsForCommunityAndType(
                              community.id, 'carousel'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            snapshot.hasError) {
                          return const SizedBox.shrink();
                        }
                        List<Post> electionPosts = snapshot.data ?? [];
                        final now = DateTime.now();
                        // Filter out posts whose election has ended.
                        electionPosts = electionPosts
                            .where((post) =>
                                post.electionEndTime != null &&
                                post.electionEndTime!.isAfter(now))
                            .toList();
                        if (electionPosts.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        // Sort posts by end time ascending.
                        electionPosts.sort((a, b) =>
                            a.electionEndTime!.compareTo(b.electionEndTime!));
                        // Use only the first (earliest ending) election.
                        final remainingTime = _formatDuration(electionPosts
                            .first.electionEndTime!
                            .difference(now));
                        String hintText = "Election ends in $remainingTime";
                        return Text(
                          hintText,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Row of boxes below header.
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 190 / 300, // maintains consistent shape
                    child: CommunityBox(
                      community: community,
                      postType: 'carousel2',
                      addButtonText: 'Campaigns',
                      emptyMessage: 'No campaign found.',
                      onBoxTap: () =>
                          navigateToCommunityWithFilter('carousel2'),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // spacing between boxes
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 190 / 300,
                    child: CommunityBox(
                      community: community,
                      postType: 'carousel',
                      addButtonText: 'Elections',
                      emptyMessage: 'No live election.',
                      onBoxTap: () => navigateToCommunityWithFilter('carousel'),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
