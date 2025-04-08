import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/loader.dart';

import '../controller/community_controller.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController communityNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  @override
  void dispose() {
    communityNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void createCommunity() {
    Get.find<CommunityController>().createCommunity(
      communityNameController.text.trim(),
      bioController.text.trim(),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    return Obx(() {
      final isLoading = communityController.isLoading.value;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Association'),
        ),
        body: isLoading
            ? const Loader()
            : Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: communityNameController,
                      decoration: const InputDecoration(
                        hintText: 'Association Name',
                        filled: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(18),
                      ),
                      maxLength: 21,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        hintText: 'Bio',
                        filled: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(18),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: createCommunity,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Create",
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}
