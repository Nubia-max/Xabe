import '../push_notification_service.dart';

void sendNewPostPush(String communityName) {
  PushNotificationService.sendNotification(
    title: 'New post in $communityName',
    body: 'Check it out now!',
  );
}
