enum UserRole { superAdmin, admin, operador }

class UserModel {
  final String uid;
  final String? cpf; 
  final String email; // Adicionado: Campo obrigatório para o novo fluxo
  final String companyId;
  final String name;
  final UserRole role;

  UserModel({
    required this.uid,
    this.cpf,
    required this.email, // Adicionado
    required this.companyId,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cpf': cpf,
      'email': email, // Adicionado
      'companyId': companyId,
      'name': name,
      'role': role.name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      cpf: map['cpf'],
      email: map['email'] ?? '', // Adicionado
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      // Tratamento para garantir que não quebre se o nome no banco for diferente
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.operador,
      ),
    );
  }
}