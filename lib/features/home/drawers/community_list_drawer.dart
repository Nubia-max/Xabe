import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/core/common/sign_in_button.dart';
import 'package:xabe/models/community_model.dart';

import '../../auth/controller/auth_controller.dart';
import '../../community/controller/community_controller.dart';

class CommunityListDrawer extends StatelessWidget {
  const CommunityListDrawer({super.key});

  void navigateToCreateCommunity() async {
    await Get.toNamed('/create-community');
  }

  void navigateToCommunity(Community community) async {
    await Get.toNamed('/X/${community.id}',
        parameters: {'filter': 'All Posts'});
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.userModel.value;
    final bool isGuest = user == null || !user.isAuthenticated;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            isGuest
                ? const SignInButton(isFromLogin: false)
                : ListTile(
                    title: const Text('Create Community'),
                    leading: const Icon(Icons.add),
                    onTap: navigateToCreateCommunity,
                  ),
            if (!isGuest)
              // Assuming CommunityController.getUserCommunities() returns a Stream<List<Community>>
              StreamBuilder<List>(
                stream:
                    Get.find<CommunityController>().getUserCommunitiesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorText(error: snapshot.error.toString());
                  }
                  if (!snapshot.hasData) {
                    return const Loader();
                  }
                  final communities = snapshot.data!;
                  return Expanded(
                    child: ListView.builder(
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: getImageProvider(community.avatar),
                          ),
                          title: Text(community.name),
                          onTap: () => navigateToCommunity(community),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        // On web, use NetworkImage
        return NetworkImage(imageUrl);
      } else {
        // For mobile builds, use CachedNetworkImageProvider.
        return CachedNetworkImageProvider(imageUrl);
      }
    } else {
      return AssetImage(imageUrl);
    }
  }
}
