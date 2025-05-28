import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xabe/core/common/loader.dart';

import '../../../core/utils/simple_filter.dart';
import '../../../core/utils/utils.dart';
import '../../../theme/theme_controller.dart';
import '../../auth/controller/auth_controller.dart';
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

  String _communityType = 'regular';

  bool _purchasePending = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  /// Starts premium payment via HTTP POST to your cloud function.
  Future<bool> startPremiumPaymentHttp({
    required String userId,
    required String email,
    required String communityName,
    required String bio,
    required bool requiresVerification,
  }) async {
    const cloudFunctionUrl =
        'https://us-central1-xabe-ai.cloudfunctions.net/createPremiumPayment';

    final payload = {
      'userId': userId,
      'email': email,
      'communityName': communityName,
      'bio': bio,
      'requiresVerification': requiresVerification,
    };

    print('Calling createPremiumPayment with payload: $payload');

    try {
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['paymentUrl'] != null) {
        final url = data['paymentUrl'];
        if (await canLaunch(url)) {
          await launch(url);

          // Show dialog to user after opening Paystack page
          final bool? result = await showDialog<bool>(
            context: Get.context!, // Use Get.context or pass context explicitly
            builder: (context) => AlertDialog(
              title: const Text('Payment'),
              content: const Text(
                  'Complete your payment in the browser. Click Done when finished.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Done'),
                ),
              ],
            ),
          );

          if (result == true) {
            // Navigate to home screen after payment is done
            Get.offAllNamed('/home'); // Change to your home route if different
          }
          return true;
        } else {
          throw 'Could not launch payment URL';
        }
      } else {
        print('Server error: ${data['error']}');
        return false;
      }
    } catch (e) {
      print('HTTP payment error: $e');
      return false;
    }
  }

  void createCommunity() async {
    final name = communityNameController.text.trim();

    if (!SimpleFilter.isClean(name)) {
      showSnackBar(context, 'Community name contains disallowed words.');
      return;
    }

    final communityController = Get.find<CommunityController>();

    setState(() {
      _purchasePending = true; // Show loading spinner
    });

    // Check if community name exists (works for both regular and premium)
    final existingCommunities = await communityController.communityRepository
        .searchCommunity(name)
        .first;

    final nameExists = existingCommunities.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );

    if (nameExists) {
      setState(() {
        _purchasePending = false;
      });
      Get.snackbar(
        'Error',
        'Community with this name already exists. Please choose another name.',
      );
      return;
    }

    // Proceed with creation depending on community type
    if (_communityType == 'regular') {
      // Regular community creation (no payment)
      await communityController.createCommunity(
        name,
        bioController.text.trim(),
        requiresVerification,
        context,
        communityType: 'regular',
      );
      setState(() {
        _purchasePending = false;
      });
    } else if (_communityType == 'premium') {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _purchasePending = false;
        });
        Get.snackbar(
            'Error', 'You must be logged in to create a premium community.');
        return;
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        setState(() {
          _purchasePending = false;
        });
        Get.snackbar('Error', 'Your email is missing or invalid.');
        return;
      }

      // Start payment
      final success = await startPremiumPaymentHttp(
        userId: user.uid,
        email: email,
        communityName: name,
        bio: bioController.text.trim(),
        requiresVerification: requiresVerification,
      );

      setState(() {
        _purchasePending = false;
      });

      if (success) {
        Get.snackbar(
          'Payment',
          'Please complete the payment in your browser. After successful payment, your premium community will be created automatically.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar('Error', 'Failed to initiate payment.');
      }
    }
  }

  @override
  void dispose() {
    communityNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Community',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: _loading
          ? const Loader()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
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
                  const SizedBox(height: 20),
                  const Text(
                    'Community Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  ElevatedButton(
                    onPressed: _purchasePending ? null : createCommunity,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _purchasePending
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "Create",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 20),
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
  }
}
