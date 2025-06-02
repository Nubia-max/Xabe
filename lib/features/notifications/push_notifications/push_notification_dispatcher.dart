import 'package:xabe/features/notifications/push_notifications/user_joined_push.dart';

import 'added_as_moderator_push.dart';
import 'election_ended_push.dart';
import 'election_started_push.dart';
import 'join_accepted_push.dart';
import 'new_post_push.dart';

class PushNotificationDispatcher {
  static void userJoined(String username, String communityName) {
    sendUserJoinedPush(username, communityName);
  }

  static void joinAccepted(String communityName) {
    sendJoinAcceptedPush(communityName);
  }

  static void electionStarted(String communityName) {
    sendElectionStartedPush(communityName);
  }

  static void newPost(String communityName) {
    sendNewPostPush(communityName);
  }

  static void electionEnded(String communityName) {
    sendElectionEndedPush(communityName);
  }

  static void addedAsModerator(String communityName) {
    sendAddedAsModeratorPush(communityName);
  }
}
