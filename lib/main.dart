import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
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
import 'router.dart'; // Import your GetX routes file
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotiService().initNotification();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create your Firebase instances.
  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();
  final firebaseStorage = FirebaseStorage.instance;

  // 👇 register your service
  final notiService = NotiService();
  Get.put<NotiService>(notiService);

  // Register Firebase instances.
  Get.put<FirebaseFirestore>(firestore);
  Get.put<FirebaseStorage>(firebaseStorage);

  // Register Auth dependencies.
  Get.put<AuthRepository>(AuthRepository(
    firestore: firestore,
    auth: firebaseAuth,
    googleSignIn: googleSignIn,
  ));
  Get.put<AuthController>(
      AuthController(authRepository: Get.find<AuthRepository>()));

  // Register Community dependencies.
  final communityRepository = CommunityRepository(firestore: firestore);
  final storageRepository = StorageRepository(firebaseStorage: firebaseStorage);
  Get.put<CommunityController>(CommunityController(
    communityRepository: communityRepository,
    storageRepository: storageRepository,
  ));

  // Register UserProfile dependencies.
  final userProfileRepository = UserProfileRepository(firestore: firestore);
  Get.put<UserProfileController>(UserProfileController(
    storageRepository: storageRepository,
    userProfileRepository: userProfileRepository,
  ));

  // Register Post dependencies.
  final postRepository = PostRepository(firestore: firestore);
  Get.put<PostRepository>(postRepository);
  Get.put<PostController>(PostController(
    postRepository: postRepository,
    storageRepository: storageRepository,
  ));

  // Register Notification dependencies.
  final notificationRepository = NotificationRepository(firestore: firestore);
  Get.put<NotificationRepository>(notificationRepository);
  Get.put<NotificationController>(NotificationController(
    notificationRepository: notificationRepository,
    notiService: notiService, // ← don’t forget this!
  ));

  Get.put<CommunityController>(
    CommunityController(
      communityRepository: CommunityRepository(firestore: firestore),
      storageRepository: storageRepository, // Pass the storage repository
    ),
  );

  // Register ThemeController (or other controllers).
  Get.put<ThemeController>(ThemeController());

  setPathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Xabe',
        theme: Pallete.lightModeAppTheme,
        darkTheme: Pallete.darkModeAppTheme,
        themeMode: themeController.mode.value,
        initialRoute: '/login',
        getPages: appRoutes,
      );
    });
  }
}
