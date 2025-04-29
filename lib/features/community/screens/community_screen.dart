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

  const CommunityScreen(
      {super.key, required this.communityId, this.filter = ''});

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
    // Check for filter parameter from the route.
    final filterParam = Get.parameters['filter'];
    if (filterParam != null) {
      if (filterParam == 'carousel2') {
        selectedFilter = PostFilter.campaign;
      } else if (filterParam == 'carousel') {
        selectedFilter = PostFilter.elections;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityStream =
        communityController.getCommunityById(widget.communityId);
    final user = authController.userModel.value;

    // Early return if user is null.
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in.")),
      );
    }

    final isGuest = !user.isAuthenticated;
    final currentTheme = Theme.of(context);

    return Scaffold(
      body: StreamBuilder<Community>(
        stream: communityStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          }
          if (!snapshot.hasData) return const Loader();

          final community = snapshot.data!;
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 10,
                  floating: true,
                  snap: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage: community.avatar.isEmpty
                                    ? const AssetImage(
                                        'assets/images/logo.png') // Add a fallback asset
                                    : getImageProvider(community.avatar),
                                radius: 35,
                                onBackgroundImageError: (_, __) => const AssetImage(
                                    'assets/images/logo.png'), // Error fallback
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    community.name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!isGuest &&
                                      community.mods.contains(user.uid))
                                    OutlinedButton(
                                      onPressed: () {
                                        Get.toNamed(
                                            '/mod-tools/${Uri.encodeComponent(widget.communityId)}');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                                          // Join immediately — add user to members and update Firestore
                                          await Get.find<CommunityController>()
                                              .joinCommunityImmediately(
                                            community,
                                            user.uid,
                                          );

                                          // Optionally show success message
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'You have joined ${community.name}')),
                                          );
                                        } else {
                                          // Requires verification — go to verification screen
                                          Get.to(() =>
                                              JoinCommunityVerificationScreen(
                                                  community: community));
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                            ],
                          ),
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
                ),
              ];
            },
            body: community.members.contains(user.uid)
                ? StreamBuilder<List<Post>>(
                    stream: communityController
                        .getCommunityPosts(widget.communityId),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.hasError) {
                        return ErrorText(error: postSnapshot.error.toString());
                      }
                      if (!postSnapshot.hasData) return const Loader();
                      final posts = postSnapshot.data!;
                      List<Post> filteredPosts;
                      if (selectedFilter == PostFilter.campaign) {
                        filteredPosts =
                            posts.where((p) => p.type == 'carousel2').toList();
                      } else if (selectedFilter == PostFilter.elections) {
                        filteredPosts =
                            posts.where((p) => p.type == 'carousel').toList();
                      } else {
                        filteredPosts = posts;
                      }
                      if (filteredPosts.isEmpty) {
                        return const Center(child: Text("No posts available."));
                      }
                      return ListView.builder(
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          return PostCard(post: post);
                        },
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
