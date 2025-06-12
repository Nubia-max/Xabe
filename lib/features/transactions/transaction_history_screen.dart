import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  // Update the stream to include web payments
  Stream<QuerySnapshot> _getTransactionsStream() {
    final userId = Get.find<AuthController>().userModel.value?.uid;
    if (userId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print("Error fetching transactions: $error");
      // You can optionally display an error message here instead of silently returning an empty stream.
    });
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
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading transactions'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Retry fetching transactions
                      // No need for setState, as StreamBuilder will rebuild on data change
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Handle empty data
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Firestore snapshots auto-update, so this can be empty.
              // If needed, you can manually trigger a refresh here.
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final amountRaw = data['amount'] ?? 0;
                final amount = amountRaw is int
                    ? amountRaw.toDouble()
                    : amountRaw as double? ?? 0.0;

                final createdAt = data['createdAt'] as Timestamp?;
                final status =
                    (data['status'] ?? 'unknown').toString().toLowerCase();

                Color statusColor;
                IconData statusIcon;

                switch (status) {
                  case 'success':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'pending':
                    statusColor = Colors.orange;
                    statusIcon = Icons.hourglass_empty;
                    break;
                  case 'failed':
                  case 'error':
                    statusColor = Colors.red;
                    statusIcon = Icons.error;
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusIcon = Icons.help_outline;
                }

                return ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text('₦${amount.toStringAsFixed(2)}'),
                  subtitle: Text(
                    createdAt != null ? _formatDate(createdAt) : 'Unknown date',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
