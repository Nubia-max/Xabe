import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/utils/utils.dart';
import '../features/auth/controller/auth_controller.dart';
import '../features/community/controller/community_controller.dart';
import '../features/posts/controller/post_controller.dart';
import '../features/posts/widgets/block_button.dart';
import '../features/posts/widgets/dot_indicator.dart';
import '../features/posts/widgets/election_time.dart';
import '../features/posts/widgets/flag_button.dart';
import '../features/posts/widgets/like_animation.dart';
import '../features/posts/widgets/neo_button.dart';
import 'package:lottie/lottie.dart';
import '../models/community_model.dart';
import '../models/post_model.dart';
import '../theme/pallete.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  final bool _showTags = false;
  Map<String, String> userNames = {};
  final Map<int, bool> _isAnimating = {};
  bool isLiked = false;
  int likeCount = 0;
  late AnimationController _lottieController;
  late int _previousVotes;
  int _currentPage = 0;
  bool _isHovered = false;
  bool _showViewResults = false;

  late final PageController _pageController;

  // Static cache for usernames to avoid repeat network calls.
  static final Map<String, String> _cachedUsernames = {};

  void _goToPrevious() {
    if (_currentPage > 0) {
      _currentPage--;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  void _goToNext() {
    if (_currentPage < widget.post.imageUrls.length - 1) {
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(viewportFraction: 1, initialPage: _currentPage);
    _lottieController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _previousVotes =
        widget.post.imageVotes.values.fold(0, (sum, element) => sum + element);
    final currentUser = Get.find<AuthController>().userModel.value!;
    isLiked = widget.post.likedBy.contains(currentUser.uid);
    likeCount = widget.post.likes;
    // Assuming widget.post.taggedUsers is a flat List<String>
    if (widget.post.taggedUids.isNotEmpty) {
      fetchUsernames(widget.post.taggedUids);
    }
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentUser = Get.find<AuthController>().userModel.value!;
    final currentVotes =
        widget.post.imageVotes.values.fold(0, (sum, element) => sum + element);
    if (currentVotes > _previousVotes) {
      _lottieController.forward(from: 0.0);
    }
    _previousVotes = currentVotes;
    if (oldWidget.post.likes != widget.post.likes ||
        oldWidget.post.likedBy != widget.post.likedBy) {
      setState(() {
        likeCount = widget.post.likes;
        isLiked = widget.post.likedBy.contains(currentUser.uid);
      });
    }
  }

  Future<void> fetchUsernames(List<String> uids) async {
    for (String userId in uids) {
      if (!_cachedUsernames.containsKey(userId)) {
        final username =
            await Get.find<AuthController>().getUsernameFromUid(userId);
        _cachedUsernames[userId] = username;
      }
      userNames[userId] = _cachedUsernames[userId]!;
    }
  }

  void deletePost() async {
    await Get.find<PostController>().deletePost(widget.post, context);
  }

  void confirmDeletePost() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Post"),
          content: const Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deletePost();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void navigateToUser() async {
    await Get.toNamed('/u/${widget.post.uid}');
  }

  void navigateToCommunity() async {
    await Get.toNamed(
        '/X/${widget.post.communityId}'); // Use communityId instead of name
  }

  void navigateToComments() async {
    await Get.toNamed('/post/${widget.post.id}/comments');
  }

  void navigateToTaggedUserProfile(String userId) async {
    await Get.toNamed('/u/$userId');
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImageProvider(imageUrl);
    } else {
      return AssetImage(imageUrl);
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthController>().userModel.value!;
    final currentTheme = Get.theme;
    final alreadyVoted = widget.post.userVotes.containsKey(user.uid);
    final votedIndex = widget.post.userVotes[user.uid];

    // Group the flat list of tagged users into sublists based on the number of images.
    // This logic assumes that the tagged users are ordered such that each consecutive group
    // of N users corresponds to one image (where N = total tagged users / number of images).
    List<List<String>> groupedTaggedUsers = List.generate(
      widget.post.imageUrls.length,
      (index) => widget.post.taggedUsers
          .where((userId) =>
              widget.post.taggedUsers.indexOf(userId) %
                  widget.post.imageUrls.length ==
              index)
          .toList(),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ).copyWith(right: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header section
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: navigateToCommunity,
                                          child: // Update the CircleAvatar for community profile
                                              CircleAvatar(
                                            backgroundImage: getImageProvider(
                                                widget
                                                    .post.communityProfilePic),
                                            radius: 16,
                                            onBackgroundImageError: (_, __) =>
                                                const AssetImage(
                                                    'assets/images/logo.png'),
                                            child: widget.post
                                                    .communityProfilePic.isEmpty
                                                ? const Icon(Icons
                                                    .group) // Fallback icon
                                                : null,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              StreamBuilder<Community>(
                                                stream: widget.post.communityId
                                                        .isNotEmpty
                                                    ? Get.find<
                                                            CommunityController>()
                                                        .getCommunityById(widget
                                                            .post
                                                            .communityId) // Fetch community only if the ID is not empty
                                                    : Stream.error(
                                                        'Invalid community ID'), // Handle invalid communityId
                                                builder: (context, snapshot) {
                                                  // If the stream is still loading, show a loading indicator
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const CircularProgressIndicator();
                                                  }

                                                  // If there was an error fetching data, display the error
                                                  if (snapshot.hasError) {
                                                    return Text(
                                                        'Error: ${snapshot.error}');
                                                  }

                                                  // If there's no community data, display a message
                                                  if (!snapshot.hasData) {
                                                    return const Text(
                                                        'Community not found');
                                                  }

                                                  // When data is available, display the community's name
                                                  final community =
                                                      snapshot.data!;

                                                  return Text(
                                                    community
                                                        .name, // Display the community name
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  );
                                                },
                                              ),
                                              GestureDetector(
                                                onTap: navigateToUser,
                                                child: Text(
                                                  'u/${widget.post.username}',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (widget.post.type == 'carousel' &&
                                            widget.post.electionEndTime != null)
                                          Tooltip(
                                            message: 'time',
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.access_time,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Pallete.whiteColor
                                                      : Pallete.blackColor,
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            "Time remaining for election"),
                                                        content: ElectionTime(
                                                            electionEndTime: widget
                                                                .post
                                                                .electionEndTime!),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(),
                                                            child: const Text(
                                                                "Close"),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        if (widget.post.uid == user.uid)
                                          IconButton(
                                            onPressed: confirmDeletePost,
                                            icon: Icon(Icons.delete,
                                                color: Pallete.redColor),
                                          ),
                                        FlagButton(
                                          contentId: widget.post.id,
                                          contentType: 'posts',
                                          communityId: widget
                                              .post.communityId, // ✅ FIXED
                                          authorId: widget
                                              .post.uid, // ✅ leave this as is
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(
                                    widget.post.title,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: widget.post.imageUrls.isNotEmpty
                                      ? MouseRegion(
                                          onEnter: (_) =>
                                              setState(() => _isHovered = true),
                                          onExit: (_) => setState(
                                              () => _isHovered = false),
                                          child: Stack(
                                            children: [
                                              PageView.builder(
                                                controller: _pageController,
                                                onPageChanged: (index) {
                                                  setState(() {
                                                    _currentPage = index;
                                                  });
                                                },
                                                itemCount: widget
                                                    .post.imageUrls.length,
                                                itemBuilder: (context, index) {
                                                  final imageUrl = widget
                                                      .post.imageUrls[index];
                                                  _isAnimating.putIfAbsent(
                                                      index, () => false);
                                                  return MouseRegion(
                                                    cursor: SystemMouseCursors
                                                        .click,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        Get.toNamed(
                                                          '/full-screen-image',
                                                          arguments: {
                                                            'post': widget.post,
                                                            'initialPage':
                                                                _currentPage,
                                                          },
                                                        );
                                                      },
                                                      child: Stack(
                                                        children: [
                                                          CachedNetworkImage(
                                                            imageUrl: imageUrl,
                                                            placeholder: (_,
                                                                    __) =>
                                                                const Center(
                                                                    child:
                                                                        CircularProgressIndicator()),
                                                            errorWidget:
                                                                (_, __, ___) =>
                                                                    Container(
                                                              color: Colors
                                                                  .grey[200],
                                                              child:
                                                                  const Center(
                                                                child: Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    size: 50,
                                                                    color: Colors
                                                                        .grey),
                                                              ),
                                                            ),
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                            fit: BoxFit.cover,
                                                          ),

                                                          // --- Tagged users overlay (always visible now) ---
                                                          if (groupedTaggedUsers[
                                                                  index]
                                                              .isNotEmpty)
                                                            ...groupedTaggedUsers[
                                                                    index]
                                                                .asMap()
                                                                .entries
                                                                .map((entry) {
                                                              final tagIdx =
                                                                  entry.key;
                                                              final tag =
                                                                  entry.value;
                                                              final isManual =
                                                                  widget.post
                                                                      .taggedNames
                                                                      .contains(
                                                                          tag);
                                                              final displayName = isManual
                                                                  ? tag
                                                                  : userNames[
                                                                          tag] ??
                                                                      'Loading...';

                                                              return Positioned(
                                                                left: 10,
                                                                bottom: 10 +
                                                                    tagIdx *
                                                                        20.0,
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    if (!isManual) {
                                                                      navigateToTaggedUserProfile(
                                                                          tag);
                                                                    }
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.5),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              4),
                                                                    ),
                                                                    child: Text(
                                                                      ' $displayName',
                                                                      style:
                                                                          const TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }),

                                                          // --- Voting button (only for carousel) ---
                                                          if (widget
                                                                  .post.type !=
                                                              'carousel2')
                                                            Positioned(
                                                              bottom: 5,
                                                              right: 5,
                                                              child: NeoButton(
                                                                isVoted:
                                                                    alreadyVoted,
                                                                onTap: () {
                                                                  final currentUser = Get
                                                                          .find<
                                                                              AuthController>()
                                                                      .userModel
                                                                      .value!;
                                                                  if (widget
                                                                      .post
                                                                      .userVotes
                                                                      .containsKey(
                                                                          currentUser
                                                                              .uid)) {
                                                                    return;
                                                                  }
                                                                  if (widget.post
                                                                              .electionEndTime !=
                                                                          null &&
                                                                      DateTime.now().isAfter(widget
                                                                          .post
                                                                          .electionEndTime!)) {
                                                                    showSnackBar(
                                                                        context,
                                                                        "Election has ended");
                                                                    return;
                                                                  }
                                                                  final taggedList =
                                                                      groupedTaggedUsers[
                                                                          index];
                                                                  String
                                                                      taggedName =
                                                                      'Candidate';

                                                                  if (taggedList
                                                                      .isNotEmpty) {
                                                                    final tag =
                                                                        taggedList
                                                                            .first;
                                                                    final isManual = widget
                                                                        .post
                                                                        .taggedNames
                                                                        .contains(
                                                                            tag);
                                                                    taggedName = isManual
                                                                        ? tag
                                                                        : userNames[tag] ??
                                                                            'Loading…';
                                                                  }

                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (_) =>
                                                                        AlertDialog(
                                                                      title: const Text(
                                                                          "Confirm Vote"),
                                                                      content: Text(
                                                                          "Vote for $taggedName?"),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(context),
                                                                          child:
                                                                              const Text("Cancel"),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                            Get.find<PostController>().voteForCandidate(widget.post.id,
                                                                                index);
                                                                            setState(() {});
                                                                          },
                                                                          child:
                                                                              const Text("Vote"),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (_isHovered &&
                                                  _currentPage > 0)
                                                Positioned(
                                                  left: 10,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: Center(
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.arrow_back,
                                                          color: Colors.white),
                                                      onPressed: _goToPrevious,
                                                    ),
                                                  ),
                                                ),
                                              if (_isHovered &&
                                                  _currentPage <
                                                      widget.post.imageUrls
                                                              .length -
                                                          1)
                                                Positioned(
                                                  right: 10,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: Center(
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.arrow_forward,
                                                          color: Colors.white),
                                                      onPressed: _goToNext,
                                                    ),
                                                  ),
                                                ),
                                              if (widget.post.imageUrls.length >
                                                  1)
                                                Positioned(
                                                  bottom: 20,
                                                  left: 0,
                                                  right: 0,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: List.generate(
                                                      widget.post.imageUrls
                                                          .length,
                                                      (index) => DotIndicator(
                                                        index: index,
                                                        currentPage:
                                                            _currentPage
                                                                .toDouble(),
                                                        totalDots: widget.post
                                                            .imageUrls.length,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed: () =>
                                                      navigateToComments(),
                                                  icon:
                                                      const Icon(Icons.comment),
                                                ),
                                                Text(
                                                  widget.post.commentCount == 0
                                                      ? 'Comment'
                                                      : '${widget.post.commentCount}',
                                                  style: const TextStyle(
                                                      fontSize: 17),
                                                ),
                                              ],
                                            ),
                                            StreamBuilder(
                                              stream: Get.find<
                                                      CommunityController>()
                                                  .getCommunityById(widget
                                                      .post.communityName),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  final data = snapshot.data!;
                                                  if (data.mods
                                                      .contains(user.uid)) {
                                                    return IconButton(
                                                      onPressed:
                                                          confirmDeletePost,
                                                      icon: const Icon(Icons
                                                          .admin_panel_settings),
                                                    );
                                                  }
                                                }
                                                return const SizedBox();
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.post.type == 'carousel' &&
                  widget.post.imageUrls.isNotEmpty) ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) {
                    setState(() {
                      _showViewResults = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _showViewResults = false;
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed('/graph/${widget.post.id}');
                    },
                    child: Stack(
                      children: [
                        Container(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Transform.translate(
                              offset: const Offset(-5, -5),
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      Transform.translate(
                                        offset: const Offset(-5, -35),
                                        child: Lottie.asset(
                                          'assets/animations/voteanimation.json',
                                          controller: _lottieController,
                                          width: 100,
                                          height: 100,
                                          repeat: false,
                                          onLoaded: (composition) {
                                            _lottieController.duration =
                                                const Duration(seconds: 2);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Transform.translate(
                                        offset: const Offset(-40, -25),
                                        child: Text(
                                          ": ${widget.post.imageVotes.values.fold(0, (previousValue, element) => previousValue + element)}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_showViewResults)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.black.withOpacity(0.5),
                              child: const Text(
                                "View Results",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (widget.post.type == 'carousel2') ...[
                Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        icon: LikeAnimation(
                          isAnimating: isLiked,
                          onEnd: () {},
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                        ),
                        onPressed: () {
                          final newLikeState = !isLiked;
                          setState(() {
                            isLiked = newLikeState;
                            likeCount =
                                newLikeState ? likeCount + 1 : likeCount - 1;
                          });
                          Get.find<PostController>().likePost(
                            widget.post.id,
                            Get.find<AuthController>().userModel.value!.uid,
                            isLiking: newLikeState,
                          );
                        },
                      ),
                      Text('$likeCount'),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: () => navigateToComments(),
                      ),
                      Text('${widget.post.commentCount}'),
                    ],
                  ),
                ),
                if (widget.post.description != null &&
                    widget.post.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.post.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: currentTheme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
              ],
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}

ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.isEmpty) {
    return const AssetImage(
        'assets/images/logo.png'); // Fallback for empty URLs
  }
  if (imageUrl.startsWith('http')) {
    return CachedNetworkImageProvider(imageUrl);
  } else {
    return AssetImage(imageUrl);
  }
}
