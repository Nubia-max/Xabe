import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import '../../core/failure.dart';
import '../auth/controller/auth_controller.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

// Import your custom push notification handlers

class NotificationController extends GetxController {
  final NotificationRepository _notificationRepository;

  final Set<String> _shownNotificationIds = {};
  var notifications = <NotificationModel>[].obs;
  var isLoading = false.obs;
  var hasNewNotifications = false.obs;
  bool _initialLoad = true;

  NotificationController({
    required NotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository;

  @override
  void onInit() {
    super.onInit();
    final user = Get.find<AuthController>().userModel.value;
    if (user != null && user.isAuthenticated) {
      loadNotifications(user.uid);
    }
  }

  void loadNotifications(String userId) {
    _initialLoad = true;

    _notificationRepository.getNotifications(userId).listen(
      (List<NotificationModel> fresh) {
        if (_initialLoad) {
          notifications.assignAll(fresh);
          for (var n in fresh) {
            _shownNotificationIds.add(n.id);
          }
          hasNewNotifications.value = notifications.any((n) => !n.isProcessed);
          _initialLoad = false;
          return;
        }

        final newUnprocessed = fresh.where((n) => !n.isProcessed).toList();

        notifications.assignAll(fresh);

        hasNewNotifications.value = notifications.any((n) => !n.isProcessed);
      },
      onError: (err) {
        print("Error loading notifications: $err");
      },
    );
  }

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

  Future<void> sendNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String message,
    required String type,
    required String communityId,
    required String communityName,
    String? verificationImageUrl,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = NotificationModel(
      id: id,
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      communityId: communityId,
      communityName: communityName,
      isProcessed: false,
      verificationImageUrl: verificationImageUrl,
    );
    final res = await _notificationRepository.createNotification(notification);
    res.fold(
      (failure) => Get.snackbar("Error", failure.message),
      (_) => null,
    );
  }

  void markNotificationsAsSeen() async {
    for (var notification in notifications) {
      if (!notification.isProcessed && notification.type != 'join_request') {
        await markNotificationAsProcessed(notification.id);
      }
    }
    hasNewNotifications.value =
        notifications.any((n) => !n.isProcessed && n.type == 'join_request');
  }

  Future<String?> getFcmToken(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data()?['fcmToken'] as String?;
  }

  Future<String?> getFcmTokenForUser(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      return data?['fcmToken'] as String?;
    } catch (e) {
      print('Error fetching FCM token for user $uid: $e');
      return null;
    }
  }
}
