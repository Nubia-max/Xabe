import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/features/notifications/notification_controller.dart';
import 'package:xabe/features/community/controller/community_controller.dart';
import 'package:xabe/features/notifications/full_screen_image_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController notificationController =
      Get.find<NotificationController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final String userId = authController.userModel.value?.uid ?? "";
    notificationController.loadNotifications(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Obx(() {
        if (notificationController.notifications.isEmpty) {
          return const Center(child: Text('No notifications'));
        }
        return ListView.builder(
          itemCount: notificationController.notifications.length,
          itemBuilder: (context, index) {
            final notification = notificationController.notifications[index];
            final isJoinRequest = notification.type == 'join_request';
            return GestureDetector(
              onTap: notification.verificationImageUrl != null &&
                      notification.verificationImageUrl!.isNotEmpty
                  ? () {
                      Get.to(() => FullScreenImageScreen(
                          imageUrl: notification.verificationImageUrl!));
                    }
                  : null,
              child: ListTile(
                title: Text(notification.message),
                subtitle: isJoinRequest
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                                'Join request from ${notification.senderName}'),
                          ),
                          if (notification.verificationImageUrl != null &&
                              notification.verificationImageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: notification.verificationImageUrl!,
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(
                                        strokeWidth: 1.5),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, size: 16),
                              ),
                            ),
                        ],
                      )
                    : notification.type == 'new_post'
                        ? Text(
                            "New post in association ${notification.communityName}")
                        : notification.type == 'join_accepted'
                            ? Text(
                                "Your request to join ${notification.communityName} association was accepted.")
                            : null,
                trailing: isJoinRequest && !notification.isProcessed
                    ? SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await Get.find<CommunityController>()
                                    .acceptJoinRequest(
                                  notification.communityId,
                                  notification.senderId,
                                  context,
                                );
                                await notificationController
                                    .markNotificationAsProcessed(
                                        notification.id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () async {
                                await Get.find<CommunityController>()
                                    .declineJoinRequest(
                                  notification.communityId,
                                  notification.senderId,
                                  context,
                                );
                                await notificationController
                                    .markNotificationAsProcessed(
                                        notification.id);
                              },
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      }),
    );
  }
}
