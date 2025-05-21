import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _getTransactionsStream() {
    final userId = Get.find<AuthController>().userModel.value?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('transactions') // Replace with your collection name
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final amount = data['amount'] ?? 0;
              final createdAt = data['createdAt'] as Timestamp?;
              final status = data['status'] ?? 'unknown';

              return ListTile(
                leading: Icon(
                  status == 'success' ? Icons.check_circle : Icons.error,
                  color: status == 'success' ? Colors.green : Colors.red,
                ),
                title: Text('₦$amount'),
                subtitle: Text(createdAt != null
                    ? _formatDate(createdAt)
                    : 'Unknown date'),
                trailing: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(
                    color: status == 'success' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
