import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:xabe/core/constants/firebase_constants.dart';
import 'package:xabe/core/failure.dart';
import 'package:xabe/models/comment_model.dart';
import 'package:xabe/models/community_model.dart';
import 'package:xabe/models/post_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore;
  PostRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);

  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);

  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  Future<void> updatePost(Post post) async {
    await _firestore.collection('posts').doc(post.id).update(post.toMap());
  }

  Future<Community> getCommunityByNameFuture(String name) async {
    final doc = await _firestore
        .collection(FirebaseConstants.communitiesCollection)
        .doc(name)
        .get();
    if (doc.exists && doc.data() != null) {
      return Community.fromMap(doc.data() as Map<String, dynamic>);
    }
    throw Exception("Community not found");
  }

  Future<Either<Failure, void>> voteForCandidate(
      String postId, int index, String uid) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'userVotes.$uid': index,
      });
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<Post> getPostById(String postId) {
    return _posts
        .doc(postId)
        .snapshots()
        .map((event) => Post.fromMap(event.data() as Map<String, dynamic>));
  }

  Future<Post?> getPostByIdFuture(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (doc.exists) {
      return Post.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<Either<Failure, void>> addPost(Post post) async {
    try {
      await _firestore.collection('posts').doc(post.id).set(post.toMap());
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<Post>> fetchUserPosts(List<Community> communities) {
    return _posts
        .where('communityName',
            whereIn: communities.map((e) => e.name).toList())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((e) => Post.fromMap(e.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Post>> fetchGuestPosts() {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((event) => event.docs
            .map((e) => Post.fromMap(e.data() as Map<String, dynamic>))
            .toList());
  }

  Future<Either<Failure, void>> deletePost(Post post) async {
    try {
      return right(_posts.doc(post.id).delete());
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<void> updatePostField({
    required String postId,
    required String field,
    required dynamic value,
  }) async {
    await _firestore.collection('posts').doc(postId).update({field: value});
  }

  Future<Either<Failure, void>> addComment(Comment comment) async {
    try {
      await _comments.doc(comment.id).set(comment.toMap());
      return right(_posts.doc(comment.postId).update({
        'commentCount': FieldValue.increment(1),
      }));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Stream<List<Comment>> getCommentsOfPost(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((e) => Comment.fromMap(e.data() as Map<String, dynamic>))
            .toList());
  }
}
