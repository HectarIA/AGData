import 'package:isar/isar.dart';

part 'leitura_model.g.dart'; 

@collection
class LeituraModel {
  Id id = Isar.autoIncrement; 

  late String resultadoIA;       
  late double confianca;         
  late String caminhoImagem;     
  
  late DateTime dataHora;        
  late double latitude;          
  late double longitude;         

  String talhao = "";

  String? userId;
  String? companyId;

  @Index()
  bool sincronizado = false;

  Map<String, dynamic> toMap() {
    return {
      'resultadoIA': resultadoIA,
      'confianca': confianca,
      'caminhoImagem': caminhoImagem,
      'dataHora': dataHora.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'talhao': talhao,
      'userId': userId,
      'companyId': companyId,
      'sincronizado': sincronizado,
    };
  }
}