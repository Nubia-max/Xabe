import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/features/community/controller/community_controller.dart';
import 'package:xabe/models/community_model.dart';

class JoinCommunityVerificationScreen extends StatefulWidget {
  final Community community;
  const JoinCommunityVerificationScreen({super.key, required this.community});

  @override
  _JoinCommunityVerificationScreenState createState() =>
      _JoinCommunityVerificationScreenState();
}

class _JoinCommunityVerificationScreenState
    extends State<JoinCommunityVerificationScreen> {
  Uint8List? verificationImage;
  bool isUploading = false;
  final ImagePicker picker = ImagePicker();

  Future<void> pickVerificationImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        verificationImage = bytes;
      });
    }
  }

  void onJoin() async {
    if (verificationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please attach a verification image.")),
      );
      return;
    }
    setState(() => isUploading = true);

    // Call the controller's method that handles join with verification.
    await Get.find<CommunityController>().joinCommunityWithVerification(
      widget.community,
      context,
      verificationImage!,
    );
    setState(() => isUploading = false);

    // After joining, close the verification screen.
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Eligibility")),
      body: isUploading
          ? const Loader()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Attach an image (e.g., I.D. card or PVC) to verify your eligibility to join this community.",
                  ),
                  const SizedBox(height: 20),
                  verificationImage != null
                      ? Image.memory(verificationImage!, height: 200)
                      : const Placeholder(fallbackHeight: 200),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: pickVerificationImage,
                        child: const Text("Attach Image"),
                      ),
                      ElevatedButton(
                        onPressed: onJoin,
                        child: const Text("Join"),
                      ),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
