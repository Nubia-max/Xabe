import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String? description;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.description,
    required this.timestamp,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      description: map['description'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'description': description,
      'timestamp': timestamp,
    };
  }
}
