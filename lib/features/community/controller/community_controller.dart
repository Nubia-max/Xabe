import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import 'package:xabe/core/constants/constants.dart';
import 'package:xabe/core/utils.dart';
import 'package:xabe/features/community/repository/community_repository.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';
import 'package:xabe/features/notifications/notification_controller.dart';
import 'package:xabe/core/failure.dart';
import 'package:xabe/core/providers/storage_repository.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';

class CommunityController extends GetxController {
  // Reactive loading state.
  var isLoading = false.obs;

  // Dependencies injected via constructor.
  final CommunityRepository communityRepository;
  final StorageRepository storageRepository;

  // Observable list of communities.
  RxList<Community> userCommunities = <Community>[].obs;

  CommunityController({
    required this.communityRepository,
    required this.storageRepository,
  });

  @override
  void onInit() {
    super.onInit();
    // Get the current user's uid.
    final uid = AuthController.to.userModel.value?.uid;
    if (uid != null) {
      debugPrint("CommunityController.onInit: uid = $uid");
      // Listen to Firebase changes for communities the user belongs to.
      communityRepository.getUserCommunities(uid).listen((communities) {
        debugPrint("Received ${communities.length} communities from Firestore");
        userCommunities.assignAll(communities);
      });
    } else {
      debugPrint(
          "CommunityController.onInit: uid is null; user might not be authenticated yet.");
    }
  }

  /// Create a new community.
  Future<void> createCommunity(
      String name, String bio, BuildContext context) async {
    isLoading.value = true;
    final String uid = AuthController.to.userModel.value?.uid ?? '';
    // Create a new Community instance with default values.
    Community community = Community(
      id: name,
      name: name,
      banner: Constants.bannerDefault,
      avatar: Constants.avatarDefault,
      members: [uid],
      mods: [uid],
      bio: bio,
      pendingMembers: [],
    );
    final res = await communityRepository.createCommunity(community);
    isLoading.value = false;
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        showSnackBar(context, 'Association created successfully!');
        Get.back();
      },
    );
  }

  /// Join a community.
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
    final res = await communityRepository.requestJoinCommunity(
        community.name, user.uid);
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        // Send notifications to moderators.
        for (final modUid in community.mods) {
          Get.find<NotificationController>().sendNotification(
            recipientId: modUid,
            senderId: user.uid,
            message: "${user.name} wants to join ${community.name}",
            type: "join_request",
            communityId: community.name,
          );
        }
        showSnackBar(context, 'Join request sent. Awaiting approval.');
      },
    );
  }

  /// When moderator accepts a join request, send a notification to the user.
  Future<void> acceptJoinRequest(
      String communityName, String userId, BuildContext context) async {
    final res =
        await communityRepository.acceptJoinRequest(communityName, userId);
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        showSnackBar(context, 'User has been accepted.');
        Get.find<NotificationController>().sendNotification(
          recipientId: userId,
          senderId: AuthController.to.userModel.value?.uid ?? 'moderator',
          message: " $communityName ",
          type: "join_accepted",
          communityId: communityName,
        );
      },
    );
  }

  /// Moderator declines a join request.
  Future<void> declineJoinRequest(
      String communityName, String userId, BuildContext context) async {
    final res =
        await communityRepository.declineJoinRequest(communityName, userId);
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) {
        showSnackBar(context, 'Join request declined.');
      },
    );
  }

  /// Fetch community users as a stream of maps containing uid and username.
  Stream<List<Map<String, String>>> fetchCommunityUsers(
      String communityName) async* {
    await for (var userIds
        in communityRepository.getCommunityUsers(communityName)) {
      List<Map<String, String>> users = [];
      for (var uid in userIds) {
        final username = await AuthController.to.getUsernameFromUid(uid);
        users.add({'uid': uid, 'username': username});
      }
      yield users;
    }
  }

  /// Alias for getCommunityUsers.
  Stream<List<Map<String, String>>> getCommunityUsers(String communityName) {
    return fetchCommunityUsers(communityName);
  }

  /// Get communities the current user belongs to.
  Stream<List<Community>> getUserCommunities() {
    final uid = AuthController.to.userModel.value?.uid ?? '';
    return communityRepository.getUserCommunities(uid);
  }

  /// Get a community by its name.
  Stream<Community> getCommunityByName(String name) {
    return communityRepository.getCommunityByName(name);
  }

  /// Edit community details.
  Future<void> editCommunity({
    required File? profileFile,
    required File? bannerFile,
    required BuildContext context,
    required Community community,
    required String bio,
  }) async {
    isLoading.value = true;
    if (profileFile != null) {
      final res = await storageRepository.storeFile(
        path: 'communities/profile',
        id: community.name,
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
        id: community.name,
        file: bannerFile,
      );
      res.fold(
        (failure) => showSnackBar(context, failure.message),
        (downloadUrl) => community = community.copyWith(banner: downloadUrl),
      );
    }
    community = community.copyWith(bio: bio);
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
      String communityName, List<String> uids, BuildContext context) async {
    final res = await communityRepository.addMods(communityName, uids);
    res.fold(
      (failure) => showSnackBar(context, failure.message),
      (_) => Get.back(),
    );
  }

  /// Join a community with verification.
  Future<void> joinCommunityWithVerification(Community community,
      BuildContext context, dynamic verificationFileOrData) async {
    final user = AuthController.to.userModel.value;
    if (user == null) {
      showSnackBar(context, 'User not found');
      return;
    }
    Either<Failure, String> uploadRes;
    if (kIsWeb) {
      uploadRes = await storageRepository.storeFileFromBytes(
        path: 'community_verifications/${community.name}',
        id: user.uid,
        bytes: verificationFileOrData,
      );
    } else {
      uploadRes = await storageRepository.storeFile(
        path: 'community_verifications/${community.name}',
        id: user.uid,
        file: verificationFileOrData,
      );
    }
    uploadRes.fold(
      (failure) => showSnackBar(context, failure.message),
      (verificationImageUrl) async {
        final res = await communityRepository.requestJoinCommunity(
            community.name, user.uid);
        res.fold(
          (failure) => showSnackBar(context, failure.message),
          (_) {
            for (final modUid in community.mods) {
              Get.find<NotificationController>().sendNotification(
                recipientId: modUid,
                senderId: user.uid,
                message: "${user.name} wants to join ${community.name}",
                type: "join_request",
                communityId: community.name,
                verificationImageUrl: verificationImageUrl,
              );
            }
            showSnackBar(context, 'Join request sent. Awaiting approval.');
          },
        );
      },
    );
  }

  /// Get posts for a community.
  Stream<List<Post>> getCommunityPosts(String name) {
    return communityRepository.getCommunityPosts(name);
  }

  /// Alternative stream for user's communities.
  Stream<List<Community>> getUserCommunitiesStream() {
    final user = AuthController.to.userModel.value;
    if (user == null) return Stream.value([]);
    return communityRepository.getUserCommunities(user.uid);
  }

  // Optional: Local cache of communities.
  RxList<Community> userCommunitiesCache = <Community>[].obs;
}
