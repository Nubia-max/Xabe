import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:xabe/core/constants/firebase_constants.dart';
import 'package:xabe/core/utils.dart';
import 'package:xabe/features/posts/repository/post_repository.dart';
import 'package:xabe/models/comment_model.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';
import 'package:uuid/uuid.dart';

import '../../../core/failure.dart';
import '../../../core/providers/storage_repository.dart';
import '../../auth/controller/auth_controller.dart';
import '../../notifications/notification_controller.dart';
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
    final user = Get.find<AuthController>().userModel.value;
    if (user == null || !user.isAuthenticated) return;

    final post = await _postRepository.getPostByIdFuture(postId);
    if (post == null || post.userVotes.containsKey(user.uid)) return;

    final updatedPost = post.copyWith(
      userVotes: {...post.userVotes, user.uid: index},
      imageVotes: {
        ...post.imageVotes,
        index.toString(): (post.imageVotes[index.toString()] ?? 0) + 1
      },
    );

    await _postRepository.updatePost(updatedPost);
    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) posts[postIndex] = updatedPost;
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
    required List<List<Map<String, dynamic>>> taggedUsers, // updated type
    bool isCarousel2 = false,
    DateTime? electionEndTime,
  }) async {
    isLoading.value = true;
    final user = Get.find<AuthController>().userModel.value!;

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
      taggedUsers: flatRawTags, // for backward compatibility
      description: caption,
      electionEndTime: isCarousel2 ? null : electionEndTime!,
      likedBy: [],
      userVotes: {},
      imageVotes: {},
      link: '',
      communityId: selectedCommunity.id,
      taggedNames: taggedNames,
      taggedUids: taggedUids,
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
    required dynamic file, // Changed to dynamic
  }) async {
    setLoading(true);
    final postId = const Uuid().v1();
    final user = Get.find<AuthController>().userModel.value!;

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

  /// Helper to convert Uint8List to File.
  File _convertUint8ListToFile(Uint8List bytes, String fileName) {
    final file = File('${Directory.systemTemp.path}/$fileName');
    file.writeAsBytesSync(bytes);
    return file;
  }
}
