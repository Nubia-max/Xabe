import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import '../../core/failure.dart';
import '../auth/controller/auth_controller.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _notificationRepository;

  // Reactive list to hold notifications.
  var notifications = <NotificationModel>[].obs;

  // Loading state if needed.
  var isLoading = false.obs;
  var hasNewNotifications = false.obs;

  NotificationController(
      {required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository;

  @override
  void onInit() {
    super.onInit();
    final user = Get.find<AuthController>().userModel.value;
    if (user != null && user.isAuthenticated) {
      loadNotifications(user.uid);
    }
  }

  /// Call this method to start listening to notifications for a given user.
  void loadNotifications(String userId) {
    _notificationRepository.getNotifications(userId).listen((notificationList) {
      notifications.assignAll(notificationList.cast<NotificationModel>());
      hasNewNotifications.value =
          notifications.any((n) => n.isProcessed == false);
    }, onError: (error) {
      print("Error loading notifications: $error");
    });
  }

  /// Mark a notification as processed.
  Future<Either<Failure, void>> markNotificationAsProcessed(
      String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isProcessed': true});
      return right(null);
    } catch (e) {
      return left(Failure('Failed to mark notification as read: $e'));
    }
  }

  /// Send a notification.
  Future<void> sendNotification({
    required String recipientId,
    required String senderId,
    required String message,
    required String type,
    required String communityId,
    String? verificationImageUrl,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = NotificationModel(
      id: id,
      recipientId: recipientId,
      senderId: senderId,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      communityId: communityId,
      isProcessed: false,
      verificationImageUrl: verificationImageUrl,
    );
    final res = await _notificationRepository.createNotification(notification);
    res.fold(
      (failure) => Get.snackbar("Error", failure.message),
      (success) => null,
    );
  }

  /// Call this method when the user opens the notifications screen.
  void markNotificationsAsSeen() async {
    for (var notification in notifications) {
      // Only mark non-join_request notifications as processed
      if (!notification.isProcessed && notification.type != 'join_request') {
        await markNotificationAsProcessed(notification.id);
      }
    }
    // Update hasNewNotifications accordingly. You might want to check for any unprocessed join requests here.
    hasNewNotifications.value =
        notifications.any((n) => !n.isProcessed && n.type == 'join_request');
  }
}
