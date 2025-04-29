import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/models/community_model.dart'; // Make sure this import is present

class ModToolsScreen extends StatelessWidget {
  final Community community;

  const ModToolsScreen({
    super.key,
    required this.community,
  });

  void navigateToEditCommunity(String communityId) {
    Get.toNamed('/edit-community/${Uri.encodeComponent(communityId)}');
  }

  void navigateToAddMods() {
    Get.toNamed('/add-mods/${Uri.encodeComponent(community.id)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mod Tools'),
      ),
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
        ],
      ),
    );
  }
}
