import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// Ajuste os caminhos conforme sua estrutura de pastas
import '../../data/models/leitura_model.dart';
import '../../data/datasources/classifier.dart';
import '../../data/datasources/location_service.dart';
import '../../data/datasources/database_service.dart';
import '../../data/services/metadata_service.dart';

class HomeController extends ChangeNotifier {
  final Classifier _classifier = Classifier();
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final MetadataService _metadataService = MetadataService();
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

  /// Método para solicitar todas as permissões necessárias ao iniciar o app
  Future<void> solicitarPermissoesIniciais() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.storage, // Para Android 12 ou inferior
      Permission.photos,  // Para iOS e Android 13+
      Permission.accessMediaLocation, // Crucial para ler EXIF/GPS das fotos
    ].request();

    statuses.forEach((permission, status) {
      debugPrint('Permissão ${permission.toString()}: $status');
    });
  }

  Future<void> pickAndProcessImage(ImageSource source, String talhao) async {
    // Definimos imageQuality como 100 para evitar que o Flutter comprima 
    // a imagem e remova os metadados EXIF antes de processarmos.
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100, 
    );
    
    if (pickedFile == null) return;

    _image = File(pickedFile.path);
    notifyListeners();
    
    await _processarImagem(_image!, talhao, source);
  }

  Future<void> _processarImagem(File image, String talhao, ImageSource source) async {
    _loading = true;
    _resultado = "A analisar...";
    _confianca = "...";
    _localizacaoTexto = "A processar localização... 🛰️";
    notifyListeners();

    try {
      // 1. Processamento da Inteligência Artificial
      final Map<String, dynamic> resultadoIA = await _classifier.predict(image);
      final String nomeFinal = resultadoIA['label'] ?? "Erro";
      final double confiancaIA = resultadoIA['confidence'] ?? 0.0;

      // 2. Lógica de Localização Híbrida (Metadados -> GPS em tempo real)
      double lat = 0.0;
      double lng = 0.0;
      bool localizacaoObtida = false;

      // Prioridade: Se vier da galeria, tenta extrair a localização original da foto
      if (source == ImageSource.gallery) {
        final coordsMeta = await _metadataService.extrairLocalizacaoDaFoto(image);
        if (coordsMeta != null) {
          lat = coordsMeta['latitude']!;
          lng = coordsMeta['longitude']!;
          localizacaoObtida = true;
          debugPrint("📍 Localização extraída dos metadados EXIF com sucesso.");
        }
      }

      // Plano B: Se a foto não tiver metadados ou se for tirada na hora (câmera)
      if (!localizacaoObtida) {
        final Position? pos = await _locationService.getCurrentPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
          localizacaoObtida = true;
          debugPrint("🛰️ Localização obtida via sensor GPS do dispositivo.");
        }
      }

      // 3. Persistência da Imagem no Armazenamento Local
      final appDir = await getApplicationDocumentsDirectory();
      final nomeFicheiro = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagemGuardada = await image.copy('${appDir.path}/$nomeFicheiro');

      // 4. Criação do Modelo e Salvamento no Banco Isar
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

      // 5. Atualização da Interface do Usuário
      _resultado = nomeFinal.toUpperCase();
      _confianca = "Precisão: ${(confiancaIA * 100).toStringAsFixed(1)}%";
      _localizacaoTexto = localizacaoObtida 
          ? "📍 ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}" 
          : "Localização indisponível";

    } catch (e) {
      debugPrint("ERRO NO HOME_CONTROLLER: $e");
      _resultado = "ERRO NA ANÁLISE";
      _confianca = "Tente novamente";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}