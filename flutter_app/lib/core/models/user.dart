enum UserRole { restaurant, client, delivery }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const User({required this.id, required this.name, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere((r) => r.name == json['role']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role.name};
}
