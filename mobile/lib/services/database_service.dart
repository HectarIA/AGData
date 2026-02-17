import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/leitura_model.dart';

class DatabaseService {
  // Mantém a instância do banco de dados aberta para toda a aplicação
  static late Isar isar;

  // Função que inicia o banco (será chamada no main.dart)
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [LeituraModelSchema],
      directory: dir.path,
    );
  }

  // Função para guardar uma nova leitura silenciosamente
  Future<void> guardarLeitura(LeituraModel leitura) async {
    // Tudo o que altera o banco de dados tem de estar dentro de uma transação (writeTxn)
    await isar.writeTxn(() async {
      await isar.leituraModels.put(leitura);
    });
  }

  // Já deixo preparada a função que vamos usar amanhã para o Histórico!
  Future<List<LeituraModel>> obterHistorico() async {
    return await isar.leituraModels.where().sortByDataHoraDesc().findAll();
  }
}