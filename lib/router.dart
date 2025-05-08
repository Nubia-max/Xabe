import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:xabe/features/auth/screens/login_screen.dart';
import 'package:xabe/features/community/screens/add_mods_screen.dart';
import 'package:xabe/features/community/screens/community_screen.dart';
import 'package:xabe/features/community/screens/create_community_screen.dart';
import 'package:xabe/features/community/screens/edit_community_screen.dart';
import 'package:xabe/features/community/screens/mod_tools_screen.dart';
import 'package:xabe/features/home/screens/home_screen.dart';
import 'package:xabe/features/posts/screens/add_post_type_screen.dart';
import 'package:xabe/features/posts/screens/comments_screen.dart';
import 'package:xabe/features/posts/screens/full_screen_image.dart';
import 'package:xabe/features/graph/graph_screen.dart';
import 'package:xabe/features/notifications/notification_screen.dart';
import 'package:xabe/features/user_profile/screens/edit_profile_screen.dart';
import 'package:xabe/features/user_profile/screens/user_profile_screen.dart';
import 'package:xabe/responsive/mobile_screen_layout.dart';
import 'package:xabe/responsive/responsive_layout.dart';
import 'package:xabe/responsive/web_screen_layout.dart';

import '../models/post_model.dart';
import 'core/terms_screen.dart';
import 'features/community/controller/community_controller.dart';
import 'features/home/delegates/blocked_users_screen.dart';
import 'features/home/widgets/add_thumbnails.dart';

final List<GetPage> appRoutes = [
  // Login Screen
  GetPage(
    name: '/login',
    page: () => const LoginScreen(),
  ),

  // Home Screen
  GetPage(
    name: '/',
    page: () => ResponsiveLayout(
      mobileScreenLayout: MobileScreenLayout(child: const HomeScreen()),
      webScreenLayout: WebScreenLayout(child: const HomeScreen()),
    ),
  ),

  // Blocked Users Screen
  GetPage(
    name: '/blocked-users',
    page: () => const BlockedUsersScreen(),
  ),

  // TermsScreen (Add route for EULA agreement flow)
  GetPage(
    name: '/terms',
    page: () => TermsScreen(onAgreed: () {
      // Navigate to the main app content once terms are agreed
      Get.offAllNamed('/'); // Navigate to the home screen
    }),
  ),

  // Create Community Screen
  GetPage(
    name: '/create-community',
    page: () => ResponsiveLayout(
      mobileScreenLayout:
          MobileScreenLayout(child: const CreateCommunityScreen()),
      webScreenLayout: WebScreenLayout(child: const CreateCommunityScreen()),
    ),
  ),

// Community Screen (uses ID)
  GetPage(
    name: '/X/:id',
    page: () {
      final id = Get.parameters['id'];
      final filter = Get.parameters['filter'] ?? '';
      if (id == null || id.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid community ID.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout: MobileScreenLayout(
            child: CommunityScreen(communityId: id, filter: filter)),
        webScreenLayout: WebScreenLayout(
            child: CommunityScreen(communityId: id, filter: filter)),
      );
    },
  ),

  // Mod Tools Screen
  GetPage(
    name: '/mod-tools/:id',
    page: () {
      final id = Get.parameters['id'];
      if (id == null || id.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid community ID.")),
        );
      }
      final communityController = Get.find<CommunityController>();
      return StreamBuilder(
        stream: communityController.getCommunityById(id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ResponsiveLayout(
            mobileScreenLayout: MobileScreenLayout(
                child: ModToolsScreen(community: snapshot.data!)),
            webScreenLayout: WebScreenLayout(
                child: ModToolsScreen(community: snapshot.data!)),
          );
        },
      );
    },
  ),

  // Edit Community Screen
  GetPage(
    name: '/edit-community/:id',
    page: () {
      final id = Get.parameters['id'];
      if (id == null || id.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid community ID.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: EditCommunityScreen(communityId: id)),
        webScreenLayout:
            WebScreenLayout(child: EditCommunityScreen(communityId: id)),
      );
    },
  ),

  // Add Moderators Screen
  GetPage(
    name: '/add-mods/:id',
    page: () {
      final id = Get.parameters['id'];
      if (id == null || id.isEmpty) {
        return const Scaffold(
          body: Center(child: Text("Invalid community ID.")),
        );
      }
      return ResponsiveLayout(
        mobileScreenLayout:
            MobileScreenLayout(child: AddModsScreen(communityId: id)),
        webScreenLayout: WebScreenLayout(child: AddModsScreen(communityId: id)),
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

  // Full-Screen Image Viewer
  GetPage(
    name: '/full-screen-image',
    page: () {
      final args = Get.arguments as Map<String, dynamic>;
      return FullScreenImagePage(
        post: args['post'] as Post,
        initialPage: args['initialPage'] as int,
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
