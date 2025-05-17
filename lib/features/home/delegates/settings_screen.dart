import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/theme/pallete.dart';
import '../../auth/controller/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Function to confirm and delete the account
  void _confirmAndDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action is irreversible and will remove all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.redColor,
            ),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              final authController = Get.find<AuthController>();
              try {
                await authController.deleteAccount();
                Get.snackbar(
                  'Account Deleted',
                  'Your account has been successfully deleted.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                // Navigate to login/onboarding
                Get.offAllNamed('/login');
              } catch (e) {
                Get.snackbar(
                  'Error',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Function to navigate to the Blocked Users tab
  void navigateToBlockedUsers(BuildContext context) async {
    Get.toNamed('/blocked-users');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete Account'),
              textColor: Pallete.redColor,
              iconColor: Pallete.redColor,
              onTap: () => _confirmAndDelete(context),
            ),
            const SizedBox(height: 10),
            // Blocked Users Tab
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Blocked Users'),
              onTap: () => navigateToBlockedUsers(context),
            ),
          ],
        ),
      ),
    );
  }
}
