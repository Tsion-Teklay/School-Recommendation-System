// Plain-Dart DTOs that mirror the backend's Zod schemas.
//
// We intentionally don't use `freezed`/`json_serializable` codegen yet — the
// surface is small enough that hand-rolled fromJson/toJson is clearer and
// avoids pulling build_runner into the toolchain on day one. If the DTO
// surface grows past ~10 models, swap to codegen.

enum UserRole { parent, schoolAdmin, moeOfficer, moderator }

extension UserRoleX on UserRole {
  /// Wire format. Backend Zod expects SCREAMING_SNAKE.
  String toWire() {
    switch (this) {
      case UserRole.parent:
        return 'PARENT';
      case UserRole.schoolAdmin:
        return 'SCHOOL_ADMIN';
      case UserRole.moeOfficer:
        return 'MOE_OFFICER';
      case UserRole.moderator:
        return 'MODERATOR';
    }
  }

  static UserRole fromWire(String s) {
    switch (s) {
      case 'PARENT':
        return UserRole.parent;
      case 'SCHOOL_ADMIN':
        return UserRole.schoolAdmin;
      case 'MOE_OFFICER':
        return UserRole.moeOfficer;
      case 'MODERATOR':
        return UserRole.moderator;
      default:
        throw ArgumentError('Unknown role: $s');
    }
  }

  String label() {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.schoolAdmin:
        return 'School admin';
      case UserRole.moeOfficer:
        return 'MoE officer';
      case UserRole.moderator:
        return 'Moderator';
    }
  }
}

class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final bool emailVerified;
  final String accountStatus;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.emailVerified,
    required this.accountStatus,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: UserRoleX.fromWire(json['role'] as String),
        emailVerified: (json['emailVerified'] ?? false) as bool,
        accountStatus: (json['accountStatus'] ?? 'ACTIVE') as String,
      );

  AppUser copyWith({String? fullName, String? phone, String? accountStatus}) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      emailVerified: emailVerified,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}

class LoginResult {
  final String token;
  final AppUser user;
  const LoginResult({required this.token, required this.user});
}
