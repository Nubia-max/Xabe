// lib/widgets/flag_button.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FlagButton extends StatelessWidget {
  final String contentId;
  final String contentType;
  final String authorId;
  final String communityId;

  const FlagButton({
    Key? key,
    required this.contentId,
    required this.contentType,
    required this.authorId,
    required this.communityId,
  }) : super(key: key);

  Future<void> _report(String reason) async {
    final postRef =
        FirebaseFirestore.instance.collection(contentType).doc(contentId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(postRef);
      final current = (snap.data()?['flagCount'] ?? 0) as int;
      final updated = current + 1;

      // 1) bump the flagCount
      tx.update(postRef, {'flagCount': updated});

      // 2) enqueue for moderation when threshold reached
      if (updated >= 3) {
        final queueRef = FirebaseFirestore.instance
            .collection('moderationQueue')
            .doc(contentId);
        tx.set(
          queueRef,
          {
            'contentId': contentId,
            'communityId': communityId,
            'contentType': contentType, // ← add this
            'authorId': authorId, // ← and add this
            'flagCount': updated,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          },
          SetOptions(merge: true),
        );
      }
    });

    Get.snackbar(
      'Reported',
      'Thank you! We will review this shortly.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
      onSelected: (reason) => _report(reason),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'Spam', child: Text('Spam')),
        PopupMenuItem(value: 'Harassment', child: Text('Harassment')),
        PopupMenuItem(value: 'Hate', child: Text('Hate Speech')),
        PopupMenuItem(value: 'Other', child: Text('Other')),
      ],
    );
  }
}
