import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

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

  Future<void> _startPayment(int amountInMinorUnits) async {
    setState(() => _isLoading = true);

    final uniqueTransRef = PayWithPayStack().generateUuidV4();

    final userEmail = Get.find<AuthController>().userModel.value?.email;

    if (userEmail == null || userEmail.isEmpty) {
      Get.snackbar(
        'Error',
        'User email not found, please update your profile.',
      );
      setState(() => _isLoading = false);
      return; // Stop if email is not available
    }

    try {
      await PayWithPayStack().now(
        context: context,
        secretKey:
            'sk_live_081a6b72526a9c7fcda22c9f194272fa9ac84e23', // Replace with your secret key
        customerEmail: userEmail,
        reference: uniqueTransRef,
        currency: 'NGN',
        amount: amountInMinorUnits.toDouble(),
        callbackUrl: '',

        transactionCompleted: (paymentData) async {
          debugPrint('Payment completed: $paymentData');
          Get.snackbar('Success', 'Payment successful!');

          // Convert minor units back to normal (e.g. kobo to Naira)
          final paidAmount = amountInMinorUnits / 1.0;

          // Update user balance via AuthController
          await Get.find<AuthController>().addFundsToUserBalance(paidAmount);

          Navigator.pop(context, true);
        },
        transactionNotCompleted: (reason) {
          debugPrint('Transaction failed: $reason');
          Get.snackbar('Failed', 'Payment failed: $reason');
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onPayPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        Get.snackbar('Error', 'Please enter a valid amount');
        return;
      }
      final amountInMinorUnits =
          (amount * 1).toInt(); // Paystack expects amount in kobo
      _startPayment(amountInMinorUnits);
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
      appBar: AppBar(
        title: const Text('Add Funds'),
      ),
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
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount greater than 0';
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
