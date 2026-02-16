import 'package:isar/isar.dart';

// Essa linha vai dar um erro vermelho no começo, é normal!
// O arquivo .g.dart será gerado magicamente no próximo passo.
part 'leitura_model.g.dart'; 

@collection
class LeituraModel {
  // O Isar exige um ID numérico para cada registro
  Id id = Isar.autoIncrement; 

  // --- Dados da Análise ---
  late String resultadoIA;       
  late double confianca;        
  late String caminhoImagem;     
  
  late DateTime dataHora;        
  late double latitude;          
  late double longitude;         

  bool sincronizado = false; 
}