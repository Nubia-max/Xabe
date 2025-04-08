// repositories/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:google_sign_in/google_sign_in.dart';
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
        // Optionally, add additional scopes:
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
          banner: Constants.bannerDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          bio: '',
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
          banner: Constants.bannerDefault,
          bio: '',
          isAuthenticated: true,
        );
        await snapshot.reference.set(user.toMap());
        return user;
      }
      return UserModel.fromMap(snapshot.data()!);
    });
  }

  Future<void> logOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
