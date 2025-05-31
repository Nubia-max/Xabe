import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // <-- Added for IAP

import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/features/community/repository/community_repository.dart';

import '../../../core/failure.dart';
import '../../../models/withdraw_model.dart';

class ModToolsScreen extends StatefulWidget {
  final Community community;
  final CommunityRepository _communityRepo = CommunityRepository(
    firestore: FirebaseFirestore.instance,
  );

  ModToolsScreen({
    super.key,
    required this.community,
  });

  @override
  _ModToolsScreenState createState() => _ModToolsScreenState();
}

class _ModToolsScreenState extends State<ModToolsScreen> {
  bool _isUpgrading = false;
  bool _isWithdrawing = false;

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _iapAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _initializeIAP() async {
    _iapAvailable = await _iap.isAvailable();
    if (!_iapAvailable) return;

    const Set<String> ids = {
      'premium_community_upgrade'
    }; // Replace with your real product IDs
    final response = await _iap.queryProductDetails(ids);
    if (response.error == null) {
      setState(() => _products = response.productDetails);
    }

    _subscription = _iap.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        // handle error if needed
      },
    );
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        final verified = await _verifyPurchaseOnBackend(purchaseDetails);
        if (verified) {
          Get.snackbar('Success', 'Community upgraded to premium!');
          setState(() => _isUpgrading = false);
        } else {
          Get.snackbar('Error', 'Purchase verification failed.');
          setState(() => _isUpgrading = false);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        Get.snackbar(
            'Error', purchaseDetails.error?.message ?? 'Purchase error');
        setState(() => _isUpgrading = false);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<bool> _verifyPurchaseOnBackend(PurchaseDetails purchaseDetails) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final receipt = purchaseDetails.verificationData.serverVerificationData;
      final response = await http.post(
        Uri.parse(
            'https://us-central1-xabe-ai.cloudfunctions.net/verifyAppleIAP'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.uid,
          'communityName': widget.community.name,
          'bio': widget.community.bio ?? '',
          'requiresVerification': widget.community.requiresVerification,
          'receiptData': receipt,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying purchase on backend: $e');
      return false;
    }
  }

  void _navigateToEditCommunity() {
    Get.toNamed('/edit-community/${Uri.encodeComponent(widget.community.id)}');
  }

  void _navigateToAddMods() {
    Get.toNamed('/add-mods/${Uri.encodeComponent(widget.community.id)}');
  }

  void _navigateToBankDetails() {
    Get.toNamed('/bank-details'); // Adjust route if needed
  }

  void _confirmAndDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Community'),
        content: Text(
          'Are you sure you want to delete "${widget.community.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              final result = await widget._communityRepo
                  .deleteCommunity(widget.community.id);
              result.match(
                (failure) => Get.snackbar(
                  'Error',
                  failure.message,
                  snackPosition: SnackPosition.BOTTOM,
                ),
                (_) {
                  Get.snackbar(
                    'Deleted',
                    'Community "${widget.community.name}" has been deleted.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  Get.offAllNamed('/');
                },
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<String> _fetchUsername(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['name'] ?? uid;
    } catch (_) {
      return uid;
    }
  }

  Future<void> _upgradeToPremium() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Upgrade to Premium"),
        content:
            Text("Upgrade ${widget.community.name} to premium for ₦5,000?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Upgrade"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'You must be logged in to upgrade this community.');
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      Get.snackbar('Error', 'Your email is missing or invalid.');
      return;
    }

    setState(() => _isUpgrading = true);

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Use Apple IAP on iOS
      if (!_iapAvailable || _products.isEmpty) {
        setState(() => _isUpgrading = false);
        Get.snackbar('Error', 'Apple IAP products not available.');
        return;
      }
      final product = _products.firstWhere(
        (p) => p.id == 'premium_community_upgrade',
        orElse: () => _products.first,
      );
      final purchaseParam = PurchaseParam(productDetails: product);
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // Use existing Paystack HTTP payment on Android/Web
      final success = await _startPremiumPaymentHttp(
        userId: user.uid,
        email: email,
        communityName: widget.community.name,
        bio: widget.community.bio ?? '',
        requiresVerification: widget.community.requiresVerification,
      );

      setState(() => _isUpgrading = false);

      if (success) {
        Get.snackbar(
          'Payment',
          'Complete payment in your browser. Your community will be upgraded automatically.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar('Error', 'Failed to initiate payment.');
      }
    }
  }

  Future<bool> _startPremiumPaymentHttp({
    required String userId,
    required String email,
    required String communityName,
    required String bio,
    required bool requiresVerification,
  }) async {
    const cloudFunctionUrl =
        'https://us-central1-xabe-ai.cloudfunctions.net/createPremiumPayment';

    final payload = {
      'userId': userId,
      'email': email,
      'communityName': communityName,
      'bio': bio,
      'requiresVerification': requiresVerification,
    };

    print('Calling createPremiumPayment with payload: $payload');

    try {
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['paymentUrl'] != null) {
        final url = data['paymentUrl'];
        if (await canLaunch(url)) {
          await launch(url);

          final bool? result = await showDialog<bool>(
            context: Get.context!,
            builder: (context) => AlertDialog(
              title: const Text('Payment'),
              content: const Text(
                  'Complete your payment in the browser. Click Done when finished.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Done'),
                ),
              ],
            ),
          );

          if (result == true) {
            Get.offAllNamed('/home');
          }
          return true;
        } else {
          throw 'Could not launch payment URL';
        }
      } else {
        print('Server error: ${data['error']}');
        return false;
      }
    } catch (e) {
      print('HTTP payment error: $e');
      return false;
    }
  }

  Future<void> _handleWithdrawFunds() async {
    final user = Get.find<AuthController>().userModel.value!;
    if (user.uid != widget.community.creatorUid) {
      Get.snackbar('Error', 'Only the creator can withdraw funds.');
      return;
    }

    // Check if bank details exist for this user before allowing withdrawal
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    if (userData == null ||
        userData['bankAccountNumber'] == null ||
        userData['bankCode'] == null ||
        userData['bankAccountName'] == null) {
      Get.snackbar('Error',
          'Please add your bank details before requesting withdrawal.');
      return;
    }

    final communityDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.community.id)
        .get();

    final balanceRaw = communityDoc.data()?['balance'] ?? 0;
    final currentBalance =
        (balanceRaw is int) ? balanceRaw.toDouble() : balanceRaw as double;

    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Withdraw Funds"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Community Balance: ₦${currentBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Text(
              "You will receive 70% of the amount you withdraw. The remaining 30% will be retained as platform profit.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Enter amount to withdraw',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final typedAmount = double.tryParse(controller.text.trim()) ?? 0;
              if (typedAmount <= 0) {
                Get.snackbar('Error', 'Please enter a valid amount.');
                return;
              }

              if (typedAmount > currentBalance) {
                Get.snackbar('Error',
                    'Insufficient community balance for this withdrawal.');
                return;
              }

              Navigator.pop(context); // close dialog
              setState(() => _isWithdrawing = true);

              try {
                // Create withdrawal request document (no balance deduction yet)
                final withdrawalRef = FirebaseFirestore.instance
                    .collection('withdrawalRequests')
                    .doc();

                final withdrawalRequest = WithdrawalRequest(
                  id: withdrawalRef.id,
                  communityId: widget.community.id,
                  creatorUid: user.uid,
                  amountRequested: typedAmount,
                  amountToPay: typedAmount * 0.7,
                  status: 'pending',
                  createdAt: DateTime.now(),
                  processedAt: null,
                );

                await withdrawalRef.set(withdrawalRequest.toMap());

                Get.snackbar(
                  'Withdrawal Requested',
                  'You requested ₦${typedAmount.toStringAsFixed(2)}. '
                      'You will receive ₦${(typedAmount * 0.7).toStringAsFixed(2)} after platform fees once approved.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar('Error', 'Failed to request withdrawal: $e');
              } finally {
                setState(() => _isWithdrawing = false);
              }
            },
            child: const Text("Request Withdrawal"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = Get.find<AuthController>().userModel.value?.uid;
    final isCreator =
        currentUid != null && currentUid == widget.community.creatorUid;
    final isPremium = widget.community.communityType == 'premium';

    return Scaffold(
      appBar: AppBar(title: const Text('Mod Tools')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add_moderator),
              title: const Text('Add Moderators'),
              onTap: _navigateToAddMods,
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Community'),
              onTap: _navigateToEditCommunity,
            ),
            if (isCreator) ...[
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Add/Edit Bank Details'),
                subtitle:
                    const Text('Add your bank details to enable withdrawals'),
                onTap: _navigateToBankDetails,
              ),
            ],
            if (widget.community.communityType == 'regular')
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: const Text('Upgrade to Premium'),
                  subtitle: const Text(
                      'Upgrade this community to premium for ₦5,000.'),
                  trailing: _isUpgrading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton(
                          onPressed: _upgradeToPremium,
                          child: const Text('Upgrade'),
                        ),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Banned Users'),
              subtitle: widget.community.bannedUsers.isEmpty
                  ? const Text('No banned users.')
                  : null,
            ),
            ...widget.community.bannedUsers.map((uid) {
              return FutureBuilder<String>(
                future: _fetchUsername(uid),
                builder: (context, snapshot) {
                  final username = snapshot.data ?? uid;
                  return ListTile(
                    leading: const Icon(Icons.person_off),
                    title: Text(username),
                    subtitle: Text('UID: $uid'),
                    trailing: IconButton(
                      icon: const Icon(Icons.undo, color: Colors.green),
                      tooltip: 'Unban User',
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('communities')
                            .doc(widget.community.id)
                            .update({
                          'bannedUsers': FieldValue.arrayRemove([uid]),
                        });

                        Get.snackbar(
                          'User Unbanned',
                          '$username has been unbanned from the community.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  );
                },
              );
            }).toList(),
            if (isCreator && isPremium) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Withdraw Funds'),
                subtitle:
                    const Text('Request withdrawal from community wallet'),
                trailing: _isWithdrawing
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _handleWithdrawFunds,
                        child: const Text("Withdraw"),
                      ),
              ),
            ],
            if (isCreator) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Community',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmAndDelete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
