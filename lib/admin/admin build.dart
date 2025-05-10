import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../features/community/screens/community_screen.dart';
import '../features/user_profile/screens/user_profile_screen.dart';

class ModerationQueuePage extends StatelessWidget {
  final queueRef = FirebaseFirestore.instance
      .collection('moderationQueue')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔨 Moderation Queue')),
      body: StreamBuilder<QuerySnapshot>(
        stream: queueRef.snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No items to review.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final data = doc.data() as Map<String, dynamic>;

              final contentType = data['contentType'] as String;
              final contentId = data['contentId'] as String;
              final authorId = data['authorId'] as String;
              final communityId = data['communityId'] as String;
              final flagCount = data['flagCount'] as int;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('$contentType • $flagCount flags'),
                  subtitle: Text('ID: $contentId'),
                  onTap: () {
                    debugPrint('Navigating from moderation item');

                    Get.to(() => UserProfileScreen(
                          uid: authorId,
                          jumpToPostId: contentId,
                        ));
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      final firestore = FirebaseFirestore.instance;
                      final moderationRef = doc.reference;

                      try {
                        if (action == 'Remove') {
                          await firestore
                              .collection(contentType)
                              .doc(contentId)
                              .delete();
                          await moderationRef.update({'status': 'reviewed'});
                          Get.snackbar(
                              'Post Removed', 'The content has been deleted.');
                        } else if (action == 'Ban User') {
                          // ✅ Updated to perform community-level ban
                          await firestore
                              .collection('communities')
                              .doc(communityId)
                              .update({
                            'bannedUsers': FieldValue.arrayUnion([authorId]),
                          });
                          await moderationRef.update({'status': 'reviewed'});
                          Get.snackbar('User Banned',
                              'User is banned from posting in this community.');
                        } else if (action == 'Reviewed') {
                          await moderationRef.update({'status': 'reviewed'});
                          Get.snackbar('Reviewed', 'Marked as reviewed.');
                        }
                      } catch (e) {
                        Get.snackbar('Error', 'Operation failed: $e');
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'Remove', child: Text('Remove Content')),
                      PopupMenuItem(value: 'Ban User', child: Text('Ban User')),
                      PopupMenuItem(
                          value: 'Reviewed', child: Text('Mark Reviewed')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
