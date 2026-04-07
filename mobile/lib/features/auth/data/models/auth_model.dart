enum UserRole { superAdmin, admin, operador }

class UserModel {
  final String uid;
  final String? cpf; 
  final String email;
  final String companyId;
  final String name;
  final UserRole role;
  final bool needsPasswordChange;

  UserModel({
    required this.uid,
    this.cpf,
    required this.email,
    required this.companyId,
    required this.name,
    required this.role,
    this.needsPasswordChange = false,
  });

  // --- ADICIONE ESTE MÉTODO ABAIXO ---
  UserModel copyWith({
    String? uid,
    String? cpf,
    String? email,
    String? companyId,
    String? name,
    UserRole? role,
    bool? needsPasswordChange,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      role: role ?? this.role,
      needsPasswordChange: needsPasswordChange ?? this.needsPasswordChange,
    );
  }
  // ----------------------------------

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