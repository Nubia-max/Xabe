import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xabe/core/common/error_text.dart';
import 'package:xabe/core/common/loader.dart';
import 'package:xabe/core/post_card.dart';
import 'package:xabe/models/post_model.dart';

import '../../auth/controller/auth_controller.dart';
import '../controller/post_controller.dart';
import '../widgets/comment_card.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  void addComment(Post post) {
    Get.find<PostController>().addComment(
      context: context,
      text: commentController.text.trim(),
      post: post,
    );
    setState(() {
      commentController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.userModel.value;
    final bool isGuest = user == null || !user.isAuthenticated;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(),
      body: StreamBuilder<Post>(
        stream: Get.find<PostController>().getPostById(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Loader();
          }
          final post = snapshot.data!;
          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      PostCard(post: post),
                      if (!isGuest)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onSubmitted: (val) => addComment(post),
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'What are your thoughts?',
                              filled: true,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              body: StreamBuilder<List>(
                stream:
                    Get.find<PostController>().fetchPostComments(widget.postId),
                builder: (context, commentSnapshot) {
                  if (commentSnapshot.hasError) {
                    return ErrorText(error: commentSnapshot.error.toString());
                  }
                  if (!commentSnapshot.hasData) {
                    return const Loader();
                  }
                  final comments = commentSnapshot.data!;
                  return comments.isEmpty
                      ? const Center(child: Text('No comments yet'))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return CommentCard(comment: comment);
                          },
                        );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
