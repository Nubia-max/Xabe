import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_strategy/url_strategy.dart';

import 'features/community/screens/community_screen.dart';
import 'features/community/screens/mod_tools_screen.dart';
import 'features/graph/graph_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/notifications/notification_screen.dart';
import 'features/premium/premium_election_screen.dart';
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔕 Handling a background message: \${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kIsWeb) {
    final fcmToken = await FirebaseMessaging.instance.getToken(
      vapidKey:
          "BLPIXv8hj_x-3TcTgfyghndxu2SiltbjnE7KZIC0vJ7qXNEThTITDWy6XYOiemlpb8yiVCmI5Ugv-ltzcyUBNHQ",
    );
    print("🌐 Web FCM Token: \$fcmToken");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🌐 Foreground Web message: \${message.notification?.title}');
    });
  }

  FirebaseMessaging.instance.getToken().then((token) {
    print("🔑 FCM Token: \$token");
  });

  FirebaseMessaging.instance.getAPNSToken().then((apnsToken) {
    if (apnsToken != null) {
      print("✅ APNs Token: \$apnsToken");
    } else {
      print("❌ Still no APNs Token. Check entitlements and Apple account.");
    }
  });

  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;
  final firebaseStorage = FirebaseStorage.instance;
  final googleSignIn = GoogleSignIn();

  Get.put<FirebaseFirestore>(firestore);
  Get.put<FirebaseStorage>(firebaseStorage);
  Get.put<AuthRepository>(AuthRepository(
    firestore: firestore,
    auth: firebaseAuth,
    googleSignIn: googleSignIn,
  ));
  Get.put<AuthController>(AuthController(authRepository: Get.find()));
  Get.put<CommunityController>(CommunityController(
    communityRepository: CommunityRepository(firestore: firestore),
    storageRepository: StorageRepository(firebaseStorage: firebaseStorage),
  ));
  Get.put<UserProfileController>(UserProfileController(
    storageRepository: StorageRepository(firebaseStorage: firebaseStorage),
    userProfileRepository: UserProfileRepository(firestore: firestore),
  ));
  Get.put<PostController>(PostController(
    postRepository: PostRepository(firestore: firestore),
    storageRepository: StorageRepository(firebaseStorage: firebaseStorage),
  ));

  final notificationRepo = NotificationRepository(firestore: firestore);
  Get.put<NotificationRepository>(notificationRepo);
  Get.put<NotificationController>(NotificationController(
    notificationRepository: notificationRepo,
  ));
  final notiService = NotiService();
  await notiService.init();

  Get.put<ThemeController>(ThemeController());

  setPathUrlStrategy();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    PremiumElectionScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message.data);
      }
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'added_as_moderator':
        Get.toNamed('/mod-tools/${data['communityId']}');
        break;
      case 'election_started':
        Get.to(() => CommunityScreen(
              communityId: data['communityId'],
              filter: 'elections',
            ));
        break;
      case 'election_ended':
        Get.to(() => GraphScreen(postId: data['postId']));
        break;
      case 'new_post':
        Get.to(() => CommunityScreen(
              communityId: data['communityId'],
              filter: 'campaigns',
            ));
        break;
      case 'user_joined':
        Get.to(() => NotificationsScreen());
        break;
      case 'join_accepted':
        Get.to(() => CommunityScreen(communityId: data['communityId']));
        break;
      default:
        print("Unknown notification type: $type");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        home: Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages,
            physics: const ClampingScrollPhysics(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon:
                    Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon:
                    Icon(_currentIndex == 1 ? Icons.poll : Icons.poll_outlined),
                label: 'Explore',
              ),
            ],
          ),
        ),
        getPages: appRoutes,
      );
    });
  }
}
