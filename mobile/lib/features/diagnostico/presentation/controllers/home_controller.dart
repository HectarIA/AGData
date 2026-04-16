import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/controller/session_controller.dart';
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
  final SessionController _session = sl<SessionController>();

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

  final Map<String, double> _thresholds = {
    'SAUDAVEL': 0.72,
    'FERRUGEM': 0.75,
    'MANCHA ALVO': 0.75,
    'MILDIO': 0.78,
    'OLHO DE SAPO': 0.78,
    'BACTERIAL BLIGHT': 0.82,
    'SEPTORIA': 0.82,
    'CERCOSPORA': 0.85,
    'OIDIO': 0.92,
    'DEFICIENCIA POTASSIO': 0.70,
  };

  HomeController() {
    _classifier.loadModel();
  }

  Future<void> solicitarPermissoesIniciais() async {
    await [
      Permission.location,
      Permission.camera,
      Permission.storage,
      Permission.photos,
      Permission.accessMediaLocation,
    ].request();
  }

  Future<void> pickAndProcessImage(ImageSource source, String talhao) async {
    if (source == ImageSource.camera) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
    }

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
      final Map<String, dynamic> resultadoIA = await _classifier.predict(image);
      final String nomeFinal = resultadoIA['label'] ?? "Erro";
      final double confiancaIA = resultadoIA['confidence'] ?? 0.0;

      final String labelChave = nomeFinal.toUpperCase().trim();
      final double limiteMinimo = _thresholds[labelChave] ?? 0.70;

      if (confiancaIA < limiteMinimo) {
        _image = null; 
        _resultado = "ANÁLISE INCONCLUSIVA";
        _confianca = "Confiança: ${(confiancaIA * 100).toStringAsFixed(1)}%";
        _localizacaoTexto = "A precisão para $labelChave deve ser > ${(limiteMinimo * 100).toInt()}%";
        return; 
      }

      double lat = 0.0;
      double lng = 0.0;
      bool localizacaoObtida = false;

      if (source == ImageSource.gallery) {
        final coordsMeta = await _metadataService.extrairLocalizacaoDaFoto(image);
        if (coordsMeta != null) {
          lat = coordsMeta['latitude']!;
          lng = coordsMeta['longitude']!;
          localizacaoObtida = true;
        } else {
          _image = null;
          _resultado = "ERRO NA GALERIA";
          _confianca = "Foto sem GPS original";
          _localizacaoTexto = "Metadados ausentes ❌";
          return;
        }
      } else {
        final Position? pos = await _locationService.getCurrentPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
          localizacaoObtida = true;
        }
      }

      if (!localizacaoObtida || (lat == 0.0 && lng == 0.0)) {
        _image = null;
        _resultado = "SEM LOCALIZAÇÃO";
        _confianca = "GPS não detectado";
        _localizacaoTexto = "Localização obrigatória ❌";
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final nomeFicheiro = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagemGuardada = await image.copy('${appDir.path}/$nomeFicheiro');

      final novaLeitura = LeituraModel()
        ..resultadoIA = labelChave
        ..confianca = confiancaIA
        ..caminhoImagem = imagemGuardada.path
        ..dataHora = DateTime.now()
        ..latitude = lat
        ..longitude = lng
        ..talhao = talhao
        ..sincronizado = false
        ..userId = _session.usuario?.uid      
        ..companyId = _session.usuario?.companyId; 

      await _databaseService.guardarLeitura(novaLeitura);

      if (labelChave == 'OIDIO') {
        _resultado = "⚠️ OÍDIO (ATENÇÃO)";
      } else {
        _resultado = labelChave;
      }

      _confianca = "Precisão: ${(confiancaIA * 100).toStringAsFixed(1)}%";
      _localizacaoTexto = "📍 ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";

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