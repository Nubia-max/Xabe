import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModToolsScreen extends StatelessWidget {
  final String name;
  const ModToolsScreen({
    super.key,
    required this.name,
  });

  void navigateToEditCommunity() {
    Get.toNamed('/edit-community/${Uri.encodeComponent(name)}');
  }

  void navigateToAddMods() {
    Get.toNamed('/add-mods/${Uri.encodeComponent(name)}');
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
            onTap: navigateToEditCommunity,
          ),
        ],
      ),
    );
  }
}
