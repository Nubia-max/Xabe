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

import 'features/home/screens/home_screen.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
                icon: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 1 ? Icons.poll : Icons.poll_outlined,
                ),
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
