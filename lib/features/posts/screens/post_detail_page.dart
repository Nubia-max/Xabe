import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostDetailPage extends StatelessWidget {
  final String contentType;
  final String contentId;

  const PostDetailPage({
    Key? key,
    required this.contentType,
    required this.contentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docRef =
        FirebaseFirestore.instance.collection(contentType).doc(contentId);

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Post not found.'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['title'] != null &&
                    data['title'].toString().isNotEmpty)
                  Text(data['title'],
                      style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (data['description'] != null &&
                    data['description'].toString().isNotEmpty)
                  Text(data['description']),
                const SizedBox(height: 16),
                if (data['imageUrls'] != null)
                  ...List<Widget>.from(
                    (data['imageUrls'] as List<dynamic>).map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(url as String),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Flags: ${data['flagCount'] ?? 0}'),
                // … add any other fields you want …
              ],
            ),
          );
        },
      ),
    );
  }
}
