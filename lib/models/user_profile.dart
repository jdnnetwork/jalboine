enum UserRole { senior, guardian }

class UserProfile {
  final String userId;
  final UserRole role;
  final String? name;
  final String? phone;

  const UserProfile({
    required this.userId,
    required this.role,
    this.name,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        userId: j['user_id'] as String,
        role: j['role'] == 'guardian' ? UserRole.guardian : UserRole.senior,
        name: j['name'] as String?,
        phone: j['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role.name,
        'name': name,
        'phone': phone,
      };
}
