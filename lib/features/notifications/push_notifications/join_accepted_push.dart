import '../push_notification_service.dart';

void sendJoinAcceptedPush(String communityName) {
  PushNotificationService.sendNotification(
    title: 'Welcome to $communityName!',
    body: 'Your request to join has been accepted 🎉',
  );
}
