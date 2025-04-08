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
            return ListTile(
              title: Text(notification.message),
              subtitle: notification.type == 'new_post'
                  ? Text("New post in association ${notification.communityId}")
                  : notification.type == 'join_accepted'
                      ? Text(
                          "Your request to join ${notification.communityId} association was accepted.")
                      : isJoinRequest
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Community: ${notification.communityId}'),
                                if (notification.verificationImageUrl != null &&
                                    notification
                                        .verificationImageUrl!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        // Navigate to full screen image view.
                                        Get.to(() => FullScreenImageScreen(
                                            imageUrl: notification
                                                .verificationImageUrl!));
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            notification.verificationImageUrl!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : null,
              trailing: isJoinRequest && !notification.isProcessed
                  ? SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await Get.find<CommunityController>()
                                  .acceptJoinRequest(
                                notification.communityId,
                                notification.senderId,
                                context,
                              );
                              await notificationController
                                  .markNotificationAsProcessed(notification.id);
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
                                  .markNotificationAsProcessed(notification.id);
                            },
                          ),
                        ],
                      ),
                    )
                  : null,
            );
          },
        );
      }),
    );
  }
}
