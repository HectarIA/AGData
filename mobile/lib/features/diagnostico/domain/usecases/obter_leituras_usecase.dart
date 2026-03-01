import '../entities/leitura.dart';
import '../repositories/i_leitura_repository.dart';

class ObterTodasLeiturasUseCase { // Nome da classe
  final ILeituraRepository repository;

  ObterTodasLeiturasUseCase(this.repository);

  Future<List<Leitura>> execute() async {
    return await repository.buscarTodasLeituras();
  }
}