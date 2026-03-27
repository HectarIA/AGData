import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/database_service.dart';
import '../../data/models/leitura_model.dart';
import '../../data/models/talhao_model.dart';

class MapaController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  List<LeituraModel> _todasLeituras = [];
  List<TalhaoModel> _todosTalhoes = [];
  
  List<Marker> markers = [];
  List<CircleMarker> circles = [];
  bool loading = true;
  LatLng centroMapa = const LatLng(-26.2295, -51.0871);

  // Filtros
  String? filtroTalhao;
  String? filtroDoenca;
  DateTime? dataInicio;
  DateTime? dataFim;

  MapaController() {
    _init();
  }

  Future<void> _init() async {
    _todasLeituras = await _db.buscarTodasLeituras();
    _todosTalhoes = await _db.buscarTodosTalhoes();
    aplicarFiltros();
    loading = false;
    notifyListeners();
  }

  void aplicarFiltros({String? talhao, String? doenca, DateTime? inicio, DateTime? fim}) {
    filtroTalhao = talhao;
    filtroDoenca = doenca;
    dataInicio = inicio;
    dataFim = fim;

    final filtradas = _todasLeituras.where((l) {
      if (filtroTalhao != null && l.talhao != filtroTalhao) return false;
      if (filtroDoenca != null && l.resultadoIA != filtroDoenca) return false;
      if (dataInicio != null && l.dataHora.isBefore(dataInicio!)) return false;
      if (dataFim != null) {
        final fimDia = dataFim!.add(const Duration(days: 1));
        if (l.dataHora.isAfter(fimDia)) return false;
      }
      return true;
    }).toList();

    _gerarCamadas(filtradas);
    notifyListeners();
  }

  void _gerarCamadas(List<LeituraModel> lista) {
    markers = [];
    circles = [];

    for (var l in lista) {
      if (l.latitude != 0.0) {
        final pos = LatLng(l.latitude, l.longitude);
        final cor = _pegarCor(l.resultadoIA);
        
        markers.add(Marker(point: pos, width: 50, height: 50, child: Icon(Icons.location_on, color: cor, size: 40)));
        circles.add(CircleMarker(point: pos, color: cor.withValues(alpha: 0.3), borderColor: cor, borderStrokeWidth: 2, useRadiusInMeter: true, radius: 50));
      }
    }
    if (markers.isNotEmpty) centroMapa = markers.first.point;
  }

Color _pegarCor(String res) { 
    switch (res.toLowerCase()) {
      case "saudavel": return Colors.green;
      case "ferrugem": return Colors.red;
      case "oidio": return Colors.orange[700]!;
      case "mancha_alvo": return Colors.brown[700]!;
      case "bacterial_blight": return Colors.teal;
      case "cercospora": return Colors.purple;
      case "deficiencia_potassio": return Colors.yellow[800]!;
      case "mildio": return Colors.blue;
      case "olho_sapo": return Colors.indigo;
      case "septoria": return Colors.cyan;
      case "inconclusivo": return Colors.grey[400]!;
      default: return Colors.grey[700]!;
    }
  }

  List<TalhaoModel> get talhoes => _todosTalhoes;
}
