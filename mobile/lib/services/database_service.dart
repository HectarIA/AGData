import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/leitura_model.dart';
import '../models/talhao_model.dart'; // Importante!

class DatabaseService {
  // Mantém a instância do banco de dados aberta para toda a aplicação
  static late Isar isar;

  // Função que inicia o banco (chamada no main.dart)
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        LeituraModelSchema, 
        TalhaoModelSchema // <--- AGORA O BANCO RECONHECE OS TALHÕES
      ],
      directory: dir.path,
    );
  }

  // --- FUNÇÕES PARA LEITURAS (ANÁLISES DAS FOLHAS) ---

  Future<void> guardarLeitura(LeituraModel leitura) async {
    await isar.writeTxn(() async {
      await isar.leituraModels.put(leitura);
    });
  }

  Future<List<LeituraModel>> buscarTodasLeituras() async {
    return await isar.leituraModels.where().sortByDataHoraDesc().findAll();
  }

  // --- FUNÇÕES PARA TALHÕES (ÁREAS DA FAZENDA) ---

  // Salva um novo talhão (ex: "Gleba Norte") no banco
  Future<void> guardarTalhao(TalhaoModel talhao) async {
    await isar.writeTxn(() async {
      await isar.talhaoModels.put(talhao);
    });
  }

  // Busca todos os talhões cadastrados, ordenados por nome
  Future<List<TalhaoModel>> buscarTodosTalhoes() async {
    return await isar.talhaoModels.where().sortByNome().findAll();
  }
}