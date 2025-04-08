import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/core/constants/constants.dart';
import 'package:xabe/core/utils.dart';
import 'package:xabe/models/community_model.dart';

import '../controller/community_controller.dart';

class EditCommunityScreen extends StatefulWidget {
  final String name;
  const EditCommunityScreen({super.key, required this.name});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  File? bannerFile;
  Uint8List? bannerBytes;
  File? profileFile;
  Uint8List? profileBytes;
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController();
  }

  @override
  void dispose() {
    bioController.dispose();
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
    Get.find<CommunityController>().editCommunity(
      profileFile: profileFile,
      bannerFile: bannerFile,
      context: context,
      community: community,
      bio: bioController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    // Use your theme controller if available; otherwise, fallback to Theme.of(context).
    final currentTheme = Theme.of(context);
    return StreamBuilder<Community>(
      stream: communityController.getCommunityByName(widget.name),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorText(error: snapshot.error.toString());
        }
        if (!snapshot.hasData) return const Loader();
        final community = snapshot.data!;
        if (bioController.text.isEmpty) {
          bioController.text = community.bio;
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Community'),
            centerTitle: false,
            actions: [
              TextButton(
                onPressed: () => save(community),
                child: const Text('Save'),
              ),
            ],
          ),
          body: Obx(() {
            final isLoading = communityController.isLoading.value;
            return isLoading
                ? const Loader()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add label for banner
                        const Text(
                          'edit banner',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: selectBannerImage,
                                child: DottedBorder(
                                  borderType: BorderType.RRect,
                                  radius: const Radius.circular(10),
                                  dashPattern: const [10, 4],
                                  strokeCap: StrokeCap.round,
                                  child: Container(
                                    width: double.infinity,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: bannerFile != null
                                        ? Image.file(bannerFile!)
                                        : (community.banner.isEmpty ||
                                                community.banner ==
                                                    Constants.bannerDefault)
                                            ? const Center(
                                                child: Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: 40,
                                                ),
                                              )
                                            : Image.network(community.banner),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 20,
                                child: GestureDetector(
                                  onTap: selectProfileImage,
                                  child: profileFile != null
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
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Add label for bio
                        const Text(
                          'bio',
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
                            hintText: 'Association Bio',
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(18),
                          ),
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
