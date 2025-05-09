import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ModerationQueuePage extends StatelessWidget {
  final queueRef = FirebaseFirestore.instance
      .collection('moderationQueue')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true);
  // After you fetch the list of communities this user moderates:
  Future<void> subscribeToMyTopics(List<String> communityIds) async {
    final fcm = FirebaseMessaging.instance;
    for (final cid in communityIds) {
      final topic = 'moderators-$cid';
      await fcm.subscribeToTopic(topic);
      debugPrint('Subscribed to $topic');
    }
  }

// And if they leave moderation role, you can optionally unsubscribe:
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
      appBar: AppBar(title: Text('🔨 Moderation Queue')),
      body: StreamBuilder<QuerySnapshot>(
        stream: queueRef.snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) {
            return Center(child: Text('No items to review.'));
          }
          return ListView(
            children: snap.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                      '${data['contentType']} • ${data['flagCount']} flags'),
                  subtitle: Text('ID: ${data['contentId']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      final batch = FirebaseFirestore.instance.batch();
                      final contentRef = FirebaseFirestore.instance
                          .collection(data['contentType'])
                          .doc(data['contentId']);

                      if (action == 'Remove') {
                        batch.update(contentRef, {'status': 'removed'});
                      }
                      if (action == 'Ban User') {
                        batch.update(
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(data['authorId']),
                          {'banned': true},
                        );
                      }
                      // Mark as reviewed
                      batch.update(doc.reference, {'status': 'reviewed'});
                      await batch.commit();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'Remove', child: Text('Remove Content')),
                      PopupMenuItem(value: 'Ban User', child: Text('Ban User')),
                      PopupMenuItem(
                          value: 'Reviewed', child: Text('Mark Reviewed')),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
