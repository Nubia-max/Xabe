// lib/widgets/block_button.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlockButton extends StatelessWidget {
  final String targetUserId;

  const BlockButton({Key? key, required this.targetUserId}) : super(key: key);

  /// Actually block the user and show feedback
  Future<void> _block() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('blocked')
        .doc(targetUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});

    Get.snackbar(
      'User Blocked',
      'They will no longer see your content.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show a confirmation dialog before blocking
  void _showConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Block User"),
        content: const Text("Are you sure you want to block this user?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(), // close dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // close dialog
              _block();
            },
            child: const Text("Block", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.block, color: Colors.grey),
      tooltip: 'Block user',
      onPressed: _showConfirmationDialog,
    );
  }
}
