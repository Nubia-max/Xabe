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
  final List<String> bannedUsers;
  final String communityType;
  final double balance;

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
    this.bannedUsers = const [],
    this.communityType = 'regular',
    this.balance = 0.0,
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
    List<String>? pendingMembers,
    List<String>? bannedUsers,
    String? communityType,
    double? balance,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      members: members ?? this.members,
      mods: mods ?? this.mods,
      creatorUid: creatorUid ?? this.creatorUid,
      campaignThumbnailUrl: campaignThumbnailUrl ?? this.campaignThumbnailUrl,
      electionThumbnailUrl: electionThumbnailUrl ?? this.electionThumbnailUrl,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      pendingMembers: pendingMembers ?? this.pendingMembers,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      communityType:
          communityType ?? this.communityType, // Use provided or current
      balance: balance ?? this.balance,
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
      'bannedUsers': bannedUsers,
      'communityType': communityType,
      'balance': balance,
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
      bannedUsers: List<String>.from(map['bannedUsers'] ?? []),
      communityType: map['communityType'] as String? ?? 'regular',
      balance: (map['balance'] != null)
          ? (map['balance'] is int
              ? (map['balance'] as int).toDouble()
              : map['balance'] as double)
          : 0.0,
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
        other.electionThumbnailUrl == electionThumbnailUrl &&
        other.communityType == communityType &&
        other.balance == balance;
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
        electionThumbnailUrl.hashCode ^
        communityType.hashCode ^
        balance.hashCode;
  }
}
