import 'package:flutter/foundation.dart';

class Community {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final List<String> members;
  final List<String> pendingMembers;
  final List<String> mods;
  final String creatorUid; // ← NEW
  final String campaignThumbnailUrl;
  final String electionThumbnailUrl;
  final bool requiresVerification;

  Community({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    this.pendingMembers = const [],
    required this.members,
    required this.mods,
    required this.creatorUid, // ← NEW
    this.campaignThumbnailUrl = '',
    this.electionThumbnailUrl = '',
    required this.requiresVerification,
  });

  Community copyWith({
    String? id,
    String? name,
    String? banner,
    String? avatar,
    String? bio,
    List<String>? members,
    List<String>? mods,
    String? creatorUid, // ← NEW
    String? campaignThumbnailUrl,
    String? electionThumbnailUrl,
    bool? requiresVerification,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      members: members ?? this.members,
      mods: mods ?? this.mods,
      creatorUid: creatorUid ?? this.creatorUid, // ← NEW
      campaignThumbnailUrl: campaignThumbnailUrl ?? this.campaignThumbnailUrl,
      electionThumbnailUrl: electionThumbnailUrl ?? this.electionThumbnailUrl,
      pendingMembers: pendingMembers,
      requiresVerification: requiresVerification ?? this.requiresVerification,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameLower': name.toLowerCase(),
      'avatar': avatar,
      'bio': bio,
      'members': members,
      'mods': mods,
      'pendingMembers': pendingMembers,
      'creatorUid': creatorUid, // ← NEW
      'campaignThumbnailUrl': campaignThumbnailUrl,
      'electionThumbnailUrl': electionThumbnailUrl,
      'requiresVerification': requiresVerification,
    };
  }

  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      avatar: map['avatar'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      members: List<String>.from(map['members'] ?? []),
      pendingMembers: List<String>.from(map['pendingMembers'] ?? []),
      mods: List<String>.from(map['mods'] ?? []),
      creatorUid: map['creatorUid'] as String? ?? '', // ← NEW
      campaignThumbnailUrl: map['campaignThumbnailUrl'] as String? ?? '',
      electionThumbnailUrl: map['electionThumbnailUrl'] as String? ?? '',
      requiresVerification: map['requiresVerification'] ?? true,
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, avatar: $avatar, bio: $bio, members: $members, mods: $mods, campaignThumbnailUrl: $campaignThumbnailUrl, electionThumbnailUrl: $electionThumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Community &&
        other.id == id &&
        other.name == name &&
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
        avatar.hashCode ^
        bio.hashCode ^
        members.hashCode ^
        mods.hashCode ^
        campaignThumbnailUrl.hashCode ^
        electionThumbnailUrl.hashCode;
  }
}
