// repositories/community_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
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

  Future<Either<Failure, String>> createPaystackRecipient({
    required String accountName,
    required String accountNumber,
    required String bankCode,
  }) async {
    const secretKey =
        'sk_live_081a6b72526a9c7fcda22c9f194272fa9ac84e23'; // replace with your Paystack secret key
    final url = Uri.parse('https://api.paystack.co/transferrecipient');

    final headers = {
      'Authorization': 'Bearer $secretKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "type": "nuban",
      "name": accountName,
      "account_number": accountNumber,
      "bank_code": bankCode,
      "currency": "NGN",
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == true) {
        return right(data['data']['recipient_code']);
      } else {
        return left(Failure(data['message'] ?? 'Recipient creation failed'));
      }
    } catch (e) {
      return left(Failure('Error creating recipient: $e'));
    }
  }

  Future<bool> _sendPaystackTransfer({
    required double amount,
    required String recipientCode, // Paystack-recipient code
  }) async {
    const secretKey =
        'sk_live_081a6b72526a9c7fcda22c9f194272fa9ac84e23'; // Replace with your Paystack Secret Key
    final headers = {
      'Authorization': 'Bearer $secretKey',
      'Content-Type': 'application/json',
    };

    final body = {
      'source': 'balance',
      'amount': (amount * 1).toInt(), // Paystack uses kobo
      'recipient': recipientCode,
      'reason': 'Community withdrawal',
    };

    final response = await http.post(
      Uri.parse('https://api.paystack.co/transfer'),
      headers: headers,
      body: jsonEncode(body),
    );

    debugPrint('Paystack payout response: ${response.body}');

    return response.statusCode == 200;
  }

  Future<Either<Failure, void>> withdrawFromCommunity({
    required String communityId,
    required String creatorUid,
    required double amountRequested, // Full amount typed by creator (NGN)
    required String creatorRecipientCode, // Paystack recipient code for creator
  }) async {
    try {
      final communityDoc = _communities.doc(communityId);

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(communityDoc);

        if (!snapshot.exists) {
          return left(Failure('Community does not exist'));
        }

        final data = snapshot.data() as Map<String, dynamic>;

        final balanceRaw = data['balance'] ?? 0;
        final creator = data['creatorUid'];
        final currentBalance =
            (balanceRaw is int) ? balanceRaw.toDouble() : balanceRaw as double;

        if (creator != creatorUid) {
          return left(Failure(
              'You are not authorized to withdraw from this community.'));
        }

        if (currentBalance < amountRequested) {
          return left(Failure('Insufficient community balance.'));
        }

        // Deduct full amount from community balance
        transaction.update(communityDoc, {
          'balance': currentBalance - amountRequested,
        });

        // Calculate actual amount to send to creator (70% of requested)
        final amountToSend = (amountRequested * 0.7);

        // Prepare Paystack Transfer API call
        final url = Uri.parse('https://api.paystack.co/transfer');
        final secretKey =
            'sk_live_081a6b72526a9c7fcda22c9f194272fa9ac84e23'; // Your secret key here

        final transferData = {
          'source': 'balance',
          'amount': (amountToSend * 100).toInt(), // Convert NGN to kobo
          'recipient': creatorRecipientCode,
          'reason': 'Community withdrawal for $communityId',
        };

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $secretKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(transferData),
        );

        final body = jsonDecode(response.body);

        if (response.statusCode == 200 && body['status'] == true) {
          // Transfer initialized successfully
          final transferReference = body['data']['reference'];
          debugPrint('Transfer initialized: $transferReference');
          return right(null);
        } else {
          // Transfer failed, rollback transaction by throwing
          throw Exception(body['message'] ?? 'Transfer failed');
        }
      });
    } catch (e) {
      return left(Failure('Withdrawal failed: $e'));
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
