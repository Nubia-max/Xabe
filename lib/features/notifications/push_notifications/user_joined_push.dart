import '../push_notification_service.dart';

void sendUserJoinedPush(String username, String communityName) {
  PushNotificationService.sendNotification(
    title: '$username wants to join $communityName',
    body: 'Tap to view their profile or approve the request.',
  );
}
