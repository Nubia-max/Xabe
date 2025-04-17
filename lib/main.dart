import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
import 'package:url_strategy/url_strategy.dart';
import 'router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  NotiService().initNotification();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();
  final firebaseStorage = FirebaseStorage.instance;

  final notiService = NotiService();
  Get.put<NotiService>(notiService);

  Get.put<FirebaseFirestore>(firestore);
  Get.put<FirebaseStorage>(firebaseStorage);

  Get.put<AuthRepository>(AuthRepository(
    firestore: firestore,
    auth: firebaseAuth,
    googleSignIn: googleSignIn,
  ));
  Get.put<AuthController>(
      AuthController(authRepository: Get.find<AuthRepository>()));

  final communityRepository = CommunityRepository(firestore: firestore);
  final storageRepository = StorageRepository(firebaseStorage: firebaseStorage);
  Get.put<CommunityController>(CommunityController(
    communityRepository: communityRepository,
    storageRepository: storageRepository,
  ));

  final userProfileRepository = UserProfileRepository(firestore: firestore);
  Get.put<UserProfileController>(UserProfileController(
    storageRepository: storageRepository,
    userProfileRepository: userProfileRepository,
  ));

  final postRepository = PostRepository(firestore: firestore);
  Get.put<PostRepository>(postRepository);
  Get.put<PostController>(PostController(
    postRepository: postRepository,
    storageRepository: storageRepository,
  ));

  final notificationRepository = NotificationRepository(firestore: firestore);
  Get.put<NotificationRepository>(notificationRepository);
  Get.put<NotificationController>(NotificationController(
    notificationRepository: notificationRepository,
    notiService: notiService,
  ));

  Get.put<CommunityController>(
    CommunityController(
      communityRepository: CommunityRepository(firestore: firestore),
      storageRepository: storageRepository,
    ),
  );

  Get.put<ThemeController>(ThemeController());

  setPathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/9214589741',
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

  @override
  void dispose() {
    _bannerAd.dispose();
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
        builder: (context, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: _isAdLoaded
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
}
