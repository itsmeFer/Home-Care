class RoleModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isDefault;
  final int usersCount;

  RoleModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.isDefault,
    required this.usersCount,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      isDefault: (json['is_default'] ?? 0) == 1,
      usersCount: (json['users_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'is_default': isDefault ? 1 : 0,
      'users_count': usersCount,
    };
  }

  String get inisial {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class UserSummary {
  final int id;
  final String name;
  final String email;
  final int? roleId;

  UserSummary({
    required this.id,
    required this.name,
    required this.email,
    this.roleId,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleId: json['role_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role_id': roleId,
    };
  }
}

class AssignFormData {
  final List<RoleModel> roles;
  final List<UserSummary> users;

  AssignFormData({required this.roles, required this.users});

  factory AssignFormData.fromJson(Map<String, dynamic> json) {
    final rolesJson = (json['roles'] ?? []) as List<dynamic>;
    final usersJson = (json['users'] ?? []) as List<dynamic>;

    return AssignFormData(
      roles: rolesJson
          .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      users: usersJson
          .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
