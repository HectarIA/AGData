import '../entities/leitura.dart';

abstract class ILeituraRepository {
  Future<List<Leitura>> buscarTodasLeituras();
  

}