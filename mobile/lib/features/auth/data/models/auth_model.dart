enum UserRole { superAdmin, admin, operador }

class UserModel {
  final String uid;
  final String? cpf; 
  final String email;
  final String companyId;
  final String name;
  final UserRole role;
  final bool needsPasswordChange; // Flag para primeiro acesso

  UserModel({
    required this.uid,
    this.cpf,
    required this.email,
    required this.companyId,
    required this.name,
    required this.role,
    this.needsPasswordChange = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cpf': cpf,
      'email': email,
      'companyId': companyId,
      'name': name,
      'role': role.name,
      'needsPasswordChange': needsPasswordChange,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      cpf: map['cpf'],
      email: map['email'] ?? '',
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      needsPasswordChange: map['needsPasswordChange'] ?? false,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.operador,
      ),
    );
  }
}