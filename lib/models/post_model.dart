import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String title;
  final String? link;
  final String? description; // used as caption for non-text posts
  final String communityName;
  final String communityProfilePic;
  final int commentCount;
  final String username;
  final String uid;
  final String type;
  final DateTime createdAt;
  final List<String> imageUrls;
  final Map<String, int> userVotes; // for voting
  final List<String> taggedUsers;
  final Map<String, int> imageVotes;
  final int likes; // total like count
  final List<String> likedBy; // list of user IDs who liked this post
  final DateTime? electionEndTime; // NEW: election end time for carousel2 posts

  Post({
    required this.id,
    required this.title,
    this.link,
    this.description,
    required this.communityName,
    required this.communityProfilePic,
    required this.commentCount,
    required this.username,
    required this.uid,
    required this.type,
    required this.createdAt,
    List<String>? imageUrls,
    Map<String, int>? userVotes,
    List<String>? taggedUsers,
    Map<String, int>? imageVotes,
    int? likes,
    List<String>? likedBy,
    this.electionEndTime, // optional: only used for carousel2 posts
  })  : imageUrls = imageUrls ?? [],
        userVotes = userVotes ?? {},
        taggedUsers = taggedUsers ?? [],
        imageVotes = imageVotes ?? {},
        likes = likes ?? 0,
        likedBy = likedBy ?? [];

  Post copyWith({
    String? id,
    String? title,
    String? link,
    String? description,
    String? communityName,
    String? communityProfilePic,
    int? commentCount,
    String? username,
    String? uid,
    String? type,
    DateTime? createdAt,
    List<String>? imageUrls,
    Map<String, int>? userVotes,
    List<String>? taggedUsers,
    Map<String, int>? imageVotes,
    int? likes,
    List<String>? likedBy,
    DateTime? electionEndTime,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      communityName: communityName ?? this.communityName,
      communityProfilePic: communityProfilePic ?? this.communityProfilePic,
      commentCount: commentCount ?? this.commentCount,
      username: username ?? this.username,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      userVotes: userVotes ?? this.userVotes,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      imageVotes: imageVotes ?? this.imageVotes,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      electionEndTime: electionEndTime ?? this.electionEndTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'link': link,
      'description': description,
      'communityName': communityName,
      'communityProfilePic': communityProfilePic,
      'commentCount': commentCount,
      'username': username,
      'uid': uid,
      'type': type,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'imageUrls': imageUrls,
      'userVotes': userVotes,
      'taggedUsers': taggedUsers,
      'imageVotes': imageVotes,
      'likes': likes,
      'likedBy': likedBy,
      'electionEndTime': electionEndTime?.millisecondsSinceEpoch,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'No Title',
      link: map['link'] as String?,
      description: map['description'] as String?,
      communityName: map['communityName'] as String? ?? '',
      communityProfilePic: map['communityProfilePic'] as String? ?? '',
      commentCount: map['commentCount'] as int? ?? 0,
      username: map['username'] as String? ?? 'Unknown',
      uid: map['uid'] as String? ?? '',
      type: map['type'] as String? ?? 'text',
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      imageUrls: (map['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      userVotes: Map<String, int>.from(map['userVotes'] ?? {}),
      taggedUsers: List<String>.from(map['taggedUsers'] ?? []),
      imageVotes: Map<String, int>.from(map['imageVotes'] ?? {}),
      likes: map['likes'] as int? ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      electionEndTime: map['electionEndTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['electionEndTime'] as int)
          : null,
    );
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.link == link &&
        other.description == description &&
        other.communityName == communityName &&
        other.communityProfilePic == communityProfilePic &&
        other.commentCount == commentCount &&
        other.username == username &&
        other.uid == uid &&
        other.type == type &&
        other.createdAt == createdAt &&
        listEquals(other.imageUrls, imageUrls) &&
        mapEquals(other.userVotes, userVotes) &&
        listEquals(other.taggedUsers, taggedUsers) &&
        other.electionEndTime == electionEndTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        link.hashCode ^
        description.hashCode ^
        communityName.hashCode ^
        communityProfilePic.hashCode ^
        commentCount.hashCode ^
        username.hashCode ^
        uid.hashCode ^
        type.hashCode ^
        createdAt.hashCode ^
        imageUrls.hashCode ^
        userVotes.hashCode ^
        taggedUsers.hashCode ^
        electionEndTime.hashCode;
  }
}
