class UserModel {
  final User? user;
  final String? accessToken;
  final String? refreshToken;

  UserModel({this.user, this.accessToken, this.refreshToken});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    return data;
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final bool isActive;
  final String? department;
  final String? image;
  final String? lastLogin;
  final String? lastAssignedAt;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    required this.isActive,
    this.department,
    this.image,
    this.lastLogin,
    this.lastAssignedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      phone: json['phone'],
      isActive: json['isActive'] ?? false,
      department: json['department'],
      image: json['image'],
      lastLogin: json['lastLogin'],
      lastAssignedAt: json['lastAssignedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['email'] = email;
    data['name'] = name;
    data['role'] = role;
    data['phone'] = phone;
    data['isActive'] = isActive;
    data['department'] = department;
    data['image'] = image;
    data['lastLogin'] = lastLogin;
    data['lastAssignedAt'] = lastAssignedAt;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
