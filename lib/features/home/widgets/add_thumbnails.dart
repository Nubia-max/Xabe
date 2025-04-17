import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xabe/models/community_model.dart'; // Ensure your Community model is imported

class AddThumbnailsPage extends StatefulWidget {
  const AddThumbnailsPage({super.key});

  @override
  _AddThumbnailsPageState createState() => _AddThumbnailsPageState();
}

class _AddThumbnailsPageState extends State<AddThumbnailsPage> {
  File? campaignThumbnail;
  File? electionThumbnail;
  Uint8List? campaignThumbnailBytes;
  Uint8List? electionThumbnailBytes;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false; // For showing loader

  Future<void> _pickImage(bool isCampaign) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // On web, use bytes from the picked file.
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isCampaign) {
            campaignThumbnailBytes = bytes;
          } else {
            electionThumbnailBytes = bytes;
          }
        });
      } else {
        // On mobile, use File.
        setState(() {
          if (isCampaign) {
            campaignThumbnail = File(pickedFile.path);
          } else {
            electionThumbnail = File(pickedFile.path);
          }
        });
      }
    }
  }

  // Compress image on mobile
  Future<File?> compressImage(File file) async {
    // If running on web, just return the original file.
    if (kIsWeb) {
      return file;
    }

    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    // Only attempt compression on supported platforms.
    try {
      final xfile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // Adjust quality (0-100)
        minWidth: 800, // Optionally resize width
        minHeight: 600, // Optionally resize height
      );
      if (xfile == null) return null;
      return File(xfile.path);
    } catch (e) {
      // If compression fails (e.g., plugin not implemented), return the original file.
      debugPrint('Compression failed: $e');
      return file;
    }
  }

  // Upload an image to Firebase Storage and return its download URL.
  Future<String> uploadImage(String type, dynamic imageData) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('thumbnails/$type/${DateTime.now().millisecondsSinceEpoch}');
    UploadTask uploadTask;
    if (kIsWeb) {
      uploadTask = storageRef.putData(imageData as Uint8List);
    } else {
      uploadTask = storageRef.putFile(imageData as File);
    }
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveThumbnails() async {
    setState(() {
      _isLoading = true;
    });
    final communityName = Get.parameters['community'] ?? 'Community';
    String? campaignUrl;
    String? electionUrl;

    // Upload campaign thumbnail if available.
    if ((kIsWeb && campaignThumbnailBytes != null) ||
        (!kIsWeb && campaignThumbnail != null)) {
      dynamic data;
      if (!kIsWeb) {
        // Compress image on mobile.
        File? compressed = await compressImage(campaignThumbnail!);
        data = compressed ?? campaignThumbnail;
      } else {
        data = campaignThumbnailBytes;
      }
      campaignUrl = await uploadImage('campaign', data);
    }

    // Upload election thumbnail if available.
    if ((kIsWeb && electionThumbnailBytes != null) ||
        (!kIsWeb && electionThumbnail != null)) {
      dynamic data;
      if (!kIsWeb) {
        // Compress image on mobile.
        File? compressed = await compressImage(electionThumbnail!);
        data = compressed ?? electionThumbnail;
      } else {
        data = electionThumbnailBytes;
      }
      electionUrl = await uploadImage('election', data);
    }

    // Update community record in Firestore.
    await FirebaseFirestore.instance
        .collection('communities')
        .doc(communityName)
        .update({
      if (campaignUrl != null) 'campaignThumbnailUrl': campaignUrl,
      if (electionUrl != null) 'electionThumbnailUrl': electionUrl,
    });

    // Fetch updated community object.
    final doc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(communityName)
        .get();
    final updatedCommunity = Community.fromMap(doc.data()!);

    setState(() {
      _isLoading = false;
    });
    // Return the updated community so the UI can refresh.
    Get.back(result: updatedCommunity);
  }

  @override
  Widget build(BuildContext context) {
    final communityName = Get.parameters['community'] ?? 'Community';

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Thumbnails'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campaign Card Thumbnail field.
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Campaign Card Thumbnail',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        if (kIsWeb && campaignThumbnailBytes != null)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: MemoryImage(campaignThumbnailBytes!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )
                        else if (!kIsWeb && campaignThumbnail != null)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(campaignThumbnail!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )
                        else
                          const Icon(Icons.image, size: 30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Election Card Thumbnail field.
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Election Card Thumbnail',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        if (kIsWeb && electionThumbnailBytes != null)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: MemoryImage(electionThumbnailBytes!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )
                        else if (!kIsWeb && electionThumbnail != null)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(electionThumbnail!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )
                        else
                          const Icon(Icons.image, size: 30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveThumbnails,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
