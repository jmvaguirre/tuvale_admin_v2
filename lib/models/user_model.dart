class AppUser {
  final String id;
  final String email;
  final String? companyId;
  final String role;

  const AppUser({
    required this.id,
    required this.email,
    this.companyId,
    this.role = 'user',
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      companyId: data['companyId'],
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'companyId': companyId,
      'role': role,
    };
  }
}
