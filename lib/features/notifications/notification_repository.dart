import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:xabe/core/failure.dart';
import 'package:xabe/core/type_def.dart';
import 'notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  NotificationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _notifications =>
      _firestore.collection('notifications');

  FutureVoid createNotification(NotificationModel notification) async {
    try {
      return right(
          _notifications.doc(notification.id).set(notification.toMap()));
    } on FirebaseException catch (e) {
      return left(Failure(e.message!));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  FutureVoid markNotificationAsProcessed(String notificationId) async {
    try {
      return right(_notifications.doc(notificationId).update({
        'isProcessed': true,
      }));
    } on FirebaseException catch (e) {
      return left(Failure(e.message!));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map<NotificationModel>((doc) =>
                NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
