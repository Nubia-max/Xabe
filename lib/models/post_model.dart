import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String title;
  final String? link;
  final String? description;
  final String communityName;
  final String communityId;
  final String communityProfilePic;
  final int commentCount;
  final String username;
  final String uid;
  final String type;
  final DateTime createdAt;
  final List<String> imageUrls;
  final Map<String, List<int>> userVotes;
  final List<String> taggedUsers;
  final Map<String, int> imageVotes;
  final int likes;
  final List<String> likedBy;
  final DateTime? electionEndTime;
  final List<String> taggedNames;
  final List<String> taggedUids;
  final bool showLiveResults;
  final int pricePerVote;
  final int maxVotesPerPerson;

  Post({
    required this.id,
    required this.title,
    this.link,
    this.description,
    required this.communityName,
    required this.communityId,
    required this.communityProfilePic,
    required this.commentCount,
    required this.username,
    required this.uid,
    required this.type,
    required this.createdAt,
    required this.showLiveResults,
    this.pricePerVote = 0,
    this.maxVotesPerPerson = 1,
    List<String>? imageUrls,
    Map<String, List<int>>? userVotes,
    List<String>? taggedUsers,
    List<String>? taggedNames,
    List<String>? taggedUids,
    Map<String, int>? imageVotes,
    int? likes,
    List<String>? likedBy,
    this.electionEndTime,
  })  : imageUrls = imageUrls ?? [],
        userVotes = userVotes ?? {},
        taggedUsers = taggedUsers ?? [],
        taggedNames = taggedNames ?? [],
        taggedUids = taggedUids ?? [],
        imageVotes = imageVotes ?? {},
        likes = likes ?? 0,
        likedBy = likedBy ?? [];

  Post copyWith({
    String? id,
    String? title,
    String? link,
    String? description,
    String? communityName,
    String? communityId,
    String? communityProfilePic,
    int? commentCount,
    String? username,
    String? uid,
    String? type,
    DateTime? createdAt,
    List<String>? imageUrls,
    List<String>? taggedNames,
    List<String>? taggedUids,
    Map<String, List<int>>? userVotes,
    List<String>? taggedUsers,
    Map<String, int>? imageVotes,
    int? likes,
    List<String>? likedBy,
    DateTime? electionEndTime,
    bool? showLiveResults,
    int? pricePerVote,
    int? maxVotesPerPerson,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      communityName: communityName ?? this.communityName,
      communityId: communityId ?? this.communityId,
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
      taggedNames: taggedNames ?? this.taggedNames,
      taggedUids: taggedUids ?? this.taggedUids,
      showLiveResults: showLiveResults ?? this.showLiveResults,
      pricePerVote: pricePerVote ?? this.pricePerVote,
      maxVotesPerPerson: maxVotesPerPerson ?? this.maxVotesPerPerson,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'link': link,
      'description': description,
      'communityName': communityName,
      'communityId': communityId,
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
      'taggedNames': taggedNames,
      'taggedUids': taggedUids,
      'showLiveResults': showLiveResults,
      'pricePerVote': pricePerVote,
      'maxVotesPerPerson': maxVotesPerPerson,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    final rawUserVotes = map['userVotes'] ?? {};
    final parsedUserVotes = <String, List<int>>{};

    (rawUserVotes as Map<String, dynamic>).forEach((key, value) {
      if (value is List) {
        parsedUserVotes[key] = List<int>.from(value);
      } else {
        parsedUserVotes[key] = [value as int];
      }
    });

    return Post(
      id: map['id'] ?? '',
      title: map['title'] ?? 'No Title',
      link: map['link'],
      description: map['description'],
      communityName: map['communityName'] ?? '',
      communityId: map['communityId'] ?? '',
      communityProfilePic: map['communityProfilePic'] ?? '',
      commentCount: map['commentCount'] ?? 0,
      username: map['username'] ?? 'Unknown',
      uid: map['uid'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      userVotes: parsedUserVotes,
      taggedUsers: List<String>.from(map['taggedUsers'] ?? []),
      imageVotes: Map<String, int>.from(map['imageVotes'] ?? {}),
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      taggedNames: List<String>.from(map['taggedNames'] ?? []),
      taggedUids: List<String>.from(map['taggedUids'] ?? []),
      electionEndTime: map['electionEndTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['electionEndTime'])
          : null,
      showLiveResults: map['showLiveResults'] ?? false,
      pricePerVote: map['pricePerVote'] ?? 0,
      maxVotesPerPerson: map['maxVotesPerPerson'] ?? 1,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Post &&
            id == other.id &&
            title == other.title &&
            link == other.link &&
            description == other.description &&
            communityName == other.communityName &&
            communityId == other.communityId &&
            communityProfilePic == other.communityProfilePic &&
            commentCount == other.commentCount &&
            username == other.username &&
            uid == other.uid &&
            type == other.type &&
            createdAt == other.createdAt &&
            listEquals(imageUrls, other.imageUrls) &&
            mapEquals(userVotes, other.userVotes) &&
            listEquals(taggedUsers, other.taggedUsers) &&
            mapEquals(imageVotes, other.imageVotes) &&
            likes == other.likes &&
            listEquals(likedBy, other.likedBy) &&
            electionEndTime == other.electionEndTime &&
            listEquals(taggedNames, other.taggedNames) &&
            listEquals(taggedUids, other.taggedUids) &&
            showLiveResults == other.showLiveResults &&
            pricePerVote == other.pricePerVote &&
            maxVotesPerPerson == other.maxVotesPerPerson);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        link.hashCode ^
        description.hashCode ^
        communityName.hashCode ^
        communityId.hashCode ^
        communityProfilePic.hashCode ^
        commentCount.hashCode ^
        username.hashCode ^
        uid.hashCode ^
        type.hashCode ^
        createdAt.hashCode ^
        imageUrls.hashCode ^
        userVotes.hashCode ^
        taggedUsers.hashCode ^
        imageVotes.hashCode ^
        likes.hashCode ^
        likedBy.hashCode ^
        electionEndTime.hashCode ^
        taggedNames.hashCode ^
        taggedUids.hashCode ^
        showLiveResults.hashCode ^
        pricePerVote.hashCode ^
        maxVotesPerPerson.hashCode;
  }
}
