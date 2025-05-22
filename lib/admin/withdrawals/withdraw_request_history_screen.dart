import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/withdraw_model.dart';

class WithdrawRequestHistoryScreen extends StatelessWidget {
  WithdrawRequestHistoryScreen({Key? key}) : super(key: key);

  final CollectionReference _withdrawalsRef =
      FirebaseFirestore.instance.collection('withdrawalRequests');

  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  Future<Map<String, dynamic>?> _fetchBankDetails(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Widget _buildRequestTile(WithdrawalRequest wr) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchBankDetails(wr.creatorUid),
      builder: (context, snapshot) {
        final bankData = snapshot.data;
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
                if (wr.processedAt != null)
                  Text(
                      'Processed At: ${wr.processedAt!.toLocal().toString().split('.')[0]}'),

                // Bank details section
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Text('Loading bank details...')
                else if (bankData == null)
                  const Text('Bank details not found')
                else ...[
                  Text('Bank Name: ${bankData['bankName'] ?? 'N/A'}'),
                  Text('Account Name: ${bankData['bankAccountName'] ?? 'N/A'}'),
                  Text(
                      'Account Number: ${bankData['bankAccountNumber'] ?? 'N/A'}'),
                ],
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Request History (Admin)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _withdrawalsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error loading withdrawal history'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No withdrawal requests found'));
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
