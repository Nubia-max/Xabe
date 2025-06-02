import '../push_notification_service.dart';

void sendElectionEndedPush(String communityName) {
  PushNotificationService.sendNotification(
    title: 'Election in $communityName has ended',
    body: 'View the results now!',
  );
}
