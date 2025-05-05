import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import 'package:xabe/features/auth/repository/auth_repository.dart';
import 'package:xabe/models/user_model.dart';
import '../../../core/failure.dart';
import '../../../models/community_model.dart';

class AuthController extends GetxController {
  // Static getter to easily access the controller instance.
  static AuthController get to => Get.find();

  final AuthRepository _authRepository;
  // Reactive loading state.
  var isLoading = false.obs;
  // Reactive user model; Rxn allows null values.
  var userModel = Rxn<UserModel>();

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth state changes.
    _authRepository.authStateChange.listen((User? firebaseUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (firebaseUser == null) {
          Get.offAllNamed('/login');
        } else {
          _authRepository
              .getUserData(firebaseUser.uid)
              .listen((UserModel user) {
            userModel.value = user;
            Get.offAllNamed('/');
          });
        }
      });
    });
  }

  /// Update the current user.
  void updateUser(UserModel user) {
    userModel.value = user;
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle(bool isFromLogin) async {
    try {
      isLoading.value = true;
      final result = await _authRepository.signInWithGoogle(isFromLogin);
      isLoading.value = false;
      result.fold(
        (failure) {
          Get.snackbar("Sign In Error", failure.message);
        },
        (user) {
          userModel.value = user as UserModel?;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> signInWithApple(bool isFromLogin) async {
    try {
      isLoading.value = true;
      final result = await _authRepository.signInWithApple(isFromLogin);
      isLoading.value = false;
      result.fold(
        (failure) {
          Get.snackbar("Sign In Error", failure.message);
        },
        (user) {
          userModel.value = user;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString());
    }
  }

  /// Get the username for a given uid.
  Future<String> getUsernameFromUid(String uid) async {
    try {
      final userData = await _authRepository.getUserData(uid).first;
      return userData.name;
    } catch (e) {
      print('Error fetching user data: $e');
      return 'Unknown User';
    }
  }

  /// Expose the getUserData stream.
  Stream<UserModel> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }

  /// Log out the user.
  Future<void> logout() async {
    await _authRepository.logOut();
    userModel.value = null;
    Get.offAllNamed('/login');
  }

  /// Deletes the current user's account.
  /// Throws on failure so the UI can catch and display.
  Future<void> deleteAccount() async {
    isLoading.value = true;
    final Either<Failure, void> result = await _authRepository.deleteAccount();
    isLoading.value = false;

    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {
        // Clear local state and navigate to login:
        userModel.value = null;
        Get.offAllNamed('/login');
      },
    );
  }

  /// Checks if the current user (from Firebase) is a moderator of the community.
  bool isModerator(Community community) {
    if (userModel.value == null) return false;
    return community.mods.contains(userModel.value!.uid);
  }
}
