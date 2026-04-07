import 'package:isar/isar.dart';
part 'talhao_model.g.dart'; 

@collection
class TalhaoModel {
  Id id = Isar.autoIncrement;

  late String nome;
  
  @Index() // Adicionando índice para buscas mais rápidas por empresa
  String? companyId;

  DateTime dataCriacao = DateTime.now();
}