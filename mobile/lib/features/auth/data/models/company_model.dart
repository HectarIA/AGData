import 'package:cloud_firestore/cloud_firestore.dart';

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
      'createdAt': createdAt, // O Firebase aceita DateTime direto para salvar como Timestamp
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cnpj: map['cnpj'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(), // Converte Timestamp para DateTime
    );
  }
}