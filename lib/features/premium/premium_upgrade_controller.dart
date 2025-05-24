import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumUpgradeController extends GetxController {
  final InAppPurchase _iap = InAppPurchase.instance;

  bool available = false;
  List<ProductDetails> products = [];
  List<PurchaseDetails> purchases = [];

  // To hold the community ID to upgrade (set from UI before purchase)
  String? communityIdToUpgrade;

  // Reactive to track loading state
  var isUpgrading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initStore();
  }

  Future<void> _initStore() async {
    available = await _iap.isAvailable();
    if (!available) {
      print('Store not available');
      return;
    }

    final response = await _iap
        .queryProductDetails({'com.yourapp.community.premium_upgrade'});
    if (response.error != null) {
      print('Error fetching products: ${response.error}');
      return;
    }
    products = response.productDetails;
    update();

    _iap.purchaseStream.listen(_listenToPurchaseUpdated, onDone: () {
      print('Purchase stream closed');
    }, onError: (error) {
      print('Purchase stream error: $error');
    });
  }

  void buyPremium(String communityId) {
    if (!available || products.isEmpty) {
      Get.snackbar('Error', 'In-app purchases not available');
      return;
    }

    communityIdToUpgrade = communityId;

    final product = products.firstWhere(
      (p) => p.id == 'com.yourapp.community.premium_upgrade',
      orElse: () => products.first,
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _verifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        Get.snackbar('Purchase Error',
            purchaseDetails.error?.message ?? 'Unknown error');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Send purchaseDetails.verificationData.serverVerificationData to your backend to validate

    // For now, assume success (replace with actual verification)
    final verified = true;

    if (verified) {
      await _upgradeCommunityToPremium();
      Get.snackbar('Success', 'Community upgraded to premium!');
    } else {
      Get.snackbar('Error', 'Purchase verification failed.');
    }
  }

  Future<void> _upgradeCommunityToPremium() async {
    if (communityIdToUpgrade == null) {
      Get.snackbar('Error', 'No community selected for upgrade.');
      return;
    }

    try {
      isUpgrading.value = true;

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(communityIdToUpgrade)
          .update({'communityType': 'premium'});

      // Optionally, you can notify user or update local state here
    } catch (e) {
      Get.snackbar('Error', 'Failed to upgrade community: $e');
    } finally {
      isUpgrading.value = false;
      communityIdToUpgrade = null;
    }
  }
}
