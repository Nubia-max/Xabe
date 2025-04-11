import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final String type; // e.g., 'join_request'
  final String communityName;
  final String communityId;
  final bool isProcessed;
  final String? verificationImageUrl; // New field

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.communityName,
    required this.communityId,
    this.isProcessed = false,
    this.verificationImageUrl,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String? ?? '',
      recipientId: map['recipientId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: map['type'] as String? ?? '',
      communityId: map['communityId'] as String? ?? '',
      communityName: map['communityName'] as String? ?? '',
      isProcessed: map['isProcessed'] as bool? ?? false,
      verificationImageUrl:
          map['verificationImageUrl'] as String?, // include if exists
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientId': recipientId,
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'communityId': communityId,
      'communityName': communityName,
      'isProcessed': isProcessed,
      'verificationImageUrl': verificationImageUrl,
    };
  }
}
