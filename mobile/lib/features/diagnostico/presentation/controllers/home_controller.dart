import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

// Ajuste os caminhos conforme sua estrutura
import '../../data/models/leitura_model.dart';
import '../../data/datasources/classifier.dart';
import '../../data/datasources/location_service.dart';
import '../../data/datasources/database_service.dart';
import '../../data/services/metadata_service.dart'; // 1. Importe o novo serviço

class HomeController extends ChangeNotifier {
  final Classifier _classifier = Classifier();
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final MetadataService _metadataService = MetadataService(); // 2. Instancie o serviço
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
    // 3. Importante: imageQuality 100 para não perder metadados na galeria
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100, 
    );
    
    if (pickedFile == null) return;

    _image = File(pickedFile.path);
    notifyListeners();
    // Passamos o 'source' para saber se tentamos metadados ou não
    await _processarImagem(_image!, talhao, source);
  }

  Future<void> _processarImagem(File image, String talhao, ImageSource source) async {
    _loading = true;
    _resultado = "A analisar...";
    _confianca = "...";
    _localizacaoTexto = "A processar localização... 🛰️";
    notifyListeners();

    try {
      // 1. Processamento da IA
      final Map<String, dynamic> resultadoIA = await _classifier.predict(image);
      final String nomeFinal = resultadoIA['label'] ?? "Erro";
      final double confiancaIA = resultadoIA['confidence'] ?? 0.0;

      // 2. Lógica de Localização Híbrida
      double lat = 0.0;
      double lng = 0.0;
      bool localizacaoObtida = false;

      // Se vier da galeria, tenta extrair os metadados da foto primeiro
      if (source == ImageSource.gallery) {
        final coordsMeta = await _metadataService.extrairLocalizacaoDaFoto(image);
        if (coordsMeta != null) {
          lat = coordsMeta['latitude']!;
          lng = coordsMeta['longitude']!;
          localizacaoObtida = true;
          debugPrint("📍 Localização extraída dos metadados EXIF.");
        }
      }

      // Se não obteve da foto (ou se for câmera), busca o GPS atual do dispositivo
      if (!localizacaoObtida) {
        final Position? pos = await _locationService.getCurrentPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
          localizacaoObtida = true;
          debugPrint("🛰️ Localização obtida via GPS do dispositivo.");
        }
      }

      // 3. Salva a imagem localmente
      final appDir = await getApplicationDocumentsDirectory();
      final nomeFicheiro = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagemGuardada = await image.copy('${appDir.path}/$nomeFicheiro');

      // 4. Monta e guarda o modelo de dados
      final novaLeitura = LeituraModel()
        ..resultadoIA = nomeFinal.toUpperCase()
        ..confianca = confiancaIA
        ..caminhoImagem = imagemGuardada.path
        ..dataHora = DateTime.now()
        ..latitude = lat
        ..longitude = lng
        ..talhao = talhao
        ..sincronizado = false;

      await _databaseService.guardarLeitura(novaLeitura);

      // 5. Atualiza a UI
      _resultado = nomeFinal.toUpperCase();
      _confianca = "Precisão: ${(confiancaIA * 100).toStringAsFixed(1)}%";
      _localizacaoTexto = localizacaoObtida 
          ? "📍 ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}" 
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