import 'dart:io';

import 'package:flutter/foundation.dart';

@immutable
class ProfileData {
  const ProfileData({
    required this.displayName,
    required this.role,
    required this.email,
    required this.phone,
    this.avatarImage,
  });

  final String displayName;
  final String role;
  final String email;
  final String phone;
  final File? avatarImage;

  ProfileData copyWith({
    String? displayName,
    String? role,
    String? email,
    String? phone,
    File? avatarImage,
  }) {
    return ProfileData(
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarImage: avatarImage ?? this.avatarImage,
    );
  }
}

/// Holds the signed-in user's profile fields so the Profile tab and Account
/// Settings screen stay in sync. No profile backend is wired up yet (see
/// CLAUDE.md), so this only lives in memory for the session.
class ProfileController extends ValueNotifier<ProfileData> {
  ProfileController()
    : super(
        const ProfileData(
          displayName: 'Alex Morgan',
          role: 'Owner',
          email: 'alex.morgan@example.com',
          phone: '+1 555 123 4567',
        ),
      );

  void updateDisplayName(String displayName) {
    value = value.copyWith(displayName: displayName);
  }

  void updateAvatarImage(File image) {
    value = value.copyWith(avatarImage: image);
  }

  void updateEmail(String email) {
    value = value.copyWith(email: email);
  }

  void updatePhone(String phone) {
    value = value.copyWith(phone: phone);
  }
}
