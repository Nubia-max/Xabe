import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequest {
  final String id;
  final String communityId;
  final String creatorUid;
  final double amountRequested;
  final double amountToPay;
  final String status;
  final DateTime createdAt;
  final DateTime? processedAt;

  WithdrawalRequest({
    required this.id,
    required this.communityId,
    required this.creatorUid,
    required this.amountRequested,
    required this.amountToPay,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'creatorUid': creatorUid,
      'amountRequested': amountRequested,
      'amountToPay': amountToPay,
      'status': status,
      'createdAt': createdAt,
      'processedAt': processedAt,
    };
  }

  factory WithdrawalRequest.fromMap(String id, Map<String, dynamic> map) {
    return WithdrawalRequest(
      id: id,
      communityId: map['communityId'] ?? '',
      creatorUid: map['creatorUid'] ?? '',
      amountRequested: (map['amountRequested'] as num?)?.toDouble() ?? 0.0,
      amountToPay: (map['amountToPay'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
