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

  // Request to join a community (adds user UID to pendingMembers)
  FutureVoid requestJoinCommunity(String communityName, String userId) async {
    try {
      return right(_communities.doc(communityName).update({
        'pendingMembers': FieldValue.arrayUnion([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Moderator accepts a join request
  FutureVoid acceptJoinRequest(String communityName, String userId) async {
    try {
      await _communities.doc(communityName).update({
        'pendingMembers': FieldValue.arrayRemove([userId]),
        'members': FieldValue.arrayUnion([userId]),
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Moderator declines a join request
  FutureVoid declineJoinRequest(String communityName, String userId) async {
    try {
      return right(_communities.doc(communityName).update({
        'pendingMembers': FieldValue.arrayRemove([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Create a community.
  FutureVoid createCommunity(Community community) async {
    try {
      var communityDoc = await _communities.doc(community.name).get();
      if (communityDoc.exists) {
        throw 'Association with the same name already exists!';
      }
      return right(_communities.doc(community.name).set(community.toMap()));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Join community (adds user to members).
  FutureVoid joinCommunity(String communityName, String userId) async {
    try {
      return right(_communities.doc(communityName).update({
        'members': FieldValue.arrayUnion([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Leave community (removes user from members).
  FutureVoid leaveCommunity(String communityName, String userId) async {
    try {
      return right(_communities.doc(communityName).update({
        'members': FieldValue.arrayRemove([userId]),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Get community users.
  Stream<List<String>> getCommunityUsers(String communityName) {
    return _communities.doc(communityName).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        List<String> members = List<String>.from(data['members'] ?? []);
        return members;
      }
      return [];
    });
  }

  // Get communities for a user.
  Stream<List<Community>> getUserCommunities(String uid) {
    return _communities
        .where('members', arrayContains: uid)
        .snapshots()
        .map((event) {
      List<Community> communities = [];
      for (var doc in event.docs) {
        communities.add(Community.fromMap(doc.data() as Map<String, dynamic>));
      }
      return communities;
    });
  }

  // Get a community by name.
  Stream<Community> getCommunityByName(String name) {
    return _communities.doc(name).snapshots().map(
          (event) => Community.fromMap(event.data() as Map<String, dynamic>),
        );
  }

  // Edit community.
  FutureVoid editCommunity(Community community) async {
    try {
      return right(_communities.doc(community.name).update(community.toMap()));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Search communities with a case-insensitive query.
  Stream<List<Community>> searchCommunity(String query) {
    final lowerQuery = query.toLowerCase();
    return _communities
        .where('nameLower', isGreaterThanOrEqualTo: lowerQuery)
        .where('nameLower', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .snapshots()
        .map((event) {
      List<Community> communities = [];
      for (var community in event.docs) {
        communities
            .add(Community.fromMap(community.data() as Map<String, dynamic>));
      }
      return communities;
    });
  }

  // Add moderators.
  FutureVoid addMods(String communityName, List<String> uids) async {
    try {
      return right(_communities.doc(communityName).update({
        'mods': uids,
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Get posts for a community.
  Stream<List<Post>> getCommunityPosts(String name) {
    return _posts
        .where('communityName', isEqualTo: name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((e) => Post.fromMap(e.data() as Map<String, dynamic>))
            .toList());
  }

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);

  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
}
