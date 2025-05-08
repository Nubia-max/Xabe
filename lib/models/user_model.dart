import 'dart:convert';

import 'package:flutter/foundation.dart';

class UserModel {
  final String name;
  final String bio; // New field
  final String profilePic;
  final String uid;
  final bool isAuthenticated;
  final List<String> blockedUsers; // New field to store blocked user IDs

  UserModel({
    required this.name,
    required this.bio, // Added to constructor
    required this.profilePic,
    required this.uid,
    required this.isAuthenticated,
    required this.blockedUsers, // Add blockedUsers in the constructor
  });

  UserModel copyWith({
    String? name,
    String? bio,
    String? profilePic,
    String? uid,
    bool? isAuthenticated,
    List<String>? blockedUsers, // Add blockedUsers to copyWith
  }) {
    return UserModel(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePic: profilePic ?? this.profilePic,
      uid: uid ?? this.uid,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      blockedUsers:
          blockedUsers ?? this.blockedUsers, // Handle blockedUsers here
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'bio': bio, // Added here
      'profilePic': profilePic,
      'uid': uid,
      'isAuthenticated': isAuthenticated,
      'blockedUsers': blockedUsers, // Add blockedUsers to the map
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] as String? ?? 'No Name',
      bio: map['bio'] as String? ??
          '', // Default to empty string if not provided
      profilePic: map['profilePic'] as String? ?? 'No Profile Pic',
      uid: map['uid'] as String? ?? 'No UID',
      isAuthenticated: map['isAuthenticated'] as bool? ?? false,
      blockedUsers:
          List<String>.from(map['blockedUsers'] ?? []), // Parse blockedUsers
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(name: $name, bio: $bio, profilePic: $profilePic, uid: $uid, isAuthenticated: $isAuthenticated, blockedUsers: $blockedUsers)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.bio == bio &&
        other.profilePic == profilePic &&
        other.uid == uid &&
        other.isAuthenticated == isAuthenticated &&
        listEquals(other.blockedUsers, blockedUsers); // Compare blockedUsers
  }

  @override
  int get hashCode {
    return name.hashCode ^
        bio.hashCode ^
        profilePic.hashCode ^
        uid.hashCode ^
        isAuthenticated.hashCode ^
        blockedUsers.hashCode; // Include blockedUsers in hashCode
  }
}
