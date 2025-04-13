import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/constants/constants.dart';
import 'package:xabe/features/home/delegates/search_community_delegate.dart';
import 'package:xabe/features/home/drawers/community_list_drawer.dart';
import 'package:xabe/features/home/drawers/profile_drawer.dart';
import 'package:xabe/features/notifications/notification_controller.dart';
import 'package:xabe/features/auth/controller/auth_controller.dart';
import 'package:xabe/features/home/widgets/community_card.dart';
import '../../community/controller/community_controller.dart';
import '../../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  void displayDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void displayEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // When the title ("Xabe") is tapped, navigate to notifications.
  void onTitleTap() {
    // Clear notifications when navigating.
    Get.find<NotificationController>().markNotificationsAsSeen();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        return NetworkImage(imageUrl);
      } else {
        return CachedNetworkImageProvider(imageUrl);
      }
    } else {
      return AssetImage(imageUrl);
    }
  }

  // Build a mini search bar widget that adapts its text based on available width.
  Widget buildMiniSearchBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine overall screen width using MediaQuery
        double screenWidth = MediaQuery.of(context).size.width;
        // If the screen is too narrow, show a shorter text.
        bool showFullText = screenWidth > 400;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              showSearch(context: context, delegate: SearchCommunityDelegate());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    showFullText ? 'Search association' : 'Search',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build the notification count red dot to overlay above the title text.
  Widget buildTitleWithNotification() {
    return Tooltip(
      message: 'notifications',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTitleTap,
          child: Obx(() {
            int unreadCount = Get.find<NotificationController>()
                .notifications
                .where((n) => !n.isProcessed)
                .length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  'Xabe',
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -16,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // Build the communities view.
  Widget buildCommunities() {
    final communityController = Get.find<CommunityController>();
    return StreamBuilder<List>(
      stream: communityController.getUserCommunitiesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final communities = snapshot.data!;
        if (communities.isEmpty) {
          return const Center(child: Text('No associations found.'));
        }
        return ListView.builder(
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return CommunityCard(community: community);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.userModel.value;
    final bool isGuest = user == null || !user.isAuthenticated;
    final currentTheme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: currentTheme.appBarTheme.backgroundColor,
        title: buildTitleWithNotification(),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: displayDrawer,
        ),
        actions: [
          // Always show the responsive mini search bar.
          buildMiniSearchBar(),
          IconButton(
            icon: CircleAvatar(
              backgroundImage: getImageProvider(user?.profilePic ?? ''),
            ),
            onPressed: displayEndDrawer,
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(
            color: Theme.of(context).dividerColor,
            thickness: 1,
            height: 1,
          ),
          Expanded(
            child: buildCommunities(),
          ),
        ],
      ),
      drawer: const CommunityListDrawer(),
      endDrawer: isGuest ? null : const ProfileDrawer(),
    );
  }
}
