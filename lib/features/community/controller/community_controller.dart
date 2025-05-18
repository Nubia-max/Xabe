import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xabe/core/constants/constants.dart';
import 'package:xabe/core/utils/utils.dart';
import 'package:xabe/features/community/repository/community_repository.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';
import 'package:xabe/features/notifications/notification_controller.dart';
import 'package:xabe/core/failure.dart';
import 'package:xabe/core/providers/storage_repository.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';

import '../../../core/constants/firebase_constants.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize Firestore and FirebaseStorage instances
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

    // Register repositories with GetX
    Get.put<CommunityRepository>(CommunityRepository(firestore: firestore));
    Get.put<StorageRepository>(
        StorageRepository(firebaseStorage: firebaseStorage));

    // Register the controller and inject the repositories
    Get.put<CommunityController>(
      CommunityController(
        communityRepository: Get.find<CommunityRepository>(),
        storageRepository: Get.find<StorageRepository>(),
      ),
    );
  }
}

class CommunityController extends GetxController {
  var isLoading = false.obs;

  final CommunityRepository communityRepository;
  final StorageRepository storageRepository;

  RxList<Community> userCommunities = <Community>[].obs;

  CommunityController({
    required this.communityRepository,
    required this.storageRepository,
  });

  @override
  void onInit() {
    super.onInit();
    final uid = AuthController.to.userModel.value?.uid;
    if (uid != null) {
      communityRepository.getUserCommunities(uid).listen((communities) {
        userCommunities.assignAll(communities);
      });
    }
  }

  Future<void> joinCommunityWithVerification(
    Community community,
    BuildContext context,
    dynamic verificationFileOrData,
  ) async {
    final user = AuthController.to.userModel.value;
    if (user == null) {
      showSnackBar(context, 'User not found');
      return;
    }

    Either<Failure, String> uploadRes;
    if (kIsWeb) {
      uploadRes = await storageRepository.storeFileFromBytes(
        path: 'community_verifications/${community.id}',
        id: user.uid,
        bytes: verificationFileOrData,
      );
    } else {
      uploadRes = await storageRepository.storeFile(
        path: 'community_verifications/${community.id}',
        id: user.uid,
        file: verificationFileOrData,
      );
    }

    uploadRes.fold(
      (failure) => showSnackBar(context, failure.message),
      (verificationImageUrl) async {
        final res = await communityRepository.requestJoinCommunity(
          community.id,
          user.uid,
        );
        res.fold(
          (failure) => showSnackBar(context, failure.message),
          (_) {
            for (final modUid in community.mods) {
              Get.find<NotificationController>().sendNotification(
                recipientId: modUid,
                senderId: user.uid,
                senderName: user.name,
                message: "${user.name} wants to join ${community.name}",
                type: "join_request",
                communityId: community.id,
                communityName: community.name,
                verificationImageUrl: verificationImageUrl,
              );
            }
            showSnackBar(context, 'Join request sent. Awaiting approval.');
          },
        );
      },
    );
  }

  // Create community method
  Future<void> createCommunity(
    String name,
    String bio,
    bool requiresVerification,
    BuildContext context, {
    String communityType = 'regular', // new optional parameter with default
  }) async {
    isLoading.value = true;
    // Check if community with this name already exists
    final existingCommunities =
        await communityRepository.searchCommunity(name).first;

    if (existingCommunities
        .any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      isLoading.value = false;
      showSnackBar(context, 'Community with this name already exists.');
      return;
    }
    final String uid = AuthController.to.userModel.value?.uid ?? '';
    final String communityId = Uuid().v4();

    Community community = Community(
      id: communityId,
      name: name,
      avatar: Constants.avatarDefault,
      members: [uid],
      mods: [uid],
      bio: bio,
      requiresVerification: requiresVerification,
      pendingMembers: [],
      creatorUid: uid,
    );

    final res = await communityRepository.createCommunity(community);
    isLoading.value = false;

    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        showSnackBar(context, 'Community created successfully!');
        Get.back();
      },
    );
  }

  // Method to join community
  Future<void> joinCommunity(Community community, BuildContext context) async {
    final user = AuthController.to.userModel.value;
    if (user == null) {
      showSnackBar(context, 'User not found');
      return;
    }
    if (community.members.contains(user.uid)) {
      showSnackBar(context, 'You are already a member of this community.');
      return;
    }
    if (community.pendingMembers.contains(user.uid)) {
      showSnackBar(context, 'Your join request is already pending.');
      return;
    }
    final res =
        await communityRepository.requestJoinCommunity(community.id, user.uid);
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        for (final modUid in community.mods) {
          Get.find<NotificationController>().sendNotification(
            recipientId: modUid,
            senderId: user.uid,
            senderName: user.name,
            message: "${user.name} wants to join ${community.name}",
            type: "join_request",
            communityId: community.id,
            communityName: community.name,
          );
        }
        showSnackBar(context, 'Join request sent. Awaiting approval.');
      },
    );
  }

  Future<void> joinCommunityImmediately(Community community, String uid) async {
    try {
      // Add to members
      final updatedMembers = [...community.members, uid];

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(community.id)
          .update({
        'members': updatedMembers,
        'pendingMembers': FieldValue.arrayRemove([uid]), // just in case
      });

      // Update local model if you're holding state
      community.members.add(uid);
      community.pendingMembers.remove(uid);

      update(); // if using GetBuilder or GetX for UI updates
    } catch (e) {
      print('Error joining community: $e');
    }
  }

  Future<void> refreshUserCommunities() async {
    final uid = AuthController.to.userModel.value?.uid;
    if (uid == null) return;
    try {
      isLoading.value = true;
      final communities = await communityRepository.getUserCommunitiesOnce(uid);
      userCommunities.assignAll(communities);
    } catch (e) {
      print('Failed to refresh communities: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// When moderator accepts a join request, send a notification to the user.
  Future<void> acceptJoinRequest(
      String communityId, String userId, BuildContext context) async {
    // Optionally, if you need the community object, fetch it using the communityId
    final community =
        await communityRepository.getCommunityById(communityId).first;
    final res =
        await communityRepository.acceptJoinRequest(communityId, userId);
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        showSnackBar(context, 'User has been accepted.');
        Get.find<NotificationController>().sendNotification(
          recipientId: userId,
          senderId: AuthController.to.userModel.value?.uid ?? 'moderator',
          senderName: 'Moderator',
          message: "Join request accepted",
          type: "join_accepted",
          communityId: communityId,
          communityName: community.name, // Use fetched community name.
        );
      },
    );
  }

  Future<void> declineJoinRequest(
      String communityId, String userId, BuildContext context) async {
    final res = await communityRepository.declineJoinRequest(
        communityId, userId); // Decline based on communityId
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        showSnackBar(context, 'Join request declined.');
      },
    );
  }

  /// Fetch community users as a stream of maps containing uid and username.
  Stream<List<Map<String, String>>> fetchCommunityUsers(
      String communityId) async* {
    await for (var userIds
        in communityRepository.getCommunityUsers(communityId)) {
      List<Map<String, String>> users = [];
      for (var uid in userIds) {
        final username = await AuthController.to.getUsernameFromUid(uid);
        users.add({'uid': uid, 'username': username});
      }
      yield users;
    }
  }

  /// Get communities the current user belongs to.
  Stream<List<Community>> getUserCommunitiesStream() {
    final uid = AuthController.to.userModel.value?.uid;
    if (uid == null) return const Stream.empty();
    return communityRepository.getUserCommunities(uid);
  }

  /// Get a community by its id.
  Stream<Community> getCommunityById(String id) {
    return communityRepository.getCommunityById(id);
  }

  /// Edit community details.
  Future<void> editCommunity({
    required File? profileFile,
    required File? bannerFile,
    required BuildContext context,
    required Community community,
    required String bio,
    required bool requiresVerification,
    required String newName, // pass the new name here
  }) async {
    isLoading.value = true;

    // Check if newName is taken by another community
    final existingCommunities =
        await communityRepository.searchCommunity(newName).first;

    final nameTakenByOther = existingCommunities.any((c) =>
        c.name.toLowerCase() == newName.toLowerCase() && c.id != community.id);

    if (nameTakenByOther) {
      isLoading.value = false;
      showSnackBar(context, 'Another community with this name already exists.');
      return;
    }

    if (profileFile != null) {
      final res = await storageRepository.storeFile(
        path: 'communities/profile',
        id: community.id,
        file: profileFile,
      );
      res.fold(
        (failure) => showSnackBar(context, failure.message),
        (downloadUrl) => community = community.copyWith(avatar: downloadUrl),
      );
    }
    if (bannerFile != null) {
      final res = await storageRepository.storeFile(
        path: 'communities/banner',
        id: community.id,
        file: bannerFile,
      );
      res.fold(
        (failure) => showSnackBar(context, failure.message),
        (downloadUrl) => community = community.copyWith(banner: downloadUrl),
      );
    }

    // Update mutable fields including the new name
    community = community.copyWith(
      bio: bio,
      name: newName, // use the passed newName here
      requiresVerification: requiresVerification,
    );

    final res = await communityRepository.editCommunity(community);

    isLoading.value = false;

    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) => Get.back(),
    );
  }

  /// Search for communities.
  Stream<List<Community>> searchCommunity(String query) {
    return communityRepository.searchCommunity(query);
  }

  /// Add moderators.
  Future<void> addMods(
    String communityId,
    List<String> newMods,
    BuildContext context,
  ) async {
    // 1) Fetch the “old” list of mods before we overwrite it
    final community =
        await communityRepository.getCommunityById(communityId).first;
    final oldMods = community.mods;

    // 2) Push the new list of mods up to Firestore
    final res = await communityRepository.addMods(communityId, newMods);
    res.fold(
      (failure) {
        showSnackBar(context, failure.message);
      },
      (_) async {
        // 3) Compute who was *just* added
        final justAdded = newMods.where((uid) => !oldMods.contains(uid));

        // 4) Notify each of those—and only those
        for (final uid in justAdded) {
          Get.find<NotificationController>().sendNotification(
            recipientId: uid,
            senderId: AuthController.to.userModel.value?.uid ?? 'system',
            senderName: 'System',
            message: "You have been added as a moderator in ${community.name}",
            type: "new_mod",
            communityId: community.id,
            communityName: community.name,
          );
        }

        // 5) Go back once it’s all done
        Get.back();
      },
    );
  }

  Future<List<Community>> getAllCommunitiesFuture() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('communities').get();

    return snapshot.docs.map((doc) => Community.fromMap(doc.data())).toList();
  }

  Future<void> leaveCommunity(Community community, String uid) async {
    try {
      final updatedMembers = List<String>.from(community.members)..remove(uid);

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(community.id)
          .update({
        'members': updatedMembers,
      });

      // Optional: update local model if held in memory
      community.members.remove(uid);
      update();
    } catch (e) {
      print('Error leaving community: $e');
      showSnackBar(Get.context!, 'Failed to leave community');
    }
  }

  /// Get posts for a community.
  Stream<List<Post>> getCommunityPosts(String communityId) {
    print('[DEBUG] Fetching posts for communityId: $communityId'); // ✅ Add this
    return communityRepository.getCommunityPosts(communityId);
  }

  Stream<List<Community>> getAllCommunities() {
    return FirebaseFirestore.instance
        .collection(FirebaseConstants.communitiesCollection)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Community.fromMap(doc.data())).toList());
  }

  // Optional: Local cache of communities.
  RxList<Community> userCommunitiesCache = <Community>[].obs;
}
