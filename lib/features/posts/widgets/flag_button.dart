import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FlagButton extends StatelessWidget {
  final String contentId;
  final String contentType;
  final String authorId;

  const FlagButton({
    Key? key,
    required this.contentId,
    required this.contentType,
    required this.authorId,
  }) : super(key: key);

  Future<void> _report(String reason) async {
    final reporterId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('reports').add({
      'contentId': contentId,
      'contentType': contentType,
      'authorId': authorId,
      'reason': reason,
      'reporterId': reporterId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    Get.snackbar(
      'Report submitted',
      'Thanks, we’ll review this shortly.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
      onSelected: _report,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'Spam', child: Text('Spam')),
        PopupMenuItem(value: 'Harassment', child: Text('Harassment')),
        PopupMenuItem(value: 'Hate', child: Text('Hate Speech')),
        PopupMenuItem(value: 'Other', child: Text('Other')),
      ],
    );
  }
}
