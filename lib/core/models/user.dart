/// Matches the backend `UserOut` schema (`GET /auth/me`).
class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.isEmailVerified,
    required this.nativeLanguage,
    required this.targetLanguage,
  });

  final int id;
  final String email;
  final String? fullName;
  final String role; // USER | ADMIN | SUPER_ADMIN
  final String status;
  final bool isEmailVerified;
  final String? nativeLanguage;
  final String? targetLanguage;

  /// A brand-new account must pick a native language before entering the
  /// cabinet (mirrors `routeAfterAuth` in the web `app.js`).
  bool get needsLanguage =>
      nativeLanguage == null || nativeLanguage!.isEmpty;

  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        role: json['role'] as String,
        status: json['status'] as String,
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
        nativeLanguage: json['native_language'] as String?,
        targetLanguage: json['target_language'] as String?,
      );

  /// Only the fields we read back — enough to render the shell offline.
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'status': status,
        'is_email_verified': isEmailVerified,
        'native_language': nativeLanguage,
        'target_language': targetLanguage,
      };
}
