import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/features/user_profile/controller/user_profile_controller.dart';
import 'package:xabe/core/utils/utils.dart';
import 'package:xabe/core/post_card.dart';

import '../../../core/common/error_text.dart';
import '../../../core/common/loader.dart';
import '../../../models/post_model.dart';
import '../../auth/repository/auth_repository.dart';

class UserProfileScreen extends StatelessWidget {
  final String uid;
  final String? jumpToPostId;

  const UserProfileScreen({
    super.key,
    required this.uid,
    this.jumpToPostId,
  });

  void navigateToEditUser(BuildContext context) async {
    await Get.toNamed('/edit-profile/$uid');
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        return NetworkImage(imageUrl);
      } else {
        return CachedNetworkImageProvider(imageUrl);
      }
    } else {
      return AssetImage(imageUrl);
    }
  }

  void _showConfirmationDialog(BuildContext context, String targetUserId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Block User"),
          content: const Text("Are you sure you want to block this user?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _blockUser(targetUserId);
              },
              child: const Text("Block", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser(String targetUserId) async {
    await Get.find<AuthRepository>().blockUser(targetUserId);
    Get.snackbar('Blocked', 'The user has been blocked successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Get.find<AuthController>().userModel.value!;
    final userProfileController = Get.find<UserProfileController>();
    final scrollController = ScrollController();
    bool hasJumped = false;

    return StreamBuilder(
      stream: userProfileController.getUserData(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorText(error: snapshot.error.toString());
        }
        if (!snapshot.hasData) return const Loader();
        final user = snapshot.data!;

        if (currentUser.blockedUsers.contains(user.uid)) {
          return const Center(child: Text("This user has been blocked."));
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 250,
                floating: true,
                snap: true,
                flexibleSpace: Stack(
                  children: [
                    Container(
                      alignment: Alignment.bottomLeft,
                      padding: currentUser.uid == uid
                          ? const EdgeInsets.all(20).copyWith(bottom: 70)
                          : const EdgeInsets.all(20),
                      child: kIsWeb
                          ? CachedWebImage(
                              imageUrl: user.profilePic,
                              fit: BoxFit.cover,
                            )
                          : CircleAvatar(
                              backgroundImage:
                                  getImageProvider(user.profilePic),
                              radius: 45,
                            ),
                    ),
                    Container(
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(20),
                      child: currentUser.uid == uid
                          ? OutlinedButton(
                              onPressed: () => navigateToEditUser(context),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                              ),
                              child: const Text("Edit Profile"),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'u/${user.name}',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    if (user.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          user.bio,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Divider(thickness: 2),
                  ]),
                ),
              ),
              if (currentUser.uid != uid)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ElevatedButton(
                        onPressed: () =>
                            _showConfirmationDialog(context, user.uid),
                        child: const Text("Block User"),
                      ),
                    ]),
                  ),
                ),
            ],
            body: StreamBuilder<List<Post>>(
              stream: userProfileController.getUserPosts(uid),
              builder: (context, snapshotPosts) {
                if (snapshotPosts.hasError) {
                  return ErrorText(error: snapshotPosts.error.toString());
                }

                if (!snapshotPosts.hasData) return const Loader();
                final posts = snapshotPosts.data!;

                if (posts.isEmpty) {
                  return const Center(child: Text('No posts available.'));
                }

                // Extract the jumpToPost if any
                final jumpPost =
                    posts.firstWhereOrNull((p) => p.id == jumpToPostId);
                final remainingPosts =
                    posts.where((p) => p.id != jumpToPostId).toList();

                return ListView.builder(
                  controller: scrollController,
                  itemCount: jumpPost == null
                      ? remainingPosts.length
                      : remainingPosts.length + 1,
                  itemBuilder: (context, index) {
                    // Show the jumpToPost first if available
                    if (jumpPost != null && index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("🚨 Flagged Post",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ),
                          PostCard(post: jumpPost),
                          const Divider(thickness: 1),
                        ],
                      );
                    }

                    final adjustedIndex = jumpPost == null ? index : index - 1;
                    final post = remainingPosts[adjustedIndex];

                    if (currentUser.blockedUsers.contains(post.uid)) {
                      return const SizedBox.shrink();
                    }

                    return PostCard(post: post);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class CachedWebImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  const CachedWebImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<CachedWebImage> createState() => _CachedWebImageState();
}

class _CachedWebImageState extends State<CachedWebImage> {
  static final _cache = <String, Uint8List>{};
  static const _maxCacheSize = 100;

  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedWebImage oldWidget) {
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _loadImage() async {
    try {
      if (_cache.containsKey(widget.imageUrl)) {
        if (mounted) setState(() => _imageBytes = _cache[widget.imageUrl]);
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      final file = await DefaultCacheManager().getSingleFile(widget.imageUrl);
      final bytes = await file.readAsBytes();

      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }

      _cache[widget.imageUrl] = bytes;
      if (mounted) setState(() => _imageBytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const CircularProgressIndicator();
    if (_error != null) return const Icon(Icons.error);
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: widget.fit);
    }
    return const SizedBox.shrink();
  }
}

ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http')) {
    if (kIsWeb) {
      return NetworkImage(imageUrl);
    } else {
      return CachedNetworkImageProvider(imageUrl);
    }
  } else {
    return AssetImage(imageUrl);
  }
}
