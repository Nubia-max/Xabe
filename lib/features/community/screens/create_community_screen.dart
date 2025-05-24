import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/utils/simple_filter.dart';
import '../../../core/utils/utils.dart';
import '../../../theme/theme_controller.dart';
import '../controller/community_controller.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController communityNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  bool requiresVerification = true;

  String _communityType = 'regular';

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;

  // Your product ID from app stores (replace with your actual ID)
  static const String premiumProductId = 'premium_community_5000';

  List<ProductDetails> _products = [];
  late Stream<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    super.initState();
    _initStoreInfo();
  }

  Future<void> _initStoreInfo() async {
    final bool isAvailable = await _iap.isAvailable();

    if (!isAvailable) {
      setState(() {
        _isAvailable = false;
        _products = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    final ProductDetailsResponse productDetailResponse =
        await _iap.queryProductDetails({premiumProductId});

    if (productDetailResponse.error != null) {
      setState(() {
        _isAvailable = false;
        _products = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _isAvailable = false;
        _products = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    setState(() {
      _isAvailable = true;
      _products = productDetailResponse.productDetails;
      _purchasePending = false;
      _loading = false;
    });

    _subscription = _iap.purchaseStream;
    _subscription.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      // stream closed
    }, onError: (error) {
      // handle error
      Get.snackbar('Error', 'Purchase stream error: $error');
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _verifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        Get.snackbar('Purchase Error',
            purchaseDetails.error?.message ?? 'Unknown error');
        setState(() {
          _purchasePending = false;
        });
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        _verifyPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Verify purchase with backend or App Store / Play Store
    // For now, assume verification success
    if (!mounted) return;

    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }

    // After successful purchase, create the premium community
    _createCommunityAfterPurchase();

    setState(() {
      _purchasePending = false;
    });
  }

  void _createCommunityAfterPurchase() {
    final name = communityNameController.text.trim();

    if (!SimpleFilter.isClean(name)) {
      showSnackBar(context, 'Community name contains disallowed words.');
      return;
    }

    Get.find<CommunityController>().createCommunity(
      name,
      bioController.text.trim(),
      requiresVerification,
      context,
      communityType: 'premium',
    );
  }

  void createCommunity() {
    final name = communityNameController.text.trim();

    if (!SimpleFilter.isClean(name)) {
      showSnackBar(context, 'Community name contains disallowed words.');
      return;
    }

    if (_communityType == 'regular') {
      // Create regular community immediately
      Get.find<CommunityController>().createCommunity(
        name,
        bioController.text.trim(),
        requiresVerification,
        context,
        communityType: 'regular',
      );
    } else if (_communityType == 'premium') {
      if (!_isAvailable || _products.isEmpty) {
        Get.snackbar('Store Unavailable', 'In-app purchases not available.');
        return;
      }

      final productDetails = _products.firstWhere(
        (product) => product.id == premiumProductId,
        orElse: () => _products.first,
      );

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

      setState(() {
        _purchasePending = true;
      });
    }
  }

  @override
  void dispose() {
    communityNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Community',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: _loading
          ? const Loader()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  TextField(
                    controller: communityNameController,
                    decoration: InputDecoration(
                      hintText: 'Community Name',
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black),
                    ),
                    maxLength: 21,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: bioController,
                    decoration: InputDecoration(
                      hintText: 'Bio',
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Community Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  RadioListTile<String>(
                    title: const Text('Regular'),
                    value: 'regular',
                    groupValue: _communityType,
                    onChanged: (value) {
                      setState(() {
                        _communityType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Premium'),
                    value: 'premium',
                    groupValue: _communityType,
                    onChanged: (value) {
                      setState(() {
                        _communityType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Require ID verification for members to join',
                        style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      const Spacer(),
                      Switch(
                        value: requiresVerification,
                        onChanged: (val) {
                          setState(() {
                            requiresVerification = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _purchasePending ? null : createCommunity,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _purchasePending
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "Create",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "You can always edit the community later.",
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
