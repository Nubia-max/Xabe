import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/core/common/error_text.dart';

import '../../auth/controller/auth_controller.dart';
import '../../auth/repository/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  // Function to unblock a user
  Future<void> _unblockUser(String targetUserId, BuildContext context) async {
    // Show confirmation dialog before unblocking
    final shouldUnblock = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unblock User'),
          content: const Text('Are you sure you want to unblock this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unblock', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldUnblock == true) {
      try {
        await Get.find<AuthRepository>().unblockUser(targetUserId);
        Get.snackbar('Unblocked', 'User has been unblocked successfully.');
      } catch (e) {
        Get.snackbar('Error', 'An error occurred while unblocking the user.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Get.find<AuthController>().userModel.value!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: StreamBuilder<List<String>>(
        stream: Get.find<AuthRepository>().getBlockedUsers(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Loader(); // Show loading while fetching data
          }

          final blockedUsers = snapshot.data!;

          if (blockedUsers.isEmpty) {
            return const Center(child: Text('You have not blocked any users.'));
          }

          // Stream to fetch the names of the blocked users from Firestore
          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final blockedUserId = blockedUsers[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(blockedUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return const Center(
                        child: Text('Error fetching user data.'));
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const Center(
                        child: Text('User data not available.'));
                  }

                  final user = userSnapshot.data!;
                  final userName = user['name'] ?? 'No name available';

                  return ListTile(
                    title: Text(userName),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        await _unblockUser(
                            blockedUserId, context); // Unblock the user
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
