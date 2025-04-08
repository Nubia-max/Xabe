import 'package:get/get.dart';
import 'package:xabe/features/auth/screens/login_screen.dart';
import 'package:xabe/features/community/screens/add_mods_screen.dart';
import 'package:xabe/features/community/screens/community_screen.dart';
import 'package:xabe/features/community/screens/create_community_screen.dart';
import 'package:xabe/features/community/screens/edit_community_screen.dart';
import 'package:xabe/features/community/screens/mod_tools_screen.dart';
import 'package:xabe/features/home/screens/home_screen.dart';
import 'package:xabe/features/posts/screens/add_post_type_screen.dart';
import 'package:xabe/features/posts/screens/comments_screen.dart';
import 'package:xabe/features/user_profile/screens/edit_profile_screen.dart';
import 'package:xabe/features/user_profile/screens/user_profile_screen.dart';
import 'package:xabe/features/graph/graph_screen.dart';
import 'package:xabe/features/notifications/notification_screen.dart';
import 'package:xabe/responsive/mobile_screen_layout.dart';
import 'package:xabe/responsive/responsive_layout.dart';
import 'package:xabe/responsive/web_screen_layout.dart';
import 'package:flutter/material.dart';

import 'features/home/widgets/add_thumbnails.dart';

final List<GetPage> appRoutes = [
  // Login Screen
  GetPage(
    name: '/login',
    page: () => const LoginScreen(),
  ),
  // Home Screen wrapped in ResponsiveLayout
  GetPage(
    name: '/',
    page: () => ResponsiveLayout(
      mobileScreenLayout: MobileScreenLayout(child: const HomeScreen()),
      webScreenLayout: WebScreenLayout(child: const HomeScreen()),
    ),
  ),
  // Create Community Screen wrapped in ResponsiveLayout
  GetPage(
    name: '/create-community',
    page: () => ResponsiveLayout(
      mobileScreenLayout:
          MobileScreenLayout(child: const CreateCommunityScreen()),
      webScreenLayout: WebScreenLayout(child: const CreateCommunityScreen()),
    ),
  ),
  // Community Screen
  GetPage(
    name: '/X/:name',
    page: () {
      final name = Get.parameters['name'];
      // If the name parameter is missing, display an error screen.
      if (name == null || name.isEmpty) {
        return const Scaffold(
          body: Center(
            child: Text("Invalid association name."),
          ),
        );
      }
      // Optionally extract a filter parameter if needed.
      final filter = Get.parameters['filter'] ?? '';
      return ResponsiveLayout(
        mobileScreenLayout: MobileScreenLayout(
            child: CommunityScreen(name: name, filter: filter)),
        webScreenLayout:
            WebScreenLayout(child: CommunityScreen(name: name, filter: filter)),
      );
    },
  ),
  // Mod Tools Screen
  GetPage(
    name: '/mod-tools/:name',
    page: () {
      final name = Get.parameters['name'];
      if (name == null || name.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid association name.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: ModToolsScreen(name: name)),
        webScreenLayout: WebScreenLayout(child: ModToolsScreen(name: name)),
      );
    },
  ),
  // Edit Community Screen
  GetPage(
    name: '/edit-community/:name',
    page: () {
      final name = Get.parameters['name'];
      if (name == null || name.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid community name.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: EditCommunityScreen(name: name)),
        webScreenLayout:
            WebScreenLayout(child: EditCommunityScreen(name: name)),
      );
    },
  ),
  // Add Moderators Screen
  GetPage(
    name: '/add-mods/:name',
    page: () {
      final name = Get.parameters['name'];
      if (name == null || name.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid community name.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: AddModsScreen(name: name)),
        webScreenLayout: WebScreenLayout(child: AddModsScreen(name: name)),
      );
    },
  ),
  // User Profile Screen
  GetPage(
    name: '/u/:uid',
    page: () {
      final uid = Get.parameters['uid'];
      if (uid == null || uid.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid user id.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: UserProfileScreen(uid: uid)),
        webScreenLayout: WebScreenLayout(child: UserProfileScreen(uid: uid)),
      );
    },
  ),
  // Edit Profile Screen
  GetPage(
    name: '/edit-profile/:uid',
    page: () {
      final uid = Get.parameters['uid'];
      if (uid == null || uid.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid user id.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: EditProfileScreen(uid: uid)),
        webScreenLayout: WebScreenLayout(child: EditProfileScreen(uid: uid)),
      );
    },
  ),
  // Add Post Type Screen
  GetPage(
    name: '/add-post/:type',
    page: () {
      final type = Get.parameters['type'] ?? '';
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: AddPostTypeScreen(type: type)),
        webScreenLayout: WebScreenLayout(child: AddPostTypeScreen(type: type)),
      );
    },
  ),
  // Comments Screen
  GetPage(
    name: '/post/:postId/comments',
    page: () {
      final postId = Get.parameters['postId'] ?? '';
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: CommentsScreen(postId: postId)),
        webScreenLayout: WebScreenLayout(child: CommentsScreen(postId: postId)),
      );
    },
  ),
  // Graph Screen
  GetPage(
    name: '/graph/:postId',
    page: () {
      final postId = Get.parameters['postId'] ?? '';
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: GraphScreen(postId: postId)),
        webScreenLayout: WebScreenLayout(child: GraphScreen(postId: postId)),
      );
    },
  ),
  // Notifications Screen
  GetPage(
    name: '/notifications',
    page: () => ResponsiveLayout(
      mobileScreenLayout:
          MobileScreenLayout(child: const NotificationsScreen()),
      webScreenLayout: WebScreenLayout(child: const NotificationsScreen()),
    ),
  ),
  // Add Thumbnails Screen
  GetPage(
    name: '/add-thumbnails',
    page: () => ResponsiveLayout(
      mobileScreenLayout: MobileScreenLayout(child: const AddThumbnailsPage()),
      webScreenLayout: WebScreenLayout(child: const AddThumbnailsPage()),
    ),
  ),
];
