import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/controller/auth_controller.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _startPayment(int amountInKobo) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    final uniqueReference = PayWithPayStack().generateUuidV4();
    final authController = Get.find<AuthController>();
    final user = authController.userModel.value;

    if (user == null || user.email.isEmpty) {
      Get.snackbar('Error', 'User information missing.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (kIsWeb) {
        /// Web flow: Call Firebase Function to initialize payment
        final response = await http.post(
          Uri.parse(
              'https://us-central1-xabe-ai.cloudfunctions.net/initAddFunds'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': user.email,
            'amount': amountInKobo,
            'userId': user.uid,
          }),
        );

        if (response.statusCode != 200) {
          throw 'Unable to initiate payment. Try again later.';
        }

        final data = jsonDecode(response.body);
        final paystackUrl = data['paymentUrl'];
        final reference = data['reference'];

        if (await canLaunch(paystackUrl)) {
          await launch(paystackUrl);

          // Listen for transaction update
          FirebaseFirestore.instance
              .collection('transactions')
              .where('reference', isEqualTo: reference)
              .snapshots()
              .listen((snapshot) async {
            if (snapshot.docs.isNotEmpty) {
              await authController.reloadUser();
              Get.back(result: true);
              Get.snackbar('Success', 'Funds added successfully!');
            }
          });
        } else {
          throw 'Could not open Paystack payment page.';
        }
      } else {
        /// Mobile flow using plugin
        await PayWithPayStack().now(
          context: context,
          secretKey: 'sk_live_081a6b72526a9c7fcda22c9f194272fa9ac84e23',
          customerEmail: user.email,
          reference: uniqueReference,
          currency: 'NGN',
          amount: amountInKobo.toDouble(),
          transactionCompleted: (paymentData) async {
            final amountInNaira = amountInKobo / 100.0;

            await FirebaseFirestore.instance.collection('transactions').add({
              'userId': user.uid,
              'amount': amountInNaira,
              'status': 'success',
              'reference': uniqueReference,
              'paymentMethod': 'paystack',
              'createdAt': FieldValue.serverTimestamp(),
            });

            await authController.addFundsToUserBalance(amountInNaira);
            await authController.reloadUser();
            Navigator.pop(context, true);
            Get.snackbar('Success', 'Payment completed!');
          },
          transactionNotCompleted: (reason) {
            Get.snackbar('Failed', reason);
          },
          callbackUrl: '',
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onPayPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        Get.snackbar('Error', 'Enter a valid amount');
        return;
      }
      final amountInKobo = (amount * 100).toInt(); // Convert ₦ to kobo
      _startPayment(amountInKobo);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Funds')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _onPayPressed,
                      child: const Text('Pay Now'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
