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

  // Subscribe to FCM topics for moderation updates
  Future<void> subscribeToMyTopics(List<String> communityIds) async {
    final fcm = FirebaseMessaging.instance;
    for (final cid in communityIds) {
      final topic = 'moderators-$cid';
      await fcm.subscribeToTopic(topic);
      debugPrint('Subscribed to $topic');
    }
  }

  // Unsubscribe from FCM topics when leaving moderation role
  Future<void> unsubscribeFromAllTopics(List<String> communityIds) async {
    final fcm = FirebaseMessaging.instance;
    for (final cid in communityIds) {
      await fcm.unsubscribeFromTopic('moderators-$cid');
      debugPrint('Unsubscribed from moderators-$cid');
    }
  }

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
              final status = data['status'] as String;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('$contentType • $flagCount flags'),
                  subtitle: Text('ID: $contentId'),
                  onTap: () {
                    debugPrint('Navigating from moderation item');

                    Get.to(
                      () => UserProfileScreen(
                        uid: authorId,
                        jumpToPostId: contentId,
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      final batch = FirebaseFirestore.instance.batch();
                      final contentRef = FirebaseFirestore.instance
                          .collection(contentType)
                          .doc(contentId);

                      if (action == 'Remove') {
                        batch.update(contentRef, {'status': 'removed'});
                      } else if (action == 'Ban User') {
                        batch.update(
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(authorId),
                          {'banned': true},
                        );
                      }

                      // Mark the queue item as reviewed
                      batch.update(doc.reference, {'status': 'reviewed'});
                      await batch.commit();
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
