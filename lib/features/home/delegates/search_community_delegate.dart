import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';

import '../../community/controller/community_controller.dart';

class SearchCommunityDelegate extends SearchDelegate {
  // Access the CommunityController via Get.find.
  final CommunityController communityController =
      Get.find<CommunityController>();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.close),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      // Return an empty container when the search query is empty.
      return Container();
    }

    // When there is text in the search bar, show the community suggestions.
    return StreamBuilder<List>(
      stream: communityController.searchCommunity(query),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorText(error: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Loader();
        }
        final communities = snapshot.data!;
        if (communities.isEmpty) {
          return const Center(
            child: Text('no association found'),
          );
        }
        return ListView.builder(
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: getImageProvider(community.avatar),
              ),
              title: Text(community.name),
              onTap: () => navigateToCommunity(community.name),
            );
          },
        );
      },
    );
  }

  void navigateToCommunity(String communityName) async {
    await Get.toNamed('/X/${communityName}',
        parameters: {'filter': 'All Posts'});
  }

  ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      if (kIsWeb) {
        // On web, use NetworkImage.
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
