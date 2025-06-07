import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:xabe/core/constants/firebase_constants.dart';
import 'package:xabe/core/utils/utils.dart';
import 'package:xabe/features/posts/repository/post_repository.dart';
import 'package:xabe/models/comment_model.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';
import 'package:uuid/uuid.dart';

import '../../../core/failure.dart';
import '../../../core/providers/storage_repository.dart';
import '../../auth/controller/auth_controller.dart';
import '../../notifications/notification_controller.dart';
import '../../notifications/push_notifications/push_notification_dispatcher.dart';
import '../../user_profile/controller/user_profile_controller.dart';

class PostController extends GetxController {
  var posts = <Post>[].obs;
  var isLoading = false.obs;

  final PostRepository _postRepository;
  final StorageRepository _storageRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PostController({
    required PostRepository postRepository,
    required StorageRepository storageRepository,
  })  : _postRepository = postRepository,
        _storageRepository = storageRepository;

  void setLoading(bool value) => isLoading.value = value;

  Future<void> deletePost(Post post, BuildContext context) async {
    final res = await _postRepository.deletePost(post);
    res.fold(
      (l) => showSnackBar(context, l.message),
      (_) {
        showSnackBar(context, "Post deleted successfully");
        posts.removeWhere((p) => p.id == post.id);
      },
    );
  }

  Future<void> voteForCandidate(String postId, int index) async {
    final authController = Get.find<AuthController>();
    final user = authController.userModel.value;
    if (user == null || !user.isAuthenticated) return;

    final post = await _postRepository.getPostByIdFuture(postId);
    if (post == null) return;

    try {
      // Fetch community document for this post
      final communitySnapshot = await FirebaseFirestore.instance
          .collection('communities')
          .doc(post.communityId)
          .get();

      if (!communitySnapshot.exists) {
        showSnackBar(Get.context!, "Community not found.");
        return;
      }

      final communityData = communitySnapshot.data()!;
      final communityType = communityData['communityType'] ?? 'regular';

      // Safely convert pricePerVote to double
      final double pricePerVote = (post.pricePerVote ?? 0).toDouble();

      if (communityType == 'premium') {
        // Check user's balance before voting
        if (user.balance < pricePerVote) {
          showSnackBar(Get.context!, "Insufficient balance to vote.");
          return;
        }

        // Firestore references
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final communityDocRef = FirebaseFirestore.instance
            .collection('communities')
            .doc(post.communityId);
        final postDocRef =
            FirebaseFirestore.instance.collection('posts').doc(postId);

        // Run transaction to atomically update balances and votes
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final freshUserSnapshot = await transaction.get(userDocRef);
          final freshCommunitySnapshot = await transaction.get(communityDocRef);
          final freshPostSnapshot = await transaction.get(postDocRef);

          final freshUserData = freshUserSnapshot.data()!;
          final freshCommunityData = freshCommunitySnapshot.data()!;
          final freshPostData = freshPostSnapshot.data()!;

          final freshUserBalanceRaw = freshUserData['balance'] ?? 0;
          final freshUserBalance = (freshUserBalanceRaw is int)
              ? freshUserBalanceRaw.toDouble()
              : freshUserBalanceRaw as double;

          if (freshUserBalance < pricePerVote) {
            throw 'Insufficient balance inside transaction.';
          }

          // Deduct price from user balance
          final newUserBalance = freshUserBalance - pricePerVote;
          transaction.update(userDocRef, {'balance': newUserBalance});

          // Add price to community balance
          final freshCommunityBalanceRaw = freshCommunityData['balance'] ?? 0;
          final freshCommunityBalance = (freshCommunityBalanceRaw is int)
              ? freshCommunityBalanceRaw.toDouble()
              : freshCommunityBalanceRaw as double;
          final newCommunityBalance = freshCommunityBalance + pricePerVote;
          transaction.update(communityDocRef, {'balance': newCommunityBalance});

          // Update user votes for the post
          final userVotes =
              Map<String, dynamic>.from(freshPostData['userVotes'] ?? {});
          List<dynamic> votesList = userVotes[user.uid] ?? [];

          if (votesList.length >= (freshPostData['maxVotesPerPerson'] ?? 1)) {
            throw 'You’ve used all your votes.';
          }

          votesList = List<dynamic>.from(votesList);
          votesList.add(index);
          userVotes[user.uid] = votesList;

          final imageVotes =
              Map<String, dynamic>.from(freshPostData['imageVotes'] ?? {});
          final imageKey = index.toString();
          imageVotes[imageKey] = (imageVotes[imageKey] ?? 0) + 1;

          transaction.update(postDocRef, {
            'userVotes': userVotes,
            'imageVotes': imageVotes,
          });
        });

        // Update local user balance after successful transaction
        final updatedUserBalance = user.balance - pricePerVote;

        // **Update the Rx userModel without navigating**
        authController.userModel.update((val) {
          if (val != null) {
            val = val.copyWith(balance: updatedUserBalance);
          }
        });

        // DO NOT call Get.back() here — no navigation!
      } else {
        // Non-premium communities: update votes without balance checks
        final userVotes = post.userVotes[user.uid] ?? [];

        if (userVotes.length >= post.maxVotesPerPerson) {
          showSnackBar(Get.context!, "You’ve used all your votes.");
          return;
        }

        final updatedUserVotes = [...userVotes, index];
        final updatedImageVotes = Map<String, int>.from(post.imageVotes);
        final imageKey = index.toString();
        updatedImageVotes[imageKey] = (updatedImageVotes[imageKey] ?? 0) + 1;

        final updatedPost = post.copyWith(
          userVotes: {
            ...post.userVotes,
            user.uid: updatedUserVotes,
          },
          imageVotes: updatedImageVotes,
        );

        await _postRepository.updatePost(updatedPost);

        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) posts[postIndex] = updatedPost;
      }
    } catch (e) {
      if (e is String) {
        showSnackBar(Get.context!, e);
      } else {
        showSnackBar(Get.context!, "Error voting: $e");
      }
    }
  }

  Future<void> likePost(String postId, String userId,
      {required bool isLiking}) async {
    final post = await _postRepository.getPostByIdFuture(postId);
    if (post == null) return;

    final firestore = Get.find<FirebaseFirestore>();
    final update = isLiking
        ? {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId])
          }
        : {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId])
          };

    await firestore
        .collection(FirebaseConstants.postsCollection)
        .doc(postId)
        .update(update);

    final updatedPost = post.copyWith(
      likes: isLiking ? post.likes + 1 : post.likes - 1,
      likedBy:
          isLiking ? [...post.likedBy, userId] : List<String>.from(post.likedBy)
            ..remove(userId),
    );

    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) posts[postIndex] = updatedPost;
  }

  Future<File?> compressImage(dynamic file) async {
    if (kIsWeb) {
      // Handle web platform
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        return _convertUint8ListToFile(bytes, 'web_image.jpg');
      }
      return file is File ? file : null;
    }

    // Handle mobile platform
    File? targetFile;
    if (file is XFile) {
      targetFile = File(file.path);
    } else if (file is File) {
      targetFile = file;
    } else {
      return null;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        targetFile.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 600,
      );

      // Explicit type casting for mobile
      return result != null ? File(result.path) : targetFile;
    } catch (e) {
      debugPrint('Compression failed: $e');
      return targetFile;
    }
  }

  Future<void> shareCarouselPost({
    required BuildContext context,
    required String title,
    required String caption,
    required Community selectedCommunity,
    required List<dynamic> files,
    required List<List<Map<String, dynamic>>> taggedUsers,
    required bool showLiveResults,
    required int pricePerVote, // ✅ Add this
    required int maxVotesPerPerson,
    bool isCarousel2 = false,
    DateTime? electionEndTime,
    required bool allowNonMembersToVote,
  }) async {
    isLoading.value = true;

    final user = Get.find<AuthController>().userModel.value!;
    final bannedInThisCommunity =
        selectedCommunity.bannedUsers.contains(user.uid);

    if (bannedInThisCommunity) {
      showSnackBar(context, "❌ You are banned from posting in this community.");
      setLoading(false); // or isLoading.value = false;
      return;
    }
    if (!isCarousel2) {
      if (selectedCommunity.id != "My Profile") {
        final community = await getCommunityById(selectedCommunity.id).first;
        if (!community.mods.contains(user.uid)) {
          showSnackBar(context, 'Only moderators can conduct elections');
          isLoading.value = false;
          return;
        }
      }
      if (electionEndTime == null) {
        showSnackBar(context, "Set election end time");
        isLoading.value = false;
        return;
      }
    }

    final postId = const Uuid().v1();
    final imageUrls = <String>[];

    // Upload images
    final uploadFutures = <Future<Either<Failure, String>>>[];

    for (int i = 0; i < files.length; i++) {
      final currentFile = files[i];

      if (kIsWeb) {
        Uint8List? bytes;
        if (currentFile is Map && currentFile.containsKey("bytes")) {
          bytes = currentFile["bytes"];
        } else if (currentFile is Uint8List) {
          bytes = currentFile;
        }
        if (bytes != null) {
          uploadFutures.add(_storageRepository.storeFileFromBytes(
            path: 'posts/${selectedCommunity.id}',
            id: '${postId}_$i',
            bytes: bytes,
            index: i,
          ));
        }
      } else {
        final File? compressed = await compressImage(currentFile);
        if (compressed != null) {
          uploadFutures.add(_storageRepository.storeFile(
            path: 'posts/${selectedCommunity.id}',
            id: '${postId}_$i',
            file: compressed,
            index: i,
          ));
        }
      }
    }

    final results = await Future.wait(uploadFutures);
    for (final res in results) {
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => imageUrls.add(r),
      );
    }

    // Separate manual names and UIDs
    final List<String> taggedNames = [];
    final List<String> taggedUids = [];
    final List<String> flatRawTags = [];

    for (var list in taggedUsers) {
      for (var tag in list) {
        if (tag['isManual'] == true && tag.containsKey('name')) {
          taggedNames.add(tag['name']);
          flatRawTags.add(tag['name']);
        } else if (tag.containsKey('uid')) {
          taggedUids.add(tag['uid']);
          flatRawTags.add(tag['uid']);
        }
      }
    }

    // Construct Post model
    final post = Post(
      id: postId,
      title: title,
      communityName: selectedCommunity.name,
      communityProfilePic: selectedCommunity.avatar,
      commentCount: 0,
      username: user.name,
      uid: user.uid,
      type: isCarousel2 ? 'carousel2' : 'carousel',
      createdAt: DateTime.now(),
      imageUrls: imageUrls,
      taggedUsers: flatRawTags,
      // for backward compatibility
      description: caption,
      electionEndTime: isCarousel2 ? null : electionEndTime!,

      likedBy: [],
      userVotes: {},
      imageVotes: {},
      link: '',
      communityId: selectedCommunity.id,
      taggedNames: taggedNames,
      taggedUids: taggedUids,
      showLiveResults: showLiveResults,
      pricePerVote:
          selectedCommunity.communityType == 'premium' ? pricePerVote : 0,
      maxVotesPerPerson:
          selectedCommunity.communityType == 'premium' ? maxVotesPerPerson : 1,
      allowNonMembersToVote: allowNonMembersToVote, communityMembers: [],
    );
    final res = await _postRepository.addPost(post);
    isLoading.value = false;

    res.fold(
      (l) => showSnackBar(context, l.message),
      (_) {
        showSnackBar(context, 'Posted Successfully!');
        Get.back();

        for (final member in selectedCommunity.members) {
          if (member != user.uid) {
            Get.find<NotificationController>().sendNotification(
              recipientId: member,
              senderId: user.uid,
              senderName: user.name,
              message: isCarousel2
                  ? "Campaigns in ${selectedCommunity.name}"
                  : "$title elections in ${selectedCommunity.name}",
              type: "new_post",
              communityId: selectedCommunity.id,
              communityName: selectedCommunity.name,
            );
          }
        }
      },
    );
  }

  Future<void> shareImagePost({
    required BuildContext context,
    required String title,
    required String caption,
    required Community selectedCommunity,
    required dynamic file,
  }) async {
    setLoading(true);

    final user = Get.find<AuthController>().userModel.value!;
    final bannedInThisCommunity =
        selectedCommunity.bannedUsers.contains(user.uid);

    if (bannedInThisCommunity) {
      showSnackBar(context, "❌ You are banned from posting in this community.");
      setLoading(false); // or isLoading.value = false;
      return;
    }

    File? fileToUpload;
    if (!kIsWeb) {
      fileToUpload = await compressImage(file);
    } else if (file is Uint8List) {
      fileToUpload = _convertUint8ListToFile(file, 'image.jpg');
    }

    if (fileToUpload == null) {
      showSnackBar(context, "Invalid file");
      setLoading(false);
      return;
    }

    final postId = const Uuid().v1(); // ✅ FIX: This was missing

    final imageRes = await _storageRepository.storeFile(
      path: 'posts/${selectedCommunity.id}',
      id: postId,
      file: fileToUpload,
    );

    imageRes.fold(
      (l) {
        showSnackBar(context, l.message);
        setLoading(false);
      },
      (r) async {
        final post = Post(
          id: postId,
          title: title,
          communityName: selectedCommunity.name,
          communityProfilePic: selectedCommunity.avatar,
          commentCount: 0,
          username: user.name,
          uid: user.uid,
          type: 'image',
          createdAt: DateTime.now(),
          link: r,
          description: caption,
          imageUrls: [],
          likedBy: [],
          userVotes: {},
          imageVotes: {},
          taggedUsers: [],
          electionEndTime: DateTime.now(),
          communityId: selectedCommunity.id,
          showLiveResults: false,
          communityMembers: [],
        );

        final res = await _postRepository.addPost(post);
        setLoading(false);

        res.fold(
          (l) => showSnackBar(context, l.message),
          (_) {
            showSnackBar(context, 'Posted!');
            Get.back();
            // Notification logic...
          },
        );
      },
    );
  }

  /// Returns a stream of posts for the given communities.
  Stream<List<Post>> fetchUserPosts(List<Community> communities) {
    if (communities.isNotEmpty) {
      return _postRepository.fetchUserPosts(communities);
    }
    return Stream.value([]);
  }

  /// Returns a stream of posts for guest users.
  Stream<List<Post>> fetchGuestPosts() {
    return _postRepository.fetchGuestPosts();
  }

  /// Returns a stream of a single post by ID.
  Stream<Post> getPostById(String postId) {
    return _postRepository.getPostById(postId);
  }

  /// Returns a stream of posts for the user.
  Stream<List<Post>> getUserPostsStream(List<Community> communities) {
    if (communities.isEmpty) return Stream.value([]);
    return _postRepository.fetchUserPosts(communities);
  }

  /// Returns a stream of posts for guest users.
  Stream<List<Post>> getGuestPostsStream() {
    return _postRepository.fetchGuestPosts();
  }

  /// Returns a stream of a community by its name.
  Stream<Community> getCommunityById(String id) {
    return FirebaseFirestore.instance
        .collection(FirebaseConstants.communitiesCollection)
        .doc(id)
        .snapshots()
        .map((doc) => Community.fromMap(doc.data() as Map<String, dynamic>));
  }

  /// Adds a comment to a post.
  Future<void> addComment({
    required BuildContext context,
    required String text,
    required Post post,
  }) async {
    final user = Get.find<AuthController>().userModel.value!;
    String commentId = const Uuid().v1();

    Comment comment = Comment(
      id: commentId,
      text: text,
      createdAt: DateTime.now(),
      postId: post.id,
      username: user.name,
      profilePic: user.profilePic,
    );
    final res = await _postRepository.addComment(comment);
    Get.find<UserProfileController>(); // Use if needed.
    res.fold((l) => showSnackBar(context, l.message), (_) => null);
  }

  /// Returns a stream of comments for a given post.
  Stream<List<Comment>> fetchPostComments(String postId) {
    return _postRepository.getCommentsOfPost(postId);
  }

  /// Fetch posts for a community and type from Firestore.
  Future<List<Post>> getPostsForCommunityAndType(
      String communityId, String type) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.postsCollection)
        .where('communityId', isEqualTo: communityId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateShowLiveResults(String postId, bool showLive) async {
    try {
      await _postRepository.updatePostField(
        postId: postId,
        field: 'showLiveResults',
        value: showLive,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update live progress status.');
    }
  }

  Future<void> updatePost(Post post) async {
    try {
      await _postRepository.updatePost(post);
      final index = posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        posts[index] = post;
      }
    } catch (e) {
      debugPrint('Failed to update post: $e');
    }
  }

  Stream<List<Post>> premiumElectionPostsStream() async* {
    // Get all premium community IDs first
    final premiumCommunitiesSnapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.communitiesCollection)
        .where('communityType', isEqualTo: 'premium')
        .get();

    final premiumCommunityIds =
        premiumCommunitiesSnapshot.docs.map((doc) => doc.id).toList();

    if (premiumCommunityIds.isEmpty) {
      yield [];
      return;
    }

    // Listen to posts filtered by those communityIds, type 'carousel', and allowNonMembersToVote == true
    yield* FirebaseFirestore.instance
        .collection(FirebaseConstants.postsCollection)
        .where('communityId', whereIn: premiumCommunityIds)
        .where('type', isEqualTo: 'carousel')
        .where('allowNonMembersToVote', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  void checkElectionEndings() async {
    final now = DateTime.now();

    final postsSnapshot = await _firestore
        .collection('posts')
        .where('type', isEqualTo: 'carousel')
        .where('electionEndTime', isLessThanOrEqualTo: now)
        .where('electionEndedNotificationSent', isEqualTo: false)
        .get();

    for (final doc in postsSnapshot.docs) {
      final post = Post.fromMap(doc.data());

      for (final uid in post.communityMembers) {
        if (uid != post.uid) {
          final fcmToken = await getFcmToken(uid);
          if (fcmToken != null) {
            await PushNotificationDispatcher.sendNotification(
              title: 'Election Ended',
              body: '${post.title} has ended. Tap to view results.',
              fcmToken: fcmToken,
              dataPayload: {
                'type': 'election_ended',
                'postId': post.id,
              },
            );
          }
        }
      }

      // Update Firestore to mark notification sent
      await _firestore.collection('posts').doc(post.id).update({
        'electionEndedNotificationSent': true,
      });
    }
  }

  /// Helper to convert Uint8List to File.
  File _convertUint8ListToFile(Uint8List bytes, String fileName) {
    final file = File('${Directory.systemTemp.path}/$fileName');
    file.writeAsBytesSync(bytes);
    return file;
  }

  Future<String?> getFcmToken(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data()?['fcmToken'] as String?;
  }
}
