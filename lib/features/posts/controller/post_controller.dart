import 'dart:io';
import 'dart:typed_data';

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
  // Reactive state for the list of posts.
  var posts = <Post>[].obs;
  // Reactive loading indicator.
  var isLoading = false.obs;

  final PostRepository _postRepository;
  final StorageRepository _storageRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PostController({
    required PostRepository postRepository,
    required StorageRepository storageRepository,
  })  : _postRepository = postRepository,
        _storageRepository = storageRepository;

  /// Sets the loading state.
  void setLoading(bool value) {
    isLoading.value = value;
  }

  /// Deletes a post.
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

  /// Votes for a candidate (image option) in a post.
  Future<void> voteForCandidate(String postId, int index) async {
    final user = Get.find<AuthController>().userModel.value;
    if (user == null || !user.isAuthenticated) return;

    final post = await _postRepository.getPostByIdFuture(postId);
    if (post == null || post.userVotes.containsKey(user.uid)) {
      print('Already voted or post not found');
      return;
    }

    final updatedUserVotes = Map<String, int>.from(post.userVotes);
    updatedUserVotes[user.uid] = index;

    final updatedImageVotes = Map<String, int>.from(post.imageVotes);
    updatedImageVotes[index.toString()] =
        (updatedImageVotes[index.toString()] ?? 0) + 1;

    final updatedPost = post.copyWith(
      userVotes: updatedUserVotes,
      imageVotes: updatedImageVotes,
    );

    // Update Firebase.
    await _postRepository.updatePost(updatedPost);
    print('Updated post in Firebase');

    // Update local state.
    final postIndex = posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      posts[postIndex] = updatedPost;
      print('Local state updated');
    }
  }

  /// Likes or unlikes a post.
  Future<void> likePost(String postId, String userId,
      {required bool isLiking}) async {
    final firestore = Get.find<FirebaseFirestore>();
    final post = await _postRepository.getPostByIdFuture(postId);
    if (post == null) return;

    if (isLiking) {
      if (!post.likedBy.contains(userId)) {
        await firestore
            .collection(FirebaseConstants.postsCollection)
            .doc(postId)
            .update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId])
        });
        final updatedPost = post.copyWith(
          likes: post.likes + 1,
          likedBy: [...post.likedBy, userId],
        );
        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          posts[postIndex] = updatedPost;
        }
      }
    } else {
      if (post.likedBy.contains(userId)) {
        await firestore
            .collection(FirebaseConstants.postsCollection)
            .doc(postId)
            .update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId])
        });
        final updatedLikedBy = List<String>.from(post.likedBy)..remove(userId);
        final updatedPost = post.copyWith(
          likes: post.likes - 1,
          likedBy: updatedLikedBy,
        );
        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          posts[postIndex] = updatedPost;
        }
      }
    }
  }

  /// Shares a text post.
  Future<void> shareTextPost({
    required BuildContext context,
    required String title,
    required Community selectedCommunity,
    required String description,
  }) async {
    setLoading(true);
    String postId = const Uuid().v1();
    final user = Get.find<AuthController>().userModel.value!;
    final Post post = Post(
      id: postId,
      title: title,
      communityName: selectedCommunity.id,
      communityProfilePic: selectedCommunity.avatar,
      commentCount: 0,
      username: user.name,
      uid: user.uid,
      type:
          'text', // Make sure the type is correctly assigned (image, text, link, etc.)
      createdAt: DateTime.now(),
      description: description,
      imageUrls: [],
      likedBy: [],
      userVotes: {},
      imageVotes: {},
      taggedUsers: [],
      link: '',
      electionEndTime: DateTime.now(),
      communityId: selectedCommunity.id, // Ensure communityId is set correctly
    );

    final res = await _postRepository.addPost(post);
    setLoading(false);
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
              message: "New post in ${selectedCommunity.id}: $title",
              type: "new_post",
              communityId: selectedCommunity.id,
            );
          }
        }
      },
    );
  }

  /// Shares a link post.
  Future<void> shareLinkPost({
    required BuildContext context,
    required String title,
    required String caption,
    required Community selectedCommunity,
    required String link,
  }) async {
    setLoading(true);
    String postId = const Uuid().v1();
    final user = Get.find<AuthController>().userModel.value!;
    final Post post = Post(
      id: postId,
      title: title,
      communityName: selectedCommunity.id,
      communityProfilePic: selectedCommunity.avatar,
      commentCount: 0,
      username: user.name,
      uid: user.uid,
      type: 'link',
      createdAt: DateTime.now(),
      link: link,
      description: caption,
      imageUrls: [],
      likedBy: [],
      userVotes: {},
      imageVotes: {},
      taggedUsers: [],
      electionEndTime: DateTime.now(), communityId: '', // Adjust as needed.
    );

    final res = await _postRepository.addPost(post);
    setLoading(false);
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
              message: "New post in ${selectedCommunity.id}: $title",
              type: "new_post",
              communityId: selectedCommunity.id,
            );
          }
        }
      },
    );
  }

  /// Helper function to compress an image file (mobile only).
  Future<File?> compressImage(File file) async {
    if (kIsWeb) return file; // Skip compression on web.
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // Adjust quality as needed.
        minWidth: 800,
        minHeight: 600,
      );
      if (result == null) return file;
      return result as File;
    } catch (e) {
      debugPrint('Compression failed: $e');
      return file;
    }
  }

  /// Shares a carousel post (or carousel2 if isCarousel2 is true).
  Future<void> shareCarouselPost({
    required BuildContext context,
    required String title,
    required String caption,
    required Community selectedCommunity,
    required List<dynamic>
        files, // Accepts either Uint8List (web) or Uint8List for mobile.
    required List<List<String>> taggedUsers,
    bool isCarousel2 = false,
    DateTime? electionEndTime,
  }) async {
    isLoading.value = true;
    final user = Get.find<AuthController>().userModel.value!;

    // For carousel posts (non-carousel2), only moderators can post.
    if (!isCarousel2 && selectedCommunity.id != "My Profile") {
      final community = await getCommunityById(selectedCommunity.id).first;
      if (!community.mods.contains(user.uid)) {
        showSnackBar(
            context, 'Only moderators can conduct elections in community.');
        isLoading.value = false;
        return;
      }
    }
    if (!isCarousel2 && electionEndTime == null) {
      showSnackBar(context, "Please set an election end time.");
      isLoading.value = false;
      return;
    }
    String postId = const Uuid().v1();
    List<String> imageUrls = [];
    List<String> flatTaggedUsers = [];
    // Upload images concurrently.
    List<Future<Either<Failure, String>>> uploadFutures = [];
    for (int i = 0; i < files.length; i++) {
      Uint8List fileBytes;
      // For web: files[i] may be a Map containing the image bytes.
      if (kIsWeb) {
        if (files[i] is Map && files[i].containsKey("bytes")) {
          fileBytes = files[i]["bytes"];
        } else if (files[i] is Uint8List) {
          fileBytes = files[i];
        } else {
          continue;
        }
        // Generate a unique id for this image.
        String uniqueId = '$postId\_$i';
        uploadFutures.add(_storageRepository.storeFileFromBytes(
          path: 'posts/${selectedCommunity.id}',
          id: uniqueId,
          bytes: fileBytes,
          index: i,
        ));
      } else {
        // For mobile:
        String uniqueId = '$postId\_$i';
        File fileToUpload;
        if (files[i] is File) {
          fileToUpload = files[i];
        } else if (files[i] is Uint8List) {
          fileToUpload = _convertUint8ListToFile(files[i], 'image_$i.jpg');
        } else {
          continue;
        }
        File? compressedFile = await compressImage(fileToUpload);
        uploadFutures.add(_storageRepository.storeFile(
          path: 'posts/${selectedCommunity.id}',
          id: uniqueId,
          file: compressedFile,
          index: i,
        ));
      }
      if (i < taggedUsers.length) {
        flatTaggedUsers.addAll(taggedUsers[i]);
      }
    }
    final results = await Future.wait(uploadFutures);
    for (var res in results) {
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => imageUrls.add(r),
      );
    }
    final Post post = Post(
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
      taggedUsers: flatTaggedUsers,
      description: caption,
      electionEndTime: isCarousel2 ? null : electionEndTime!,
      likedBy: [],
      userVotes: {},
      imageVotes: {},
      link: '',
      communityId: selectedCommunity.id,
    );
    final res = await _postRepository.addPost(post);
    res.fold(
      (l) => showSnackBar(context, l.message),
      (_) => showSnackBar(context, "Post shared successfully!"),
    );
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
              message: "New post in ${selectedCommunity.id}: $title",
              type: "new_post",
              communityId: selectedCommunity.id,
            );
          }
        }
      },
    );
  }

  /// Shares an image post.
  Future<void> shareImagePost({
    required BuildContext context,
    required String title,
    required String caption,
    required Community selectedCommunity,
    required File? file,
  }) async {
    setLoading(true);
    String postId = const Uuid().v1();
    final user = Get.find<AuthController>().userModel.value!;
    // Compress image on mobile before uploading.
    File? fileToUpload = file;
    if (!kIsWeb && file != null) {
      fileToUpload = await compressImage(file);
    }
    final imageRes = await _storageRepository.storeFile(
      path: 'posts/${selectedCommunity.id}',
      id: postId,
      file: fileToUpload,
    );
    imageRes.fold((l) {
      showSnackBar(context, l.message);
      setLoading(false);
    }, (r) async {
      final Post post = Post(
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
        electionEndTime: DateTime.now(), communityId: '', // Adjust as needed.
      );
      final res = await _postRepository.addPost(post);
      setLoading(false);
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
                message: "New post in ${selectedCommunity.id}: $title",
                type: "new_post",
                communityId: selectedCommunity.id,
              );
            }
          }
        },
      );
    });
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
        .where('communityId', isEqualTo: communityId) // Use communityId here
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
