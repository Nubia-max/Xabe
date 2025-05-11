import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../models/post_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/post_controller.dart';
import '../widgets/dot_indicator.dart';
import '../widgets/neo_button.dart';

class FullScreenImagePage extends StatefulWidget {
  final Post post;
  final int initialPage;

  const FullScreenImagePage({
    super.key,
    required this.post,
    this.initialPage = 0,
  });

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late PageController _pageController;
  late int _currentPage;
  bool _showTags = false;
  late bool _alreadyVoted;
  Map<String, String> userNames = {};
  static final Map<String, String> _cachedUsernames = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage);

    final user = Get.find<AuthController>().userModel.value!;
    _alreadyVoted = widget.post.userVotes.containsKey(user.uid);

    // fetch usernames for all UIDs
    _fetchUsernames(widget.post.taggedUids);
  }

  Future<void> _fetchUsernames(List<String> ids) async {
    for (var uid in ids) {
      if (!_cachedUsernames.containsKey(uid)) {
        final name = await Get.find<AuthController>().getUsernameFromUid(uid);
        _cachedUsernames[uid] = name;
      }
      userNames[uid] = _cachedUsernames[uid]!;
    }
    setState(() {});
  }

  List<List<String>> getGroupedTags() {
    final totalImages = widget.post.imageUrls.length;
    final flatTags = widget.post.taggedUsers;
    final grouped = <List<String>>[];

    for (int i = 0; i < totalImages; i++) {
      if (i < flatTags.length) {
        grouped.add([flatTags[i]]);
      } else {
        grouped.add([]);
      }
    }

    return grouped;
  }

  void _vote() {
    if (_alreadyVoted) return;

    if (widget.post.electionEndTime != null &&
        DateTime.now().isAfter(widget.post.electionEndTime!)) {
      Get.snackbar('Voting Closed', 'This election has ended.');
      return;
    }

    final groupedTaggedUsers = getGroupedTags();
    String taggedName = "Candidate";

    final tagsForCurrentImage = groupedTaggedUsers[_currentPage];
    if (tagsForCurrentImage.isNotEmpty) {
      final tag = tagsForCurrentImage.first;
      final isManual = widget.post.taggedNames.contains(tag);
      taggedName = isManual ? tag : userNames[tag] ?? "Loading...";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Vote"),
        content: Text("Are you sure you want to vote for $taggedName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.find<PostController>().voteForCandidate(
                widget.post.id,
                _currentPage,
              );
              setState(() => _alreadyVoted = true);
            },
            child: const Text("Vote"),
          ),
        ],
      ),
    );
  }

  void _navigateToTaggedUserProfile(String userId) {
    Get.toNamed('/u/$userId');
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.post.imageUrls;
    final groupedTaggedUsers = getGroupedTags();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showTags = !_showTags),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentPage = idx;
                  final user = Get.find<AuthController>().userModel.value!;
                  _alreadyVoted = widget.post.userVotes.containsKey(user.uid);
                });
              },
              itemBuilder: (context, idx) {
                return Center(
                  child: CachedNetworkImage(
                    imageUrl: images[idx],
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                        size: 60, color: Colors.grey),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              },
            ),
            if (_showTags && groupedTaggedUsers[_currentPage].isNotEmpty)
              ...groupedTaggedUsers[_currentPage].asMap().entries.map((entry) {
                final idx = entry.key;
                final tag = entry.value;
                final isManual = widget.post.taggedNames.contains(tag);
                final name = isManual ? tag : userNames[tag] ?? 'Loading...';

                return Positioned(
                  left: 16,
                  bottom: 80 + idx * 28,
                  child: GestureDetector(
                    onTap: () {
                      if (!isManual) {
                        _navigateToTaggedUserProfile(tag);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ' $name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            if (images.length > 1)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => DotIndicator(
                      index: i,
                      currentPage: _currentPage.toDouble(),
                      totalDots: images.length,
                    ),
                  ),
                ),
              ),
            if (widget.post.type == 'carousel')
              Positioned(
                bottom: 20,
                right: 20,
                child: NeoButton(
                  isVoted: _alreadyVoted,
                  onTap: _vote,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
