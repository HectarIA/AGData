enum UserRole { superAdmin, admin, operador }

class UserModel {
  final String uid;
  final String? cpf; 
  final String companyId;
  final String name;
  final UserRole role;

  UserModel({
    required this.uid,
    this.cpf,
    required this.companyId,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cpf': cpf,
      'companyId': companyId,
      'name': name,
      'role': role.name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      cpf: map['cpf'],
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.byName(map['role'] ?? 'operador'),
    );
  }
}