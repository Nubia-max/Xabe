import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xabe/features/community/controller/community_controller.dart';
import 'package:xabe/features/posts/controller/post_controller.dart';
import 'package:xabe/models/post_model.dart';
import '../../core/post_card.dart';
import 'package:async/async.dart';

class PremiumElectionScreen extends StatefulWidget {
  const PremiumElectionScreen({super.key});

  @override
  State<PremiumElectionScreen> createState() => _PremiumElectionScreenState();
}

class _PremiumElectionScreenState extends State<PremiumElectionScreen> {
  final PostController _postController = Get.find<PostController>();
  final CommunityController _communityController =
      Get.find<CommunityController>();

  List<String> _premiumCommunityIds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPremiumCommunities();
  }

  Future<void> loadPremiumCommunities() async {
    setState(() => isLoading = true);
    try {
      final allCommunities =
          await _communityController.getAllCommunitiesFuture();
      final premiumCommunities =
          allCommunities.where((c) => c.communityType == 'premium').toList();
      _premiumCommunityIds = premiumCommunities.map((c) => c.id).toList();
    } catch (e) {
      debugPrint("Error loading premium communities: $e");
      _premiumCommunityIds = [];
    }
    setState(() => isLoading = false);
  }

  Stream<List<Post>> getPremiumElectionPostsStream() {
    if (_premiumCommunityIds.isEmpty) {
      return Stream.value([]);
    }

    final List<Stream<List<Post>>> chunks = [];

    // Firestore whereIn has a 10-item limit — split if needed
    for (int i = 0; i < _premiumCommunityIds.length; i += 10) {
      final sublist = _premiumCommunityIds.skip(i).take(10).toList();

      final chunkStream = FirebaseFirestore.instance
          .collection('posts')
          .where('communityId', whereIn: sublist)
          .where('type', isEqualTo: 'carousel')
          .where('allowNonMembersToVote', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
              .toList());

      chunks.add(chunkStream);
    }

    return StreamZip(chunks).map((listOfLists) =>
        listOfLists.expand((list) => list).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> refresh() async {
    await loadPremiumCommunities();
  }

  void _onVoteSuccess(Post updatedPost) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Elections")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Post>>(
              stream: getPremiumElectionPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Center(
                      child: Text("No premium election posts found."));
                }

                return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: posts[index],
                        onVoteSuccess: _onVoteSuccess,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
