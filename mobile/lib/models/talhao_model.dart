import 'package:isar/isar.dart';

// O erro vermelho aqui é normal antes de rodar o build_runner!
part 'talhao_model.g.dart'; 

@collection
class TalhaoModel {
  Id id = Isar.autoIncrement; // ID único gerado automaticamente

  late String nome; // Ex: "Lote Sul", "Gleba 2"
  
  DateTime dataCriacao = DateTime.now(); // Para sabermos quando foi cadastrado
}