import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/leitura_model.dart';
import '../models/talhao_model.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        LeituraModelSchema, 
        TalhaoModelSchema 
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

  Future<void> guardarTalhao(TalhaoModel talhao) async {
    await isar.writeTxn(() async {
      await isar.talhaoModels.put(talhao);
    });
  }

  Future<List<TalhaoModel>> buscarTalhoesPorEmpresa(String companyId) async {
    return await isar.talhaoModels
        .filter()
        .companyIdEqualTo(companyId) // Filtro do Isar
        .sortByNome()
        .findAll();
  }

  Future<List<TalhaoModel>> buscarTodosTalhoes() async {
    return await isar.talhaoModels.where().sortByNome().findAll();
  }
}