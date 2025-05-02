import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/post_model.dart';
import '../auth/controller/auth_controller.dart';
import '../posts/controller/post_controller.dart';
import 'bar_graph.dart';

class GraphScreen extends StatefulWidget {
  final String postId;
  const GraphScreen({super.key, required this.postId});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<String> taggedUsernames = [];
  bool isLoading = true;
  late final PostController postController;
  late final AuthController authController;
  late final Future<Post> _postFuture;

  @override
  void initState() {
    super.initState();
    postController = Get.find<PostController>();
    authController = Get.find<AuthController>();
    // Store the future so we only call it once.
    _postFuture = postController.getPostById(widget.postId).first;
    fetchTaggedUsernames();
  }

  Future<void> fetchTaggedUsernames() async {
    final post = await _postFuture;
    final List<String> result = [];

    for (int i = 0; i < post.imageUrls.length; i++) {
      if (i < post.taggedUsers.length) {
        final tag = post.taggedUsers[i];

        final isManual = post.taggedNames.contains(tag);
        if (isManual) {
          result.add(tag);
        } else {
          final username = await authController.getUsernameFromUid(tag);
          result.add(username);
        }
      } else {
        result.add("N/A");
      }
    }

    if (!mounted) return;
    setState(() {
      taggedUsernames = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _postFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final post = snapshot.data as Post;
              double totalVotes = 0;
              // Sum up the vote counts.
              for (int i = 0; i < post.imageUrls.length; i++) {
                double count = (post.imageVotes[i.toString()] ?? 0).toDouble();
                totalVotes += count;
              }
              return Text("Total votes: ${totalVotes.toInt()}");
            }
            return const Text("Total votes: ...");
          },
        ),
      ),
      body: FutureBuilder(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = snapshot.data as Post;
          List<double> votes = [];
          // Extract vote counts from the post.
          for (int i = 0; i < post.imageUrls.length; i++) {
            double count = (post.imageVotes[i.toString()] ?? 0).toDouble();
            votes.add(count);
          }
          return isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: MyHorizontalBarGraph(
                              votesSummary: votes,
                              taggedUsers: taggedUsernames,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
