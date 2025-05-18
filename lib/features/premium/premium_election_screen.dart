import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/features/community/controller/community_controller.dart';
import 'package:xabe/features/posts/controller/post_controller.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';

import '../../core/post_card.dart';

class PremiumElectionScreen extends StatefulWidget {
  const PremiumElectionScreen({super.key});

  @override
  State<PremiumElectionScreen> createState() => _PremiumElectionScreenState();
}

class _PremiumElectionScreenState extends State<PremiumElectionScreen> {
  final PostController _postController = Get.find<PostController>();
  final CommunityController _communityController =
      Get.find<CommunityController>();

  List<Post> premiumElectionPosts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPremiumElectionPosts();
  }

  Future<void> fetchPremiumElectionPosts() async {
    setState(() => isLoading = true);
    try {
      List<Community> allCommunities =
          await _communityController.getAllCommunitiesFuture();
      List<Community> premiumCommunities = allCommunities
          .where((community) => community.communityType == 'premium')
          .toList();

      List<Post> allPosts = [];

      for (Community community in premiumCommunities) {
        List<Post> posts = await _postController.getPostsForCommunityAndType(
          community.id,
          'carousel',
        );
        allPosts.addAll(posts);
      }

      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        premiumElectionPosts = allPosts;
      });
    } catch (e) {
      debugPrint("Error fetching premium posts: $e");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Elections"),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPremiumElectionPosts,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : premiumElectionPosts.isEmpty
                ? const Center(child: Text("No premium election posts found."))
                : ListView.builder(
                    itemCount: premiumElectionPosts.length,
                    itemBuilder: (context, index) {
                      return PostCard(post: premiumElectionPosts[index]);
                    },
                  ),
      ),
    );
  }
}
