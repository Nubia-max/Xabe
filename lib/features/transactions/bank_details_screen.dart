import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  _BankDetailsScreenState createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();

  String? _selectedBankCode;
  String? _selectedBankName;

  final List<Map<String, String>> _banks = [
    {'name': 'Access Bank', 'code': '044'},
    {'name': 'Citibank Nigeria', 'code': '023'},
    {
      'name': 'Diamond Bank',
      'code': '063'
    }, // Now merged with Access Bank, but code often still used
    {'name': 'Ecobank Nigeria', 'code': '050'},
    {'name': 'Fidelity Bank', 'code': '070'},
    {'name': 'First Bank of Nigeria', 'code': '011'},
    {'name': 'First City Monument Bank', 'code': '214'},
    {'name': 'Globus Bank', 'code': '001'},
    {'name': 'Guaranty Trust Bank', 'code': '058'},
    {'name': 'Heritage Bank', 'code': '030'},
    {'name': 'Jaiz Bank', 'code': '301'},
    {'name': 'Keystone Bank', 'code': '082'},
    {'name': 'Kuda Bank', 'code': '50211'},
    {'name': 'Opay', 'code': '51251'},
    {'name': 'Parallex Bank', 'code': '52646'},
    {'name': 'Polaris Bank', 'code': '076'},
    {'name': 'Providus Bank', 'code': '101'},
    {'name': 'Stanbic IBTC Bank', 'code': '221'},
    {'name': 'Standard Chartered Bank', 'code': '068'},
    {'name': 'Sterling Bank', 'code': '232'},
    {'name': 'Suntrust Bank', 'code': '100'},
    {'name': 'TAJ Bank', 'code': '302'},
    {'name': 'Union Bank of Nigeria', 'code': '032'},
    {'name': 'United Bank for Africa', 'code': '033'},
    {'name': 'Unity Bank', 'code': '215'},
    {'name': 'Wema Bank', 'code': '035'},
    {'name': 'Zenith Bank', 'code': '057'},
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  void _loadBankDetails() {
    final user = Get.find<AuthController>().userModel.value;
    if (user == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    userDoc.get().then((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _accountNameController.text = data['bankAccountName'] ?? '';
        _accountNumberController.text = data['bankAccountNumber'] ?? '';
        _selectedBankCode = data['bankCode'];
        _selectedBankName = data['bankName'];
        setState(() {}); // refresh UI
      }
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to load bank details: $error');
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBankCode == null || _selectedBankName == null) {
      Get.snackbar('Error', 'Please select a bank.');
      return;
    }

    setState(() => _isLoading = true);
    final authController = Get.find<AuthController>();
    final user = authController.userModel.value!;
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    try {
      await userDoc.update({
        'bankAccountName': accountName,
        'bankAccountNumber': accountNumber,
        'bankCode': _selectedBankCode,
        'bankName': _selectedBankName,
      });

      // Optionally update local user model here if you want to reflect changes immediately
      authController.updateUser(
        user.copyWith(
          bankAccountName: accountName,
          bankAccountNumber: accountNumber,
          bankCode: _selectedBankCode,
          bankName: _selectedBankName,
        ),
      );

      Get.snackbar('Success', 'Bank details saved successfully!');
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save bank details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add/Edit Bank Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter account holder name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                ),
                maxLength: 10,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter account number';
                  }
                  if (val.trim().length != 10) {
                    return 'Account number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBankCode,
                decoration: const InputDecoration(
                  labelText: 'Select Bank',
                ),
                items: _banks
                    .map(
                      (bank) => DropdownMenuItem<String>(
                        value: bank['code'],
                        child: Text(bank['name']!),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedBankCode = val;
                    _selectedBankName = _banks
                        .firstWhere((bank) => bank['code'] == val)['name'];
                  });
                },
                validator: (val) => val == null ? 'Please select a bank' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Bank Details'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
