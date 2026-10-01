import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/leitura_model.dart';
import '../../data/datasources/classifier.dart';
import '../../data/datasources/location_service.dart';
import '../../data/datasources/database_service.dart';
import '../../data/services/metadata_service.dart';

/// Estados da tela de diagnóstico.
enum DiagnosticoStatus { inicial, processando, revisao, erro }

class HomeController extends ChangeNotifier {
  final Classifier _classifier = Classifier();
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final MetadataService _metadataService = MetadataService();
  final ImagePicker _picker = ImagePicker();

  DiagnosticoStatus _status = DiagnosticoStatus.inicial;
  File? _image;
  String _resultado = '';
  double _confiancaValor = 0.0;
  String _localizacaoTexto = '';
  String _mensagemErro = '';
  bool _salvando = false;

  /// Leitura construída a partir do diagnóstico, ainda não persistida.
  LeituraModel? _leituraPendente;

  DiagnosticoStatus get status => _status;
  File? get image => _image;
  String get resultado => _resultado;
  double get confiancaValor => _confiancaValor;
  String get localizacaoTexto => _localizacaoTexto;
  String get mensagemErro => _mensagemErro;
  bool get salvando => _salvando;

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
      Permission.microphone,
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
    _status = DiagnosticoStatus.processando;
    notifyListeners();

    await _processar(_image!, talhao, source);
  }

  Future<void> _processar(File image, String talhao, ImageSource source) async {
    try {
      final Map<String, dynamic> resultadoIA = await _classifier.predict(image);
      final String nomeFinal = resultadoIA['label'] ?? "Erro";
      final double confiancaIA = resultadoIA['confidence'] ?? 0.0;

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
          _falhar('ERRO NA GALERIA', 'A foto não possui GPS original.');
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
        _falhar('SEM LOCALIZAÇÃO',
            'GPS não detectado. A localização é obrigatória.');
        return;
      }

      // Constrói a leitura pendente (a imagem só é copiada ao salvar).
      _leituraPendente = LeituraModel()
        ..resultadoIA = nomeFinal.toUpperCase()
        ..confianca = confiancaIA
        ..caminhoImagem = ''
        ..dataHora = DateTime.now()
        ..latitude = lat
        ..longitude = lng
        ..talhao = talhao
        ..sincronizado = false;

      _resultado = nomeFinal.toUpperCase();
      _confiancaValor = confiancaIA;
      _localizacaoTexto =
          "📍 ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
      _status = DiagnosticoStatus.revisao;
      notifyListeners();
    } catch (e) {
      debugPrint("ERRO NO HOME_CONTROLLER: $e");
      _falhar('ERRO NA ANÁLISE', 'Não foi possível processar a imagem.');
    }
  }

  void _falhar(String titulo, String mensagem) {
    _image = null;
    _leituraPendente = null;
    _resultado = titulo;
    _mensagemErro = mensagem;
    _status = DiagnosticoStatus.erro;
    notifyListeners();
  }

  /// Persiste a leitura em revisão, anexando a observação do técnico.
  /// Retorna true se salvou com sucesso.
  Future<bool> salvar({String observacao = ''}) async {
    final pendente = _leituraPendente;
    final origem = _image;
    if (pendente == null || origem == null) return false;

    _salvando = true;
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final nomeFicheiro = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagemGuardada = await origem.copy('${appDir.path}/$nomeFicheiro');

      pendente
        ..caminhoImagem = imagemGuardada.path
        ..observacao = observacao.trim();

      await _databaseService.guardarLeitura(pendente);
      _resetar();
      return true;
    } catch (e) {
      debugPrint("ERRO AO SALVAR LEITURA: $e");
      _falhar('ERRO AO SALVAR', 'Não foi possível guardar a leitura.');
      return false;
    }
  }

  /// Descarta a leitura em revisão (ex: imagem com erro de leitura).
  void descartar() => _resetar();

  void _resetar() {
    _status = DiagnosticoStatus.inicial;
    _image = null;
    _leituraPendente = null;
    _resultado = '';
    _confiancaValor = 0.0;
    _localizacaoTexto = '';
    _mensagemErro = '';
    _salvando = false;
    notifyListeners();
  }
}
