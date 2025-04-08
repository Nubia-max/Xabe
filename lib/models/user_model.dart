import 'dart:convert';

class UserModel {
  final String name;
  final String bio; // New field
  final String profilePic;
  final String banner;
  final String uid;
  final bool isAuthenticated;

  UserModel({
    required this.name,
    required this.bio, // Added to constructor
    required this.profilePic,
    required this.banner,
    required this.uid,
    required this.isAuthenticated,
  });

  UserModel copyWith({
    String? name,
    String? bio,
    String? profilePic,
    String? banner,
    String? uid,
    bool? isAuthenticated,
  }) {
    return UserModel(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePic: profilePic ?? this.profilePic,
      banner: banner ?? this.banner,
      uid: uid ?? this.uid,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'bio': bio, // Added here
      'profilePic': profilePic,
      'banner': banner,
      'uid': uid,
      'isAuthenticated': isAuthenticated,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] as String? ?? 'No Name',
      bio: map['bio'] as String? ??
          '', // Default to empty string if not provided
      profilePic: map['profilePic'] as String? ?? 'No Profile Pic',
      banner: map['banner'] as String? ?? 'No Banner',
      uid: map['uid'] as String? ?? 'No UID',
      isAuthenticated: map['isAuthenticated'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(name: $name, bio: $bio, profilePic: $profilePic, banner: $banner, uid: $uid, isAuthenticated: $isAuthenticated)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.bio == bio &&
        other.profilePic == profilePic &&
        other.banner == banner &&
        other.uid == uid &&
        other.isAuthenticated == isAuthenticated;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        bio.hashCode ^
        profilePic.hashCode ^
        banner.hashCode ^
        uid.hashCode ^
        isAuthenticated.hashCode;
  }
}
