import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/terms_screen.dart';
import 'router.dart';
import 'firebase_options.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/features/auth/repository/auth_repository.dart';
import 'package:xabe/features/community/controller/community_controller.dart';
import 'package:xabe/features/community/repository/community_repository.dart';
import 'package:xabe/core/providers/storage_repository.dart';
import 'package:xabe/features/notifications/noti_service.dart';
import 'package:xabe/features/posts/controller/post_controller.dart';
import 'package:xabe/features/posts/repository/post_repository.dart';
import 'package:xabe/theme/pallete.dart';
import 'package:xabe/theme/theme_controller.dart';
import 'package:xabe/features/user_profile/controller/user_profile_controller.dart';
import 'package:xabe/features/user_profile/repository/user_profile_repository.dart';
import 'package:xabe/features/notifications/notification_controller.dart';
import 'package:xabe/features/notifications/notification_repository.dart';

const String _androidBannerAdUnitId = 'ca-app-pub-8352296755977335/6184022554';
const String _iosBannerAdUnitId = 'ca-app-pub-8352296755977335/3919625753';

String get bannerAdUnitId {
  if (kIsWeb) throw UnsupportedError('Ads are not supported on web');
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return _androidBannerAdUnitId;
    case TargetPlatform.iOS:
      return _iosBannerAdUnitId;
    default:
      throw UnsupportedError('Unsupported platform for ads');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads SDK only for mobile platforms (Android/iOS)
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Initialize notifications
  NotiService().initNotification();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activate AppCheck only on mobile platforms
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  // --- Dependency Injection ---
  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();
  final firebaseStorage = FirebaseStorage.instance;

  Get.put<FirebaseFirestore>(firestore);
  Get.put<FirebaseStorage>(firebaseStorage);

  // Auth
  Get.put<AuthRepository>(AuthRepository(
    firestore: firestore,
    auth: firebaseAuth,
    googleSignIn: googleSignIn,
  ));
  Get.put<AuthController>(AuthController(authRepository: Get.find()));

  // Community
  Get.put<CommunityController>(CommunityController(
    communityRepository: CommunityRepository(firestore: firestore),
    storageRepository: StorageRepository(firebaseStorage: firebaseStorage),
  ));

  // User Profile
  Get.put<UserProfileController>(UserProfileController(
    storageRepository: StorageRepository(firebaseStorage: firebaseStorage),
    userProfileRepository: UserProfileRepository(firestore: firestore),
  ));

  // Posts
  Get.put<PostController>(PostController(
    postRepository: PostRepository(firestore: firestore),
    storageRepository: StorageRepository(firebaseStorage: firebaseStorage),
  ));

  // Notifications repo & controller
  final notificationRepository = NotificationRepository(firestore: firestore);
  final notiService = NotiService();
  Get.put<NotificationRepository>(notificationRepository);
  Get.put<NotificationController>(NotificationController(
    notificationRepository: notificationRepository,
    notiService: notiService,
  ));

  // --- Theme ---
  Get.put<ThemeController>(ThemeController());

  // URL strategy for web
  setPathUrlStrategy();

  // --- Run App ---
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final BannerAd _bannerAd;
  bool _isAdLoaded = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    _checkEulaAgreement();
  }

  void _loadAd() {
    if (kIsWeb) return;

    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('Ad failed to load: $err');
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  Future<void> _checkEulaAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(kEulaVersionKey) ?? 0;
    setState(() => _agreed = version >= kCurrentEulaVersion);
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _bannerAd.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Xabe',
        initialRoute: '/login',
        getPages: appRoutes, // Set up your routes here
        theme: Pallete.lightModeAppTheme, // Light theme from Pallete class
        darkTheme: Pallete.darkModeAppTheme, // Dark theme from Pallete class
        themeMode: themeController.mode.value, // Listen to theme mode changes

        builder: (context, child) {
          if (!_agreed) {
            return TermsScreen(onAgreed: _onAgreed);
          }
          return Scaffold(
            body: child,
            bottomNavigationBar: (!kIsWeb && _isAdLoaded)
                ? SizedBox(
                    height: _bannerAd.size.height.toDouble(),
                    width: _bannerAd.size.width.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  )
                : null,
          );
        },
      );
    });
  }

  Future<void> _onAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kEulaVersionKey, kCurrentEulaVersion);
    setState(() => _agreed = true);

    // Add a small delay to allow GetMaterialApp to initialize properly
    await Future.delayed(Duration(milliseconds: 500));

    // Now navigate to the home screen
    Get.offAllNamed('/');
  }
}
