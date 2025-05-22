// repositories/community_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:xabe/core/constants/firebase_constants.dart';
import 'package:xabe/core/failure.dart';
import 'package:xabe/core/type_def.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';

class CommunityRepository {
  final FirebaseFirestore _firestore;
  CommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Request to join a community (uses community ID)
  FutureVoid requestJoinCommunity(String communityId, String userId) async {
    try {
      return right(_communities.doc(communityId).update({
        'pendingMembers': FieldValue.arrayUnion([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Moderator accepts a join request (uses community ID)
  FutureVoid acceptJoinRequest(String communityId, String userId) async {
    try {
      await _communities.doc(communityId).update({
        'pendingMembers': FieldValue.arrayRemove([userId]),
        'members': FieldValue.arrayUnion([userId]),
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Moderator declines a join request (uses community ID)
  FutureVoid declineJoinRequest(String communityId, String userId) async {
    try {
      return right(_communities.doc(communityId).update({
        'pendingMembers': FieldValue.arrayRemove([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Create a community with UUID as document ID
  FutureVoid createCommunity(Community community) async {
    try {
      // Check for existing community name (name must still be unique)
      final querySnapshot =
          await _communities.where('name', isEqualTo: community.id).get();
      if (querySnapshot.docs.isNotEmpty) {
        throw 'Community with the same name already exists!';
      }
      // Save using UUID as document ID
      return right(_communities.doc(community.id).set(community.toMap()));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<List<Community>> getUserCommunitiesOnce(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('communities')
          .where('members', arrayContains: uid)
          .get();

      return snapshot.docs.map((doc) => Community.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to fetch communities: $e');
    }
  }

  // Edit community using UUID
  FutureVoid editCommunity(Community community) async {
    try {
      return right(_communities.doc(community.id).update(community.toMap()));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Join community using UUID
  FutureVoid joinCommunity(String communityId, String userId) async {
    try {
      return right(_communities.doc(communityId).update({
        'members': FieldValue.arrayUnion([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Leave community using UUID
  FutureVoid leaveCommunity(String communityId, String userId) async {
    try {
      return right(_communities.doc(communityId).update({
        'members': FieldValue.arrayRemove([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Get community users by UUID
  Stream<List<String>> getCommunityUsers(String communityId) {
    return _communities.doc(communityId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return List<String>.from(data['members'] ?? []);
      }
      return [];
    });
  }

  // Get communities for a user (unchanged)
  Stream<List<Community>> getUserCommunities(String uid) {
    return _communities.where('members', arrayContains: uid).snapshots().map(
        (event) => event.docs
            .map((doc) => Community.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get community by UUID
  Stream<Community> getCommunityById(String communityId) {
    if (communityId.isEmpty) {
      // Handle the case where the communityId is empty or invalid
      throw ArgumentError("Community ID cannot be empty");
    }

    return _communities.doc(communityId).snapshots().map(
      (snapshot) {
        if (snapshot.exists) {
          // If the document exists, convert Firestore data into a Community object
          return Community.fromMap(snapshot.data()! as Map<String, dynamic>);
        } else {
          // Handle the case where the community does not exist
          throw Exception("Community not found");
        }
      },
    );
  }

  // Search communities by name (unchanged)
  Stream<List<Community>> searchCommunity(String query) {
    final lowerQuery = query.toLowerCase();
    return _communities
        .where('nameLower', isGreaterThanOrEqualTo: lowerQuery)
        .where('nameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .snapshots()
        .map((event) => event.docs
            .map((doc) => Community.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Add moderators using UUID
  FutureVoid addMods(String communityId, List<String> uids) async {
    try {
      return right(_communities.doc(communityId).update({'mods': uids}));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureVoid addFundsToCommunityBalance(
      String communityId, double amount) async {
    try {
      final communityDoc = _communities.doc(communityId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(communityDoc);
        if (!snapshot.exists) throw 'Community does not exist';

        final data = snapshot.data() as Map<String, dynamic>?; // cast first
        final currentBalance = (data?['balance'] ?? 0).toDouble();

        transaction.update(communityDoc, {
          'balance': currentBalance + amount,
        });
      });

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Get posts for a community using UUID
  Stream<List<Post>> getCommunityPosts(String communityId) {
    return _posts
        .where('communityId',
            isEqualTo: communityId) // Changed from communityName
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((e) => Post.fromMap(e.data() as Map<String, dynamic>))
            .toList());
  }

  /// Deletes the community document (and optionally all its posts).
  FutureVoid deleteCommunity(String communityId) async {
    try {
      // 1) Delete all posts in that community
      final postsSnapshot =
          await _posts.where('communityId', isEqualTo: communityId).get();
      for (var doc in postsSnapshot.docs) {
        await _posts.doc(doc.id).delete();
      }

      // 2) Delete the community itself
      await _communities.doc(communityId).delete();

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Firestore references
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);

  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
}
