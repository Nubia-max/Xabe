import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/core/utils/utils.dart';
import 'package:xabe/models/community_model.dart';

import '../../../core/utils/simple_filter.dart';
import '../controller/community_controller.dart';

class EditCommunityScreen extends StatefulWidget {
  final String communityId;
  const EditCommunityScreen({super.key, required this.communityId});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  File? bannerFile;
  Uint8List? bannerBytes;
  File? profileFile;
  Uint8List? profileBytes;
  bool? requiresVerification;

  late TextEditingController bioController;
  late TextEditingController communityNameController;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController();
    communityNameController = TextEditingController();
  }

  @override
  void dispose() {
    bioController.dispose();
    communityNameController.dispose();
    super.dispose();
  }

  Future<void> selectBannerImage() async {
    final res = await pickImage();
    if (res != null) {
      if (kIsWeb) {
        if (!mounted) return;
        setState(() {
          bannerBytes = res.files.first.bytes;
          bannerFile = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          bannerFile = File(res.files.first.path!);
        });
      }
    }
  }

  Future<void> selectProfileImage() async {
    final res = await pickImage();
    if (res != null) {
      if (!mounted) return;
      setState(() {
        profileFile = File(res.files.first.path!);
      });
    }
  }

  void save(Community community) {
    final newName = communityNameController.text.trim();
    if (!SimpleFilter.isClean(newName)) {
      showSnackBar(context, 'Community name contains disallowed words.');
      return;
    }
    // Update the community model with the new name before saving.
    final updatedCommunity = community.copyWith(
      name: communityNameController.text.trim(),
      requiresVerification: requiresVerification,
    );
    Get.find<CommunityController>().editCommunity(
      profileFile: profileFile,
      bannerFile: bannerFile,
      context: context,
      community: updatedCommunity,
      bio: bioController.text.trim(),
      requiresVerification: requiresVerification!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    // Use your theme controller if available; otherwise, fallback to Theme.of(context).
    final currentTheme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Community>(
      stream: communityController.getCommunityById(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorText(error: snapshot.error.toString());
        }
        if (!snapshot.hasData) return const Loader();
        final community = snapshot.data!;

        // Initialize controllers on first load if not already set.
        if (bioController.text.isEmpty) {
          bioController.text = community.bio;
        }
        if (communityNameController.text.isEmpty) {
          communityNameController.text = community.name;
        }
        requiresVerification ??= community.requiresVerification;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Edit Community',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            iconTheme:
                IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
            actions: [
              TextButton(
                onPressed: () => save(community),
                child:
                    const Text('Save', style: TextStyle(color: Colors.purple)),
              ),
            ],
          ),
          body: Obx(() {
            final isLoading = communityController.isLoading.value;
            return isLoading
                ? const Loader()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        // Banner/Profile section.
                        SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 20,
                                left: 20,
                                child: GestureDetector(
                                  onTap: selectProfileImage,
                                  child: Stack(
                                    children: [
                                      profileFile != null
                                          ? CircleAvatar(
                                              backgroundImage:
                                                  FileImage(profileFile!),
                                              radius: 32,
                                            )
                                          : CircleAvatar(
                                              backgroundImage: getImageProvider(
                                                  community.avatar),
                                              radius: 32,
                                            ),
                                      // Overlay the camera icon.
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Add field to edit the community name.
                        const Text(
                          'Community Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: communityNameController,
                          decoration: InputDecoration(
                            filled: true,
                            hintText: 'Enter Community Name',
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color:
                                      isDarkMode ? Colors.white : Colors.blue),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(18),
                            hintStyle: TextStyle(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.black),
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Bio field.
                        const Text(
                          'Bio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: bioController,
                          decoration: InputDecoration(
                            filled: true,
                            hintText: 'Community Bio',
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color:
                                      isDarkMode ? Colors.white : Colors.blue),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(18),
                            hintStyle: TextStyle(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.black),
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          value: requiresVerification!,
                          onChanged: (val) =>
                              setState(() => requiresVerification = val),
                          title: Text(
                              'Require ID verification for members to join',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                      ],
                    ),
                  );
          }),
        );
      },
    );
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        return NetworkImage(imageUrl);
      }
      return CachedNetworkImageProvider(imageUrl);
    } else {
      return AssetImage(imageUrl);
    }
  }
}
