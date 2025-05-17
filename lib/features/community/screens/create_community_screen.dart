import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/loader.dart';

import '../../../core/utils/simple_filter.dart';
import '../../../core/utils/utils.dart';
import '../../../theme/theme_controller.dart';
import '../controller/community_controller.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController communityNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  bool requiresVerification = true;

  // New: Community type state
  String _communityType = 'regular';

  @override
  void dispose() {
    communityNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void createCommunity() {
    final name = communityNameController.text.trim();
    if (!SimpleFilter.isClean(name)) {
      showSnackBar(context, 'Community name contains disallowed words.');
      return;
    }
    Get.find<CommunityController>().createCommunity(
      communityNameController.text.trim(),
      bioController.text.trim(),
      requiresVerification,
      context,
      communityType: _communityType, // Pass the new community type here
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    final themeController =
        Get.find<ThemeController>(); // Access theme controller
    final isDarkMode = themeController.isDarkMode;

    return Obx(() {
      final isLoading = communityController.isLoading.value;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Create Community',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor:
              isDarkMode ? Colors.black : Colors.white, // Adjust based on theme
          elevation: 0,
          iconTheme:
              IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        ),
        body: isLoading
            ? const Loader()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    // Community Name Text Field
                    TextField(
                      controller: communityNameController,
                      decoration: InputDecoration(
                        hintText: 'Community Name',
                        filled: true,
                        fillColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black),
                      ),
                      maxLength: 21,
                    ),
                    const SizedBox(height: 20),
                    // Bio Text Field
                    TextField(
                      controller: bioController,
                      decoration: InputDecoration(
                        hintText: 'Bio',
                        filled: true,
                        fillColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black),
                      ),
                      maxLines: 3,
                    ),

                    // New: Community Type Selection
                    const SizedBox(height: 20),
                    const Text(
                      'Community Type',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    RadioListTile<String>(
                      title: const Text('Regular'),
                      value: 'regular',
                      groupValue: _communityType,
                      onChanged: (value) {
                        setState(() {
                          _communityType = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Premium'),
                      value: 'premium',
                      groupValue: _communityType,
                      onChanged: (value) {
                        setState(() {
                          _communityType = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    // Require Verification Switch
                    Row(
                      children: [
                        Text(
                          'Require ID verification for members to join',
                          style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black),
                        ),
                        const Spacer(),
                        Switch(
                          value: requiresVerification,
                          onChanged: (val) {
                            setState(() {
                              requiresVerification = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Create Button
                    ElevatedButton(
                      onPressed: createCommunity,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor:
                            isDarkMode ? Colors.purple : Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Create",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Informational Text
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "You can always edit the community later.",
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
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
