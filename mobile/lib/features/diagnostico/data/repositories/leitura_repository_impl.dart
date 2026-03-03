import '../../domain/entities/leitura.dart';
import '../../domain/repositories/i_leitura_repository.dart';
import '../datasources/database_service.dart';

class LeituraRepositoryImpl implements ILeituraRepository {
  final DatabaseService _databaseService;

  LeituraRepositoryImpl(this._databaseService);

  @override
  Future<List<Leitura>> buscarTodasLeituras() async {
    // Aqui fazemos a conversão: Model (Data) -> Entity (Domain)
    final models = await _databaseService.buscarTodasLeituras();
    
    return models.map((m) => Leitura(
      id: m.id,
      resultadoIA: m.resultadoIA,
      confianca: m.confianca,
      caminhoImagem: m.caminhoImagem,
      dataHora: m.dataHora,
      latitude: m.latitude,
      longitude: m.longitude,
      talhao: m.talhao,
      sincronizado: m.sincronizado,
    )).toList();
  }
}