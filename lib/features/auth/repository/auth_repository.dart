import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:xabe/core/constants/constants.dart';
import 'package:xabe/core/constants/firebase_constants.dart';
import 'package:xabe/core/failure.dart';
import 'package:xabe/models/user_model.dart';

import '../../../core/type_def.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _firestore = firestore,
        _auth = auth,
        _googleSignIn = googleSignIn;

  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  Stream<User?> get authStateChange => _auth.authStateChanges();

  FutureEither<UserModel> signInWithGoogle(bool isFromLogin) async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // For web, use the popup flow with GoogleAuthProvider
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider
            .addScope('https://www.googleapis.com/auth/userinfo.email');
        googleProvider
            .addScope('https://www.googleapis.com/auth/userinfo.profile');

        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return left(Failure('Google sign-in failed: No user data received'));
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        if (isFromLogin) {
          userCredential = await _auth.signInWithCredential(credential);
        } else {
          userCredential =
              await _auth.currentUser!.linkWithCredential(credential);
        }
      }

      UserModel userModel;
      if (userCredential.additionalUserInfo!.isNewUser) {
        userModel = UserModel(
          name: userCredential.user!.displayName ?? 'No Name',
          profilePic: userCredential.user!.photoURL ?? Constants.avatarDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          bio: '',
          blockedUsers: [], // Initialize blockedUsers as empty list
        );
        await _users.doc(userCredential.user!.uid).set(userModel.toMap());
      } else {
        final docSnapshot = await _users.doc(userCredential.user!.uid).get();
        if (!docSnapshot.exists || docSnapshot.data() == null) {
          return left(Failure('User data not found'));
        }
        userModel =
            UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
      }
      return right(userModel);
    } on FirebaseException catch (e) {
      return left(Failure(e.message ?? 'Firebase error'));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Stream to fetch user data
  Stream<UserModel> getUserData(String uid) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .handleError((error) {
      throw Failure('Failed to fetch user data: $error');
    }).asyncMap((snapshot) async {
      if (!snapshot.exists) {
        final user = UserModel(
          uid: uid,
          name: 'New User',
          profilePic: Constants.avatarDefault,
          bio: '',
          isAuthenticated: true,
          blockedUsers: [], // Initialize with an empty list
        );
        await snapshot.reference.set(user.toMap());
        return user;
      }
      return UserModel.fromMap(snapshot.data()!);
    });
  }

  // In auth_repository.dart

// Block a user
  Future<void> blockUser(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Add target user to the current user's blocked list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({
      'blockedUsers':
          FieldValue.arrayUnion([targetUserId]), // Add to blockedUsers
    });

    // Optionally, show feedback to the user
    Get.snackbar('Blocked', 'The user has been blocked successfully.');
  }
  // In auth_repository.dart

// Method to get blocked users
  Stream<List<String>> getBlockedUsers(String currentUserId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data != null && data['blockedUsers'] != null) {
        return List<String>.from(data['blockedUsers']);
      } else {
        return [];
      }
    });
  }

// Unblock a user
  Future<void> unblockUser(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Remove target user from the current user's blocked list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({
      'blockedUsers':
          FieldValue.arrayRemove([targetUserId]), // Remove from blockedUsers
    });

    // Optionally, show feedback to the user
    Get.snackbar('Unblocked', 'The user has been unblocked successfully.');
  }

  // Function to log out the user
  Future<void> logOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Function to sign in with Apple
  FutureEither<UserModel> signInWithApple(bool isFromLogin) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      UserCredential userCredential;
      if (isFromLogin) {
        userCredential = await _auth.signInWithCredential(oauthCredential);
      } else {
        userCredential =
            await _auth.currentUser!.linkWithCredential(oauthCredential);
      }

      UserModel userModel;
      if (userCredential.additionalUserInfo!.isNewUser) {
        final displayName = appleCredential.givenName ?? "No Name";
        userModel = UserModel(
          name: displayName,
          profilePic: Constants.avatarDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          bio: '',
          blockedUsers: [], // Initialize blockedUsers for new users
        );
        await _users.doc(userModel.uid).set(userModel.toMap());
      } else {
        final doc = await _users.doc(userCredential.user!.uid).get();
        if (!doc.exists) return left(Failure('User data not found'));
        userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return right(userModel);
    } on FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Apple sign-in failed.'));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Function to generate a nonce for Apple sign-in
  String _generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Function to generate SHA-256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Function to delete the user's account
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return left(Failure('No user is currently signed in.'));
      }

      final uid = user.uid;

      // 1) Delete Firestore user document
      await _firestore.collection('users').doc(uid).delete();

      // 2) Delete Firebase Auth user
      await user.delete();

      return right(null);
    } on FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Failed to delete account.'));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
}
