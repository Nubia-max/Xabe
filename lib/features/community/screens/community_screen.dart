import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/core/post_card.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/features/community/controller/community_controller.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';
import 'join_community_verification_screen.dart';

// Extend the filter enum to include campaign and news.
enum PostFilter { all, elections, campaign }

class CommunityScreen extends StatefulWidget {
  final String communityId;
  final String filter;

  const CommunityScreen({
    super.key,
    required this.communityId,
    this.filter = '',
  });

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Filter state.
  PostFilter selectedFilter = PostFilter.all;

  // Controllers.
  final authController = Get.find<AuthController>();
  final communityController = Get.find<CommunityController>();

  @override
  void initState() {
    super.initState();
    // Apply initial filter from route params, if any.
    final filterParam = Get.parameters['filter'];
    if (filterParam == 'carousel2') {
      selectedFilter = PostFilter.campaign;
    } else if (filterParam == 'carousel') {
      selectedFilter = PostFilter.elections;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.userModel.value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in.")),
      );
    }

    // Listen to the raw document so we can detect deletion.
    final docStream = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .snapshots();

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docStream,
        builder: (context, snapshot) {
          // 1) Firestore error?
          if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          }

          // 2) Still loading?
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }

          final docSnap = snapshot.data;
          // 3) Document deleted or never existed
          if (docSnap == null || !docSnap.exists) {
            // Navigate away & show feedback once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // If already popped, skip
              if (Get.currentRoute != '/') {
                Get.offAllNamed('/');
                Get.snackbar(
                  'Deleted',
                  'This community has been deleted.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            });
            // Render an empty scaffold while we transition
            return const Scaffold();
          }

          // 4) Document exists: build your Community object
          // RIGHT: pass only the map
          final data = docSnap.data()! as Map<String, dynamic>;
          final community = Community.fromMap(
              data); // :contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}

          final isGuest = !user.isAuthenticated;
          final isMod = community.mods.contains(user.uid);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 10,
                floating: true,
                snap: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: community.avatar.isEmpty
                                ? const AssetImage('assets/images/logo.png')
                                : getImageProvider(community.avatar),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                community.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isGuest && isMod)
                                OutlinedButton(
                                  onPressed: () {
                                    Get.toNamed(
                                      '/mod-tools/${Uri.encodeComponent(widget.communityId)}',
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 25),
                                  ),
                                  child: const Text('Mod Tools'),
                                )
                              else
                                OutlinedButton(
                                  onPressed: () async {
                                    if (!community.requiresVerification) {
                                      await communityController
                                          .joinCommunityImmediately(
                                        community,
                                        user.uid,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'You have joined ${community.name}'),
                                        ),
                                      );
                                    } else {
                                      Get.to(
                                        () => JoinCommunityVerificationScreen(
                                          community: community,
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 25),
                                  ),
                                  child: Text(
                                    community.members.contains(user.uid)
                                        ? 'Joined'
                                        : 'Join',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text("Filter: "),
                              DropdownButton<PostFilter>(
                                value: selectedFilter,
                                items: const [
                                  DropdownMenuItem(
                                    value: PostFilter.all,
                                    child: Text("All Posts"),
                                  ),
                                  DropdownMenuItem(
                                    value: PostFilter.elections,
                                    child: Text("Elections"),
                                  ),
                                  DropdownMenuItem(
                                    value: PostFilter.campaign,
                                    child: Text("Campaigns"),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedFilter = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          if (community.bio.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                community.bio,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text('${community.members.length} members'),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
            body: community.members.contains(user.uid)
                ? StreamBuilder<List<Post>>(
                    stream: communityController
                        .getCommunityPosts(widget.communityId),
                    builder: (ctx, postSnapshot) {
                      if (postSnapshot.hasError) {
                        return ErrorText(
                          error: postSnapshot.error.toString(),
                        );
                      }
                      if (!postSnapshot.hasData) return const Loader();

                      final posts = postSnapshot.data!;
                      final filtered = switch (selectedFilter) {
                        PostFilter.campaign =>
                          posts.where((p) => p.type == 'carousel2').toList(),
                        PostFilter.elections =>
                          posts.where((p) => p.type == 'carousel').toList(),
                        _ => posts,
                      };

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text("No posts available."),
                        );
                      }
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => PostCard(post: filtered[i]),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      community.pendingMembers.contains(user.uid)
                          ? 'Your join request is pending approval.'
                          : 'Join the community to view posts.',
                    ),
                  ),
          );
        },
      ),
    );
  }
}
