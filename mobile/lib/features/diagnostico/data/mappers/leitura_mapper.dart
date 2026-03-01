import '../../domain/entities/leitura.dart';
import '../models/leitura_model.dart';

extension LeituraMapper on LeituraModel {
  Leitura toEntity() {
    return Leitura(
      id: id,
      resultadoIA: resultadoIA,
      confianca: confianca,
      caminhoImagem: caminhoImagem,
      dataHora: dataHora,
      latitude: latitude,
      longitude: longitude,
      talhao: talhao,
      sincronizado: sincronizado,
    );
  }
}