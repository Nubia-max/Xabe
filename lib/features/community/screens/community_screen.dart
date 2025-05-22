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
  PostFilter selectedFilter = PostFilter.all;

  final authController = Get.find<AuthController>();
  final communityController = Get.find<CommunityController>();

  @override
  void initState() {
    super.initState();
    final filterParam = Get.parameters['filter'];
    if (filterParam == 'carousel2') {
      selectedFilter = PostFilter.campaign;
    } else if (filterParam == 'carousel') {
      selectedFilter = PostFilter.elections;
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {});
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      return AssetImage(imageUrl);
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

    final docStream = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .snapshots();

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }

          final docSnap = snapshot.data;
          if (docSnap == null || !docSnap.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Only navigate if still on this community screen
              final currentRoute = Get.currentRoute;
              if (currentRoute.contains(widget.communityId)) {
                Get.offAllNamed('/');
                Get.snackbar(
                  'Deleted',
                  'This community has been deleted.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            });
            return const Scaffold();
          }

          final data = docSnap.data()!;
          final community = Community.fromMap(data);

          final isGuest = !user.isAuthenticated;
          final isMod = community.mods.contains(user.uid);
          final isPremium = community.communityType == 'premium';

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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: community.avatar.isEmpty
                                    ? const AssetImage('assets/images/logo.png')
                                    : getImageProvider(community.avatar),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      community.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (isPremium) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[700],
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                                  ],
                                ),
                              ),
                              if (isPremium && isMod)
                                StreamBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('communities')
                                      .doc(community.id)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData ||
                                        snapshot.hasError) {
                                      return const SizedBox();
                                    }
                                    final communityData = snapshot.data!.data();
                                    if (communityData == null)
                                      return const SizedBox();

                                    final balanceRaw =
                                        communityData['balance'] ?? 0;
                                    final balance = (balanceRaw is int)
                                        ? balanceRaw.toDouble()
                                        : balanceRaw as double;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green[600],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '₦${balance.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
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
                                    final isMember =
                                        community.members.contains(user.uid);
                                    final isPending = community.pendingMembers
                                        .contains(user.uid);

                                    if (isMember) {
                                      final shouldLeave =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Leave Community"),
                                          content: Text(
                                              "Are you sure you want to leave ${community.name}?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text("Leave",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldLeave == true) {
                                        await communityController
                                            .leaveCommunity(
                                                community, user.uid);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'You have left ${community.name}'),
                                          ),
                                        );
                                      }
                                    } else {
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
                                        : community.pendingMembers
                                                .contains(user.uid)
                                            ? 'Pending'
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
                        return ErrorText(error: postSnapshot.error.toString());
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
                      return RefreshIndicator(
                        onRefresh: _refreshPosts,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final post = filtered[i];

                            if (user.blockedUsers.contains(post.uid)) {
                              return const SizedBox.shrink();
                            }

                            return PostCard(post: post);
                          },
                        ),
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
