import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_strategy/url_strategy.dart';

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

// Real Ad Unit IDs
const String _androidBannerAdUnitId = 'ca-app-pub-8352296755977335/6184022554';
const String _iosBannerAdUnitId = 'ca-app-pub-8352296755977335/3919625753';

String get bannerAdUnitId {
  if (kIsWeb) {
    throw UnsupportedError('Ads are not supported on web');
  }
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

  // Dependency injection
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
  final communityRepository = CommunityRepository(firestore: firestore);
  final storageRepository = StorageRepository(firebaseStorage: firebaseStorage);
  Get.put<CommunityController>(CommunityController(
    communityRepository: communityRepository,
    storageRepository: storageRepository,
  ));

  // User Profile
  final userProfileRepository = UserProfileRepository(firestore: firestore);
  Get.put<UserProfileController>(UserProfileController(
    storageRepository: storageRepository,
    userProfileRepository: userProfileRepository,
  ));

  // Posts
  final postRepository = PostRepository(firestore: firestore);
  Get.put<PostController>(PostController(
    postRepository: postRepository,
    storageRepository: storageRepository,
  ));

  // Notifications repo & controller
  final notificationRepository = NotificationRepository(firestore: firestore);
  final notiService = NotiService();
  Get.put<NotificationRepository>(notificationRepository);
  Get.put<NotificationController>(NotificationController(
    notificationRepository: notificationRepository,
    notiService: notiService,
  ));

  // Theme
  Get.put<ThemeController>(ThemeController());

  // URL strategy for web
  setPathUrlStrategy();

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

  @override
  void initState() {
    super.initState();
    // Initialize banner ads only for mobile platforms
    if (!kIsWeb) {
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
  }

  @override
  void dispose() {
    // Dispose of the banner ad only for mobile platforms
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
        theme: Pallete.lightModeAppTheme,
        darkTheme: Pallete.darkModeAppTheme,
        themeMode: themeController.mode.value,
        initialRoute: '/login',
        getPages: appRoutes,
        builder: (context, child) => Scaffold(
          body: child,
          bottomNavigationBar: (!kIsWeb && _isAdLoaded)
              ? SizedBox(
                  height: _bannerAd.size.height.toDouble(),
                  width: _bannerAd.size.width.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                )
              : null,
        ),
      );
    });
  }
}
