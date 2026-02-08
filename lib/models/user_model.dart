class AppUser {
  final String id;
  final String email;
  final String? companyId;
  final String role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.email,
    this.companyId,
    this.role = 'user',
    this.isActive = true,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      companyId: data['companyId'],
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true, // Default true for existing users
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'companyId': companyId,
      'role': role,
      'isActive': isActive,
    };
  }
}
