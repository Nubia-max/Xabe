import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/withdraw_model.dart';

class WithdrawalApprovalScreen extends StatelessWidget {
  WithdrawalApprovalScreen({Key? key}) : super(key: key);

  final CollectionReference _withdrawalsRef =
      FirebaseFirestore.instance.collection('withdrawalRequests');
  final CollectionReference _communitiesRef =
      FirebaseFirestore.instance.collection('communities');
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  Future<void> _updateStatus(
      WithdrawalRequest wr, String newStatus, BuildContext context) async {
    try {
      final processedAt = DateTime.now();

      if (newStatus == 'approved') {
        // Deduct full amount from community balance inside a transaction
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final communityDoc = _communitiesRef.doc(wr.communityId);
          final snapshot = await transaction.get(communityDoc);

          if (!snapshot.exists) {
            throw Exception('Community does not exist');
          }

          final data = snapshot.data() as Map<String, dynamic>;
          final balanceRaw = data['balance'] ?? 0;
          final currentBalance = (balanceRaw is int)
              ? balanceRaw.toDouble()
              : balanceRaw as double;

          if (currentBalance < wr.amountRequested) {
            throw Exception(
                'Insufficient community balance for this withdrawal');
          }

          // Deduct the full requested amount
          transaction.update(communityDoc, {
            'balance': currentBalance - wr.amountRequested,
          });

          // Update withdrawal request status and processedAt
          final withdrawalDoc = _withdrawalsRef.doc(wr.id);
          transaction.update(withdrawalDoc, {
            'status': newStatus,
            'processedAt': processedAt,
          });
        });
      } else {
        // For rejection or other statuses, just update status & processedAt
        await _withdrawalsRef.doc(wr.id).update({
          'status': newStatus,
          'processedAt': processedAt,
        });
      }

      Get.snackbar('Success', 'Withdrawal request $newStatus.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }

  Widget _buildRequestTile(WithdrawalRequest wr) {
    return FutureBuilder<DocumentSnapshot>(
      future: _usersRef.doc(wr.creatorUid).get(),
      builder: (context, snapshot) {
        String bankDetailsText = 'Loading bank details...';

        if (snapshot.hasError) {
          bankDetailsText = 'Error loading bank details';
        } else if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          final bankName = userData['bankName'] ?? 'N/A';
          final bankAccountName = userData['bankAccountName'] ?? 'N/A';
          final bankAccountNumber = userData['bankAccountNumber'] ?? 'N/A';

          bankDetailsText =
              'Bank: $bankName\nAccount Name: $bankAccountName\nAccount Number: $bankAccountNumber';
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          bankDetailsText = 'Loading bank details...';
        } else {
          bankDetailsText = 'No bank details found';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('Request from ${wr.creatorUid}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community: ${wr.communityId}'),
                Text('Requested: ₦${wr.amountRequested.toStringAsFixed(2)}'),
                Text('To Pay: ₦${wr.amountToPay.toStringAsFixed(2)}'),
                Text('Status: ${wr.status}'),
                Text(
                    'Requested At: ${wr.createdAt.toLocal().toString().split('.')[0]}'),
                const SizedBox(height: 8),
                Text(bankDetailsText),
              ],
            ),
            isThreeLine: true,
            trailing: wr.status == 'pending'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () =>
                            _updateStatus(wr, 'approved', Get.context!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () =>
                            _updateStatus(wr, 'rejected', Get.context!),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Requests (Admin)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _withdrawalsRef.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No pending withdrawal requests'));
          }

          final requests = docs.map((doc) {
            return WithdrawalRequest.fromMap(
                doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestTile(requests[index]);
            },
          );
        },
      ),
    );
  }
}
