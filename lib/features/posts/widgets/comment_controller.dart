// comment_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../models/comment_model.dart';
import '../../auth/controller/auth_controller.dart';

class CommentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = const Uuid();

  /// Call this when the user submits a new comment on [postId].
  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      final currentUser = _authController.userModel.value!;
      final commentId = _uuid.v4();
      final comment = Comment(
        id: commentId,
        text: text,
        createdAt: DateTime.now(),
        postId: postId,
        username: currentUser.name,
        // <-- notice: userModel.name not username
        profilePic: currentUser.profilePic,
      );

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      final postSnap = await _firestore.collection('posts').doc(postId).get();
      if (!postSnap.exists) {
        throw Exception("Post not found");
      }
      final postData = postSnap.data()!;
      final postOwnerUid = postData['uid'] as String;

      final notificationId = _uuid.v4();
      final notificationData = {
        'id': notificationId,
        'receiverUid': postOwnerUid,
        'senderUid': currentUser.uid,
        'senderUsername': currentUser.name,
        'postId': postId,
        'type': 'comment',
        'text': '${currentUser.name} commented on your post',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'profilePic': currentUser.profilePic,
      };

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notificationData);

      Get.snackbar('Success', 'Comment posted and user notified');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
