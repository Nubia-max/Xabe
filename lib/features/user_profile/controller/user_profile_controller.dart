// user_profile_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:xabe/models/post_model.dart';
import 'package:xabe/models/user_model.dart';
import '../../../core/providers/storage_repository.dart';
import '../../../core/utils/utils.dart';
import '../../auth/controller/auth_controller.dart';
import '../repository/user_profile_repository.dart';

/// Utility to compress images.
Future<Uint8List> compressImage(File file) async {
  final image = img.decodeImage(await file.readAsBytes());
  final resized = img.copyResize(image!, width: 800);
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

class UserProfileController extends GetxController {
  final UserProfileRepository _userProfileRepository;
  final StorageRepository _storageRepository;

  // Reactive loading state.
  var isLoading = false.obs;

  UserProfileController({
    required UserProfileRepository userProfileRepository,
    required StorageRepository storageRepository,
  })  : _userProfileRepository = userProfileRepository,
        _storageRepository = storageRepository;

  /// Returns a stream of UserModel for the given uid.
  Stream<UserModel> getUserData(String uid) {
    return _userProfileRepository.getUserData(uid);
  }

  /// Edit the user profile.
  Future<void> editCommunity({
    File? profileFile,
    required BuildContext context,
    required String name, // new username to update
    required String bio,
  }) async {
    isLoading.value = true;
    UserModel user = Get.find<AuthController>().userModel.value!;

    // Check if the new username is taken by another user
    final existingUsers = await _userProfileRepository.searchUsers(name).first;

    final usernameTakenByOther = existingUsers.any(
        (u) => u.name.toLowerCase() == name.toLowerCase() && u.uid != user.uid);

    if (usernameTakenByOther) {
      isLoading.value = false;
      showSnackBar(context, 'This username is already taken.');
      return;
    }

    Future<void> handleFileUpload(File? file, String path) async {
      if (file == null) return;
      final compressedBytes = await compressImage(file);
      final res = await _storageRepository.storeFile(
        path: path,
        id: user.uid,
        file: compressedBytes,
      );
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) {
          if (path.contains('profile')) {
            user = user.copyWith(profilePic: r);
          } else {
            user = user.copyWith();
          }
        },
      );
    }

    await handleFileUpload(profileFile, 'users/profile');

    // Update the user's name and bio.
    user = user.copyWith(name: name, bio: bio);

    final res = await _userProfileRepository.editProfile(user);
    isLoading.value = false;

    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) {
        Get.find<AuthController>().updateUser(user);
        Get.back();
      },
    );
  }

  /// Returns a stream of posts for the given user.
  Stream<List<Post>> getUserPosts(String uid) {
    return _userProfileRepository.getUserPosts(uid);
  }
}
