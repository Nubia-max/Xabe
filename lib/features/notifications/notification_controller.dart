import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import '../../core/failure.dart';
import '../auth/controller/auth_controller.dart';
import 'noti_service.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _notificationRepository;
  final NotiService _notiService;

  // track which IDs we've already shown
  final Set<String> _shownNotificationIds = {};

  var notifications = <NotificationModel>[].obs;
  var isLoading = false.obs;
  var hasNewNotifications = false.obs;

  // ← NEW: guard so we ignore the very first batch
  bool _initialLoad = true;

  NotificationController({
    required NotificationRepository notificationRepository,
    required NotiService notiService,
  })  : _notificationRepository = notificationRepository,
        _notiService = notiService;

  @override
  void onInit() {
    super.onInit();
    _notiService.initNotification();
    final user = Get.find<AuthController>().userModel.value;
    if (user != null && user.isAuthenticated) {
      loadNotifications(user.uid);
    }
  }

  void loadNotifications(String userId) {
    // reset the flag any time you re-subscribe
    _initialLoad = true;

    _notificationRepository.getNotifications(userId).listen(
        (List<NotificationModel> fresh) {
      // 1) On the very first arrival, just seed our lists & IDs
      if (_initialLoad) {
        notifications.assignAll(fresh);
        for (var n in fresh) {
          _shownNotificationIds.add(n.id);
        }
        hasNewNotifications.value = notifications.any((n) => !n.isProcessed);
        _initialLoad = false;
        return; // <--- skip showing system notifications here
      }

      // 2) Subsequent changes: diff out only brand-new IDs
      final newOnes =
          fresh.where((n) => !_shownNotificationIds.contains(n.id)).toList();

      // update the displayed list
      notifications.assignAll(fresh);

      // show only those new ones
      for (final n in newOnes) {
        _shownNotificationIds.add(n.id);
        _notiService.showNotification(
          id: n.id.hashCode & 0x7FFFFFFF,
          title: n.senderName,
          body: n.message,
        );
      }

      // update your “unprocessed” badge
      hasNewNotifications.value = notifications.any((n) => !n.isProcessed);
    }, onError: (err) {
      print("Error loading notifications: $err");
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
