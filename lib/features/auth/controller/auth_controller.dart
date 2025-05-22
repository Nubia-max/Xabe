import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xabe/features/auth/repository/auth_repository.dart';
import 'package:xabe/models/user_model.dart';
import '../../../core/failure.dart';
import '../../../core/terms_screen.dart';
import '../../../models/community_model.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final AuthRepository _authRepository;
  var isLoading = false.obs;
  var userModel = Rxn<UserModel>();

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  void onInit() {
    super.onInit();

    _authRepository.authStateChange.listen((User? firebaseUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (firebaseUser == null) {
          Get.offAllNamed('/login');
        } else {
          // Fetch user once instead of listening indefinitely
          final user =
              await _authRepository.getUserData(firebaseUser.uid).first;
          userModel.value = user;

          final prefs = await SharedPreferences.getInstance();
          final version = prefs.getInt(kEulaVersionKey) ?? 0;

          if (version < kCurrentEulaVersion) {
            Get.offAllNamed('/terms');
          } else {
            Get.offAllNamed('/');
          }

          // Now start listening to user data changes but WITHOUT navigation
          _authRepository.getUserData(firebaseUser.uid).listen((user) {
            userModel.value = user;
            // No navigation here
          });
        }
      });
    });
  }

  void updateUser(UserModel user) {
    userModel.value = user;
  }

  Future<void> signInWithGoogle(bool isFromLogin) async {
    try {
      isLoading.value = true;
      final result = await _authRepository.signInWithGoogle(isFromLogin);
      isLoading.value = false;
      result.fold(
        (failure) => Get.snackbar("Sign In Error", failure.message),
        (user) => userModel.value = user,
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
        (failure) => Get.snackbar("Sign In Error", failure.message),
        (user) => userModel.value = user,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString());
    }
  }

  Future<String> getUsernameFromUid(String uid) async {
    try {
      final userData = await _authRepository.getUserData(uid).first;
      return userData.name;
    } catch (e) {
      return 'Unknown User';
    }
  }

  Stream<UserModel> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }

  Future<void> logout() async {
    await _authRepository.logOut();
    userModel.value = null;
    Get.offAllNamed('/login');
  }

  Future<void> deleteAccount() async {
    isLoading.value = true;
    final Either<Failure, void> result = await _authRepository.deleteAccount();
    isLoading.value = false;

    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {
        userModel.value = null;
        Get.offAllNamed('/login');
      },
    );
  }

  bool isModerator(Community community) {
    final user = userModel.value;
    if (user == null) return false;
    return community.mods.contains(user.uid);
  }

  /// Adds funds to the user's balance, updates backend and local model
  Future<void> addFundsToUserBalance(double amount) async {
    final user = userModel.value;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    isLoading.value = true;

    final newBalance = (user.balance ?? 0) + amount;

    // Assuming your backend expects this update, and your AuthRepository has updateUserBalance
    final result =
        await _authRepository.updateUserBalance(user.uid, newBalance);

    isLoading.value = false;

    result.fold(
      (failure) {
        Get.snackbar('Error', failure.message);
      },
      (_) {
        // Update local user model with new balance
        userModel.update((val) {
          if (val != null) {
            userModel.value = val.copyWith(balance: newBalance);
          }
        });

        Get.snackbar('Success', 'Your balance has been updated');
      },
    );
  }

  /// Reload user data from backend
  Future<void> reloadUser() async {
    final currentUser = userModel.value;
    if (currentUser == null) return;

    try {
      final updatedUser =
          await _authRepository.getUserData(currentUser.uid).first;
      userModel.value = updatedUser;
    } catch (e) {
      debugPrint('Failed to reload user: $e');
    }
  }
}
