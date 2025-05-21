import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction_model.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TransactionModel>> getUserTransactionsStream(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> recordTransaction({
    required String userId,
    required double amount,
    required String status, // e.g. 'success', 'failed'
    required String reference, // transaction reference from Paystack
    String? paymentMethod,
  }) async {
    final transactionsCollection =
        FirebaseFirestore.instance.collection('transactions');

    await transactionsCollection.add({
      'userId': userId,
      'amount': amount,
      'status': status,
      'reference': reference,
      'paymentMethod': paymentMethod ?? 'unknown',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
