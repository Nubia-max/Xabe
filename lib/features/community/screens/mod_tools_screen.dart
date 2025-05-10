import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/features/community/repository/community_repository.dart';

class ModToolsScreen extends StatelessWidget {
  final Community community;
  final CommunityRepository _communityRepo = CommunityRepository(
    firestore: FirebaseFirestore.instance,
  );

  ModToolsScreen({
    super.key,
    required this.community,
  });

  void _navigateToEditCommunity() {
    Get.toNamed('/edit-community/${Uri.encodeComponent(community.id)}');
  }

  void _navigateToAddMods() {
    Get.toNamed('/add-mods/${Uri.encodeComponent(community.id)}');
  }

  void _confirmAndDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Community'),
        content: Text(
          'Are you sure you want to delete "${community.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              final result = await _communityRepo.deleteCommunity(community.id);
              result.match(
                (failure) => Get.snackbar(
                  'Error',
                  failure.message,
                  snackPosition: SnackPosition.BOTTOM,
                ),
                (_) {
                  Get.snackbar(
                    'Deleted',
                    'Community "${community.name}" has been deleted.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  Get.offAllNamed('/');
                },
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<String> _fetchUsername(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['name'] ?? uid;
    } catch (_) {
      return uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = Get.find<AuthController>().userModel.value?.uid;
    final isCreator = currentUid != null && currentUid == community.creatorUid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mod Tools')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add_moderator),
              title: const Text('Add Moderators'),
              onTap: _navigateToAddMods,
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Community'),
              onTap: _navigateToEditCommunity,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Banned Users'),
              subtitle: community.bannedUsers.isEmpty
                  ? const Text('No banned users.')
                  : null,
            ),
            ...community.bannedUsers.map((uid) {
              return FutureBuilder<String>(
                future: _fetchUsername(uid),
                builder: (context, snapshot) {
                  final username = snapshot.data ?? uid;
                  return ListTile(
                    leading: const Icon(Icons.person_off),
                    title: Text(username),
                    subtitle: Text('UID: $uid'),
                    trailing: IconButton(
                      icon: const Icon(Icons.undo, color: Colors.green),
                      tooltip: 'Unban User',
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('communities')
                            .doc(community.id)
                            .update({
                          'bannedUsers': FieldValue.arrayRemove([uid]),
                        });

                        Get.snackbar(
                          'User Unbanned',
                          '$username has been unbanned from the community.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  );
                },
              );
            }).toList(),
            if (isCreator) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Community',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmAndDelete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
