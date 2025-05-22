import 'dart:convert';

import 'package:flutter/foundation.dart';

class UserModel {
  final String name;
  final String bio;
  final String profilePic;
  final String uid;
  final String email;
  final bool isAuthenticated;
  final List<String> blockedUsers;
  final bool? bannedFromCommunities;
  final double balance;
  final bool isAdmin;

  // Bank details fields
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankCode;
  final String? bankName;

  UserModel({
    required this.name,
    required this.bio,
    required this.profilePic,
    required this.uid,
    required this.email,
    required this.isAuthenticated,
    required this.blockedUsers,
    this.bannedFromCommunities,
    this.balance = 0.0,
    this.isAdmin = false,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankCode,
    this.bankName,
  });

  UserModel copyWith({
    String? name,
    String? bio,
    String? profilePic,
    String? uid,
    String? email,
    bool? isAuthenticated,
    List<String>? blockedUsers,
    bool? bannedFromCommunities,
    double? balance,
    bool? isAdmin,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankCode,
    String? bankName,
  }) {
    return UserModel(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePic: profilePic ?? this.profilePic,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      bannedFromCommunities:
          bannedFromCommunities ?? this.bannedFromCommunities,
      balance: balance ?? this.balance,
      isAdmin: isAdmin ?? this.isAdmin,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'bio': bio,
      'profilePic': profilePic,
      'uid': uid,
      'email': email,
      'isAuthenticated': isAuthenticated,
      'blockedUsers': blockedUsers,
      'bannedFromCommunities': bannedFromCommunities ?? false,
      'balance': balance,
      'isAdmin': isAdmin,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'bankCode': bankCode,
      'bankName': bankName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] as String? ?? 'No Name',
      bio: map['bio'] as String? ?? '',
      profilePic: map['profilePic'] as String? ?? 'No Profile Pic',
      uid: map['uid'] as String? ?? 'No UID',
      email: map['email'] as String? ?? '',
      isAuthenticated: map['isAuthenticated'] as bool? ?? false,
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      bannedFromCommunities: map['bannedFromCommunities'] ?? false,
      balance: (map['balance'] != null)
          ? (map['balance'] is int
              ? (map['balance'] as int).toDouble()
              : map['balance'] as double)
          : 0.0,
      isAdmin: map['isAdmin'] as bool? ?? false,
      bankAccountName: map['bankAccountName'] as String?,
      bankAccountNumber: map['bankAccountNumber'] as String?,
      bankCode: map['bankCode'] as String?,
      bankName: map['bankName'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(name: $name, bio: $bio, profilePic: $profilePic, uid: $uid, isAuthenticated: $isAuthenticated, blockedUsers: $blockedUsers, bannedFromCommunities: $bannedFromCommunities, balance: $balance, isAdmin: $isAdmin, bankAccountName: $bankAccountName, bankAccountNumber: $bankAccountNumber, bankCode: $bankCode, bankName: $bankName)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.bio == bio &&
        other.profilePic == profilePic &&
        other.uid == uid &&
        other.isAuthenticated == isAuthenticated &&
        listEquals(other.blockedUsers, blockedUsers) &&
        other.bannedFromCommunities == bannedFromCommunities &&
        other.balance == balance &&
        other.isAdmin == isAdmin &&
        other.bankAccountName == bankAccountName &&
        other.bankAccountNumber == bankAccountNumber &&
        other.bankCode == bankCode &&
        other.bankName == bankName;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        bio.hashCode ^
        profilePic.hashCode ^
        uid.hashCode ^
        isAuthenticated.hashCode ^
        blockedUsers.hashCode ^
        bannedFromCommunities.hashCode ^
        balance.hashCode ^
        isAdmin.hashCode ^
        (bankAccountName?.hashCode ?? 0) ^
        (bankAccountNumber?.hashCode ?? 0) ^
        (bankCode?.hashCode ?? 0) ^
        (bankName?.hashCode ?? 0);
  }
}
