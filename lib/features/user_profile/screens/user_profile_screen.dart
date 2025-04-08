// user_profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';

import '../../../core/post_card.dart';
import '../controller/user_profile_controller.dart';

class UserProfileScreen extends StatelessWidget {
  final String uid;
  const UserProfileScreen({super.key, required this.uid});

  void navigateToEditUser(BuildContext context) async {
    await Get.toNamed('/edit-profile/$uid');
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        // On web, use NetworkImage
        return NetworkImage(imageUrl);
      } else {
        // For mobile builds, use CachedNetworkImageProvider.
        return CachedNetworkImageProvider(imageUrl);
      }
    } else {
      return AssetImage(imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileController = Get.find<UserProfileController>();
    return StreamBuilder(
      stream: userProfileController.getUserData(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorText(error: snapshot.error.toString());
        }
        if (!snapshot.hasData) return const Loader();
        final user = snapshot.data!;
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 250,
                  floating: true,
                  snap: true,
                  flexibleSpace: Stack(
                    children: [
                      Positioned.fill(
                        child: kIsWeb
                            ? CachedWebImage(
                                imageUrl: user.banner, fit: BoxFit.cover)
                            : Image(
                                image: getImageProvider(user.banner),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Container(
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(20).copyWith(bottom: 70),
                        child: kIsWeb
                            ? CachedWebImage(
                                imageUrl: user.profilePic, fit: BoxFit.cover)
                            : CircleAvatar(
                                backgroundImage:
                                    getImageProvider(user.profilePic),
                                radius: 45,
                              ),
                      ),
                      Container(
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(20),
                        child: OutlinedButton(
                          onPressed: () => navigateToEditUser(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                          ),
                          child: const Text("Edit Profile"),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
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
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        const SizedBox(height: 10),
                        const Divider(thickness: 2),
                      ],
                    ),
                  ),
                )
              ];
            },
            body: StreamBuilder<List>(
              stream: userProfileController.getUserPosts(uid),
              builder: (context, snapshotPosts) {
                if (snapshotPosts.hasError) {
                  return ErrorText(error: snapshotPosts.error.toString());
                }
                if (!snapshotPosts.hasData) return const Loader();
                final posts = snapshotPosts.data!;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
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

ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http')) {
    if (kIsWeb) {
      // On web, use NetworkImage
      return NetworkImage(imageUrl);
    } else {
      // For mobile builds, use CachedNetworkImageProvider.
      return CachedNetworkImageProvider(imageUrl);
    }
  } else {
    return AssetImage(imageUrl);
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

      // Manage cache size
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
    if (_imageBytes != null) return Image.memory(_imageBytes!, fit: widget.fit);
    return const SizedBox.shrink();
  }
}
