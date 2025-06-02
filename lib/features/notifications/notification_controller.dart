import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart';
import '../../core/failure.dart';
import '../auth/controller/auth_controller.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

// Import your custom push notification handlers
import 'push_notifications/user_joined_push.dart';
import 'push_notifications/join_accepted_push.dart';
import 'push_notifications/election_started_push.dart';
import 'push_notifications/new_post_push.dart';
import 'push_notifications/election_ended_push.dart';
import 'push_notifications/added_as_moderator_push.dart';

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

        for (final n in newUnprocessed) {
          _handlePush(n);
          _shownNotificationIds
              .add(n.id); // still helpful to avoid multiple triggers
        }

        hasNewNotifications.value = notifications.any((n) => !n.isProcessed);
      },
      onError: (err) {
        print("Error loading notifications: $err");
      },
    );
  }

  void _handlePush(NotificationModel noti) {
    final name = noti.communityName;
    switch (noti.type) {
      case 'join_request':
        sendUserJoinedPush(noti.senderName, name);
        break;
      case 'join_accepted':
        sendJoinAcceptedPush(name);
        break;
      case 'election_start':
        sendElectionStartedPush(name);
        break;
      case 'new_post':
        sendNewPostPush(name);
        break;
      case 'election_end':
        sendElectionEndedPush(name);
        break;
      case 'new_mod':
        sendAddedAsModeratorPush(name);
        break;
      default:
        print('Unhandled notification type: ${noti.type}');
    }
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
}
