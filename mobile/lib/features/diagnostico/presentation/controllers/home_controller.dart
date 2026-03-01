import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

// Ajuste o caminho abaixo conforme a sua estrutura de pastas
import '../../data/models/leitura_model.dart';
import '../../data/datasources/classifier.dart';
import '../../data/datasources/location_service.dart';
import '../../data/datasources/database_service.dart';

class HomeController extends ChangeNotifier {
  final Classifier _classifier = Classifier();
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  String _resultado = "Tire uma fotografia";
  String _confianca = "para analisar a soja";
  String _localizacaoTexto = "";
  bool _loading = false;

  File? get image => _image;
  String get resultado => _resultado;
  String get confianca => _confianca;
  String get localizacaoTexto => _localizacaoTexto;
  bool get loading => _loading;

  HomeController() {
    _classifier.loadModel();
  }

  Future<void> pickAndProcessImage(ImageSource source, String talhao) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    _image = File(pickedFile.path);
    notifyListeners();
    await _processarImagem(_image!, talhao);
  }

  Future<void> _processarImagem(File image, String talhao) async {
    _loading = true;
    _resultado = "A analisar...";
    _confianca = "...";
    _localizacaoTexto = "A buscar satélite... 🛰️";
    notifyListeners();

    try {
      // 1. Recebe o resultado como um Mapa (label + confidence)
      final Map<String, dynamic> resultadoIA = await _classifier.predict(image);
      final String nomeFinal = resultadoIA['label'] ?? "Erro";
      final double confianca = resultadoIA['confidence'] ?? 0.0;

      // 2. Busca localização
      final Position? pos = await _locationService.getCurrentPosition();
      
      final appDir = await getApplicationDocumentsDirectory();
      final nomeFicheiro = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagemGuardada = await image.copy('${appDir.path}/$nomeFicheiro');

      // 3. Monta o modelo de dados
      final novaLeitura = LeituraModel()
        ..resultadoIA = nomeFinal.toUpperCase()
        ..confianca = confianca // Agora usa o valor real da IA
        ..caminhoImagem = imagemGuardada.path
        ..dataHora = DateTime.now()
        ..latitude = pos?.latitude ?? 0.0
        ..longitude = pos?.longitude ?? 0.0
        ..talhao = talhao
        ..sincronizado = false;

      await _databaseService.guardarLeitura(novaLeitura);

      // 4. Atualiza a tela com os dados reais
      _resultado = nomeFinal.toUpperCase();
      _confianca = "Precisão: ${(confianca * 100).toStringAsFixed(1)}%";
      _localizacaoTexto = pos != null 
          ? "📍 ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}" 
          : "GPS indisponível";

    } catch (e) {
      debugPrint("ERRO NO CONTROLLER: $e");
      _resultado = "ERRO NA ANÁLISE";
      _confianca = "Tente novamente";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}