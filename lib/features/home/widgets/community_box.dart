import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/features/posts/controller/post_controller.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';
import '../../posts/widgets/neo_button.dart';

class CommunityBox extends StatelessWidget {
  final Community community;
  final String postType; // 'carousel2', 'carousel', 'carousel3'
  final String addButtonText;
  final String emptyMessage;
  final VoidCallback onBoxTap;

  const CommunityBox({
    super.key,
    required this.community,
    required this.postType,
    required this.addButtonText,
    required this.emptyMessage,
    required this.onBoxTap,
  });

  @override
  Widget build(BuildContext context) {
    final postController = Get.find<PostController>();

    return FutureBuilder<List<Post>>(
      future:
          postController.getPostsForCommunityAndType(community.id, postType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 175,
            height: 285,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Container(
            width: 177,
            height: 285,
            alignment: Alignment.center,
            child: Text("Error loading posts: ${snapshot.error}"),
          );
        }
        List<Post> posts = snapshot.data ?? [];
        bool hasPosts = posts.isNotEmpty;

        // Check for a saved thumbnail. For instance, if postType is 'carousel2' use campaignThumbnailUrl.
        String imageUrl = '';
        if (postType == 'carousel2' &&
            community.campaignThumbnailUrl.isNotEmpty) {
          imageUrl = community.campaignThumbnailUrl;
        } else if (postType == 'carousel' &&
            community.electionThumbnailUrl.isNotEmpty) {
          imageUrl = community.electionThumbnailUrl;
        } else if (hasPosts && posts.first.imageUrls.isNotEmpty) {
          // Fallback to the first post image.
          imageUrl = posts.first.imageUrls.first;
        }

        // Use different colors based on the theme brightness.
        final isLightMode = Theme.of(context).brightness == Brightness.light;
        final boxColor = isLightMode
            ? (hasPosts ? Colors.grey.shade100 : Colors.grey.shade200)
            : (hasPosts ? Colors.grey.shade800 : Colors.grey.shade700);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: hasPosts ? onBoxTap : null,
            child: Container(
              width: 169,
              height: 285,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Center(
                    child: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, color: Colors.red),
                            ),
                          )
                        : Text(
                            emptyMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 14),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        // Optionally, add an onTap if you want this button to perform an action
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 4),
                              Text(
                                addButtonText,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Only show the vote button if postType is "carousel" and there are posts.
                  if (postType == 'carousel' && hasPosts)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: NeoButton(
                        text: "Vote",
                        isVoted: false,
                        isDisabled: false, // or true based on your logic
                        pricePerVote: 0, // or fetch from post if available
                        onTap: () {
                          navigateToCommunityWithFilter('carousel');
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void navigateToCommunityWithFilter(String filter) {
    // Navigate to the route "/X/:name" with a parameter "filter".
    Get.toNamed('/X/${community.id}', parameters: {'filter': filter});
  }
}
