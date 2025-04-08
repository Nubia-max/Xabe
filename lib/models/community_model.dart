import 'package:flutter/foundation.dart';

class Community {
  final String id;
  final String name;
  final String banner;
  final String avatar;
  final String bio; // New field for bio
  final List<String> members;
  final List<String> pendingMembers;
  final List<String> mods;
  final String campaignThumbnailUrl; // New field for campaign thumbnail
  final String electionThumbnailUrl; // New field for election thumbnail

  Community({
    required this.id,
    required this.name,
    required this.banner,
    required this.avatar,
    required this.bio,
    this.pendingMembers = const [],
    required this.members,
    required this.mods,
    this.campaignThumbnailUrl = '',
    this.electionThumbnailUrl = '',
  });

  Community copyWith({
    String? id,
    String? name,
    String? banner,
    String? avatar,
    String? bio,
    List<String>? members,
    List<String>? mods,
    String? campaignThumbnailUrl,
    String? electionThumbnailUrl,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      banner: banner ?? this.banner,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      members: members ?? this.members,
      mods: mods ?? this.mods,
      campaignThumbnailUrl: campaignThumbnailUrl ?? this.campaignThumbnailUrl,
      electionThumbnailUrl: electionThumbnailUrl ?? this.electionThumbnailUrl,
      pendingMembers: pendingMembers, // remains unchanged
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'banner': banner,
      'nameLower': name.toLowerCase(), // added for case-insensitive search
      'avatar': avatar,
      'bio': bio, // Include bio in the map
      'members': members,
      'mods': mods,
      'pendingMembers': pendingMembers,
      'campaignThumbnailUrl': campaignThumbnailUrl,
      'electionThumbnailUrl': electionThumbnailUrl,
    };
  }

  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      banner: map['banner'] as String? ?? '',
      avatar: map['avatar'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      members: List<String>.from(map['members'] ?? []),
      pendingMembers: List<String>.from(map['pendingMembers'] ?? []),
      mods: List<String>.from(map['mods'] ?? []),
      campaignThumbnailUrl: map['campaignThumbnailUrl'] as String? ?? '',
      electionThumbnailUrl: map['electionThumbnailUrl'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, banner: $banner, avatar: $avatar, bio: $bio, members: $members, mods: $mods, campaignThumbnailUrl: $campaignThumbnailUrl, electionThumbnailUrl: $electionThumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Community &&
        other.id == id &&
        other.name == name &&
        other.banner == banner &&
        other.avatar == avatar &&
        other.bio == bio &&
        listEquals(other.members, members) &&
        listEquals(other.mods, mods) &&
        other.campaignThumbnailUrl == campaignThumbnailUrl &&
        other.electionThumbnailUrl == electionThumbnailUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        banner.hashCode ^
        avatar.hashCode ^
        bio.hashCode ^
        members.hashCode ^
        mods.hashCode ^
        campaignThumbnailUrl.hashCode ^
        electionThumbnailUrl.hashCode;
  }
}
