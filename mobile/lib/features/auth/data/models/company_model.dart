class CompanyModel {
  final String id;
  final String name;
  final String cnpj;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cnpj': cnpj,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}