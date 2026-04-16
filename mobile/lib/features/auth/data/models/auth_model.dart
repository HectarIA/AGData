import 'package:isar/isar.dart';

part 'auth_model.g.dart';

enum UserRole { superAdmin, admin, operador }

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;
  
  String? cpf;
  String? phone; 
  late String email;
  late String companyId;
  late String name;

  @enumerated
  late UserRole role;
  
  late bool needsPasswordChange;
  
  UserModel();

  UserModel.create({
    required this.uid,
    this.cpf,
    this.phone,
    required this.email,
    required this.companyId,
    required this.name,
    required this.role,
    this.needsPasswordChange = false,
  });

  UserModel copyWith({
    String? uid,
    String? cpf,
    String? phone,
    String? email,
    String? companyId,
    String? name,
    UserRole? role,
    bool? needsPasswordChange,
  }) {
    return UserModel.create(
      uid: uid ?? this.uid,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      role: role ?? this.role,
      needsPasswordChange: needsPasswordChange ?? this.needsPasswordChange,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cpf': cpf,
      'phone': phone,
      'email': email,
      'companyId': companyId,
      'name': name,
      'role': role.name,
      'needsPasswordChange': needsPasswordChange,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.create(
      uid: map['uid'] ?? '',
      cpf: map['cpf'],
      phone: map['phone'],
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