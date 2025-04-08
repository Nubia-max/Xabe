// screens/add_mods_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/models/community_model.dart';

import '../../auth/controller/auth_controller.dart';
import '../controller/community_controller.dart';

class AddModsScreen extends StatefulWidget {
  final String name;
  const AddModsScreen({super.key, required this.name});

  @override
  _AddModsScreenState createState() => _AddModsScreenState();
}

class _AddModsScreenState extends State<AddModsScreen> {
  Set<String> uids = {};
  int ctr = 0;

  void addUid(String uid) {
    setState(() {
      uids.add(uid);
    });
  }

  void removeUid(String uid) {
    setState(() {
      uids.remove(uid);
    });
  }

  void saveMods() {
    Get.find<CommunityController>()
        .addMods(widget.name, uids.toList(), context);
  }

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: saveMods,
            icon: const Icon(Icons.done),
          ),
        ],
      ),
      body: StreamBuilder<Community>(
        stream: communityController.getCommunityByName(widget.name),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          }
          if (!snapshot.hasData) return const Loader();

          final community = snapshot.data!;

          // Safely handle possible nulls for lists
          final members = community.members ?? [];
          final mods = community.mods ?? [];

          ctr = 0; // Reset counter on each build

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return StreamBuilder(
                stream: Get.find<AuthController>().getUserData(member),
                builder: (context, AsyncSnapshot userSnapshot) {
                  if (userSnapshot.hasError) {
                    return ErrorText(error: userSnapshot.error.toString());
                  }
                  if (!userSnapshot.hasData) return const Loader();

                  final user = userSnapshot.data;
                  // Check if user or expected properties are null
                  if (user == null || user.uid == null || user.name == null) {
                    return const Loader();
                  }

                  // Example: Only add the member once if they're a mod.
                  if (mods.contains(member) && ctr == 0) {
                    uids.add(member);
                  }
                  ctr++;

                  return CheckboxListTile(
                    value: uids.contains(user.uid),
                    onChanged: (val) {
                      if (val == true) {
                        addUid(user.uid);
                      } else {
                        removeUid(user.uid);
                      }
                    },
                    title: Text(user.name),
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
