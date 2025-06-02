import '../push_notification_service.dart';

void sendAddedAsModeratorPush(String communityName) {
  PushNotificationService.sendNotification(
    title: 'You are now a moderator in $communityName',
    body: 'Moderation tools are now available to you.',
  );
}
