// ============================================
// FILE 6: models/user_model.dart
// ============================================
// Create new file: lib/models/user_model.dart

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? licenseNumber;
  final String? avatarUrl;
  final bool isAdmin;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.licenseNumber,
    this.avatarUrl,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      licenseNumber: json['license_number'],
      avatarUrl: json['avatar_url'],
      isAdmin: json['is_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'license_number': licenseNumber,
      'avatar_url': avatarUrl,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName => fullName ?? email.split('@')[0];
  String get initials => displayName.substring(0, 1).toUpperCase();
}