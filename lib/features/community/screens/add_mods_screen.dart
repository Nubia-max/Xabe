// screens/add_mods_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/models/community_model.dart';

import '../../../models/user_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/community_controller.dart';

class AddModsScreen extends StatefulWidget {
  final String communityId;
  const AddModsScreen({super.key, required this.communityId});

  @override
  _AddModsScreenState createState() => _AddModsScreenState();
}

class _AddModsScreenState extends State<AddModsScreen> {
  final communityController = Get.find<CommunityController>();
  final authController = Get.find<AuthController>();

  String? currentUid;
  String? creatorUid;
  Set<String> selectedMods = {};

  @override
  void initState() {
    super.initState();
    // Grab current user UID however you store it:
    currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Seed creator & existing mods once:
    communityController
        .getCommunityById(widget.communityId)
        .first
        .then((community) {
      setState(() {
        creatorUid = community.creatorUid;
        selectedMods = Set.from(community.mods);
      });
    });
  }

  bool get isCreator => currentUid == creatorUid;

  void _onCheckboxChanged(String uid, bool? checked) {
    if (uid == creatorUid) return; // never remove creator
    if (checked == true) {
      selectedMods.add(uid);
    } else {
      selectedMods.remove(uid);
    }
    setState(() {});
  }

  void _saveMods() {
    communityController.addMods(
      widget.communityId,
      selectedMods.toList(),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admin'),
        actions: [
          if (isCreator)
            IconButton(icon: const Icon(Icons.check), onPressed: _saveMods),
        ],
      ),
      body: StreamBuilder<Community>(
        stream: communityController.getCommunityById(widget.communityId),
        builder: (ctx, snap) {
          if (snap.hasError) return ErrorText(error: snap.error.toString());
          if (!snap.hasData) return const Loader();

          final community = snap.data!;
          final members = community.members;

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (ctx2, i) {
              final memberUid = members[i];

              return StreamBuilder<UserModel>(
                stream: authController.getUserData(memberUid),
                builder: (ctx3, userSnap) {
                  if (userSnap.hasError) {
                    return ErrorText(error: userSnap.error.toString());
                  }
                  if (!userSnap.hasData) return const Loader();

                  final user = userSnap.data!;
                  final isOwner = user.uid == creatorUid;
                  final checked = isOwner || selectedMods.contains(user.uid);
                  final enabled = isCreator && !isOwner;

                  return CheckboxListTile(
                    title: Text(user.name ?? 'Unknown'),
                    value: checked,
                    onChanged: enabled
                        ? (val) => _onCheckboxChanged(user.uid, val)
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: isOwner
                        ? const Icon(Icons.star, color: Colors.amber)
                        : null,
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
