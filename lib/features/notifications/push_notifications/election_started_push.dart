import '../push_notification_service.dart';

void sendElectionStartedPush(String communityName) {
  PushNotificationService.sendNotification(
    title: 'Elections have started in $communityName',
    body: 'Cast your votes now!',
  );
}
