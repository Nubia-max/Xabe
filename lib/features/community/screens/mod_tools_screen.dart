import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/models/community_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../repository/community_repository.dart';

class ModToolsScreen extends StatelessWidget {
  final Community community;
  final CommunityRepository _communityRepo = CommunityRepository(
    firestore: FirebaseFirestore.instance,
  );

  ModToolsScreen({
    super.key,
    required this.community,
  });

  void navigateToEditCommunity(String communityId) {
    Get.toNamed('/edit-community/${Uri.encodeComponent(communityId)}');
  }

  void navigateToAddMods() {
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
                  // go back to home or communities list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mod Tools')),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.add_moderator),
            title: const Text('Add Moderators'),
            onTap: navigateToAddMods,
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Community'),
            onTap: () => navigateToEditCommunity(community.id),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Community',
                style: TextStyle(color: Colors.red)),
            onTap: () => _confirmAndDelete(context),
          ),
        ],
      ),
    );
  }
}
