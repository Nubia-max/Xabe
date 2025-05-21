import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/theme/pallete.dart';
import '../../../admin/admin build.dart';
import '../../../theme/theme_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../../transactions/payment_screen.dart';
import '../delegates/settings_screen.dart';
import '../../transactions/transaction_history_screen.dart'; // adjust path if needed

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Get.find<AuthController>().logout();
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void logOut() {
    Get.find<AuthController>().logout();
  }

  void navigateToUserProfile(String uid) async {
    await Get.toNamed('/u/$uid');
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final user = authController.userModel.value;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: getImageProvider(user?.profilePic ?? ''),
              radius: 70,
            ),
            const SizedBox(height: 10),
            Text(
              'u/${user?.name ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),

            // --- Account balance under username ---
            if (user != null) ...[
              const SizedBox(height: 5),
              Text(
                'Balance: ₦${user.balance.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(),

            ListTile(
              title: const Text('My Profile'),
              leading: const Icon(Icons.person),
              onTap: () => navigateToUserProfile(user?.uid ?? ''),
            ),

            // --- Add Funds tile ---
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Add Funds'),
              onTap: () async {
                final paymentResult = await Get.to(() => PaymentScreen());
                if (paymentResult == true) {
                  // Refresh the user profile/balance here
                  await Get.find<AuthController>()
                      .reloadUser(); // You need to implement reloadUser() in AuthController
                  Get.snackbar('Success', 'Balance updated!');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Transaction History'),
              onTap: () {
                Get.to(() => const TransactionHistoryScreen());
              },
            ),

            Obx(
              () => ListTile(
                title: const Text('Dark Mode'),
                leading: const Icon(Icons.dark_mode),
                trailing: Switch(
                  activeColor: Pallete.blueColor,
                  value: themeController.isDarkMode,
                  onChanged: (value) => themeController.toggleTheme(),
                ),
              ),
            ),

            ListTile(
              title: const Text('Moderation Queue'),
              leading: const Icon(Icons.report),
              onTap: () => Get.to(() => ModerationQueuePage()),
            ),

            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () => Get.to(() => const SettingsScreen()),
            ),

            ListTile(
              title: const Text('Log Out'),
              leading: Icon(Icons.logout, color: Pallete.redColor),
              onTap: () => confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        return NetworkImage(imageUrl);
      } else {
        return CachedNetworkImageProvider(imageUrl);
      }
    } else {
      return AssetImage(imageUrl);
    }
  }
}
