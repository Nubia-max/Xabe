import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/features/community/controller/community_controller.dart';
import 'package:xabe/features/posts/controller/post_controller.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';
import 'package:xabe/core/common/loader.dart';

import '../../core/post_card.dart';

class PremiumElectionScreen extends StatelessWidget {
  const PremiumElectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    final postController = Get.find<PostController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Elections'),
      ),
      body: StreamBuilder<List<Community>>(
        stream: communityController.getAllCommunities(),
        builder: (context, communitySnapshot) {
          if (communitySnapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }
          if (communitySnapshot.hasError) {
            return Text('Error: ${communitySnapshot.error}');
          }

          final allCommunities = communitySnapshot.data ?? [];
          final premiumCommunities = allCommunities
              .where((c) => c.communityType == 'premium')
              .toList();

          if (premiumCommunities.isEmpty) {
            return const Center(child: Text('No premium communities found.'));
          }

          return StreamBuilder<List<Post>>(
            stream: postController.fetchUserPosts(premiumCommunities),
            builder: (context, postSnapshot) {
              if (postSnapshot.connectionState == ConnectionState.waiting) {
                return const Loader();
              }
              if (postSnapshot.hasError) {
                return Text('Error: ${postSnapshot.error}');
              }

              final allPosts = postSnapshot.data ?? [];

              final electionPosts = allPosts
                  .where((post) =>
                      post.type == 'carousel' &&
                      premiumCommunities.any((c) => c.id == post.communityId))
                  .toList()
                ..sort((a, b) =>
                    b.createdAt.compareTo(a.createdAt)); // Newest first

              if (electionPosts.isEmpty) {
                return const Center(
                    child: Text('No election posts in premium communities.'));
              }

              return ListView.builder(
                itemCount: electionPosts.length,
                itemBuilder: (context, index) {
                  final post = electionPosts[index];
                  return PostCard(post: post);
                },
              );
            },
          );
        },
      ),
    );
  }
}
