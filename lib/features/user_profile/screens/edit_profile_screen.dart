// edit_profile_screen.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/constants/constants.dart';
import 'package:xabe/core/utils.dart';

import '../controller/user_profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  final String uid;
  const EditProfileScreen({super.key, required this.uid});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? bannerFile;
  Uint8List? bannerBytes;
  File? profileFile;
  Uint8List? profileBytes;
  late TextEditingController nameController;
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    // Retrieve initial user data from the UserProfileController stream.
    // (Assuming getUserData(uid) returns a Stream<UserModel>.)
    final userProfileController = Get.find<UserProfileController>();
    userProfileController.getUserData(widget.uid).first.then((user) {
      nameController = TextEditingController(text: user.name);
      bioController = TextEditingController(text: user.bio);
      setState(() {}); // Trigger rebuild once controllers are set.
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void selectBannerImage() async {
    final res = await pickImage();
    if (res != null) {
      if (kIsWeb) {
        if (!mounted) return;
        setState(() {
          bannerBytes = res.files.first.bytes;
        });
      } else {
        if (!mounted) return;
        setState(() {
          bannerFile = File(res.files.first.path!);
        });
      }
    }
  }

  void selectProfileImage() async {
    final res = await pickImage();
    if (res != null) {
      if (!mounted) return;
      setState(() {
        profileFile = File(res.files.first.path!);
      });
    }
  }

  void save() {
    // Call the edit method from your UserProfileController.
    Get.find<UserProfileController>().editCommunity(
      profileFile: profileFile,
      bannerFile: bannerFile,
      context: context,
      name: nameController.text.trim(),
      bio: bioController.text.trim(),
    );
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        // On web, use NetworkImage
        return NetworkImage(imageUrl);
      } else {
        // For mobile builds, use CachedNetworkImageProvider.
        return CachedNetworkImageProvider(imageUrl);
      }
    } else {
      return AssetImage(imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Get.theme;
    final userProfileController = Get.find<UserProfileController>();
    return StreamBuilder(
      stream: userProfileController.getUserData(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        return Scaffold(
          backgroundColor: currentTheme.dialogBackgroundColor,
          appBar: AppBar(
            title: const Text('Edit Profile'),
            centerTitle: false,
            actions: [
              TextButton(
                onPressed: save,
                child: const Text('Save'),
              ),
            ],
          ),
          body: userProfileController.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
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
                                      : user.banner.isEmpty ||
                                              user.banner ==
                                                  Constants.bannerDefault
                                          ? const Center(
                                              child: Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: 40))
                                          : Image.network(user.banner),
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
                                        backgroundImage:
                                            getImageProvider(user.profilePic),
                                        radius: 32,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          filled: true,
                          hintText: 'Name',
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: bioController,
                        decoration: InputDecoration(
                          filled: true,
                          hintText: 'Bio',
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
                ),
        );
      },
    );
  }
}
