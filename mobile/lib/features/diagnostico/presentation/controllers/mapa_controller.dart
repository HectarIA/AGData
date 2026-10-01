import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/diagnostico_visuals.dart';
import '../../data/datasources/database_service.dart';
import '../../data/models/leitura_model.dart';
import '../../data/models/talhao_model.dart';

class MapaController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<LeituraModel> _todasLeituras = [];
  List<TalhaoModel> _todosTalhoes = [];

  List<Marker> markers = [];
  List<CircleMarker> circles = [];

  /// Pontos visíveis (para reenquadrar a câmera nas ocorrências).
  List<LatLng> pontos = [];

  /// Contagem por diagnóstico entre as ocorrências visíveis (label -> total).
  Map<String, int> contagemDoenca = {};

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

  void aplicarFiltros(
      {String? talhao, String? doenca, DateTime? inicio, DateTime? fim}) {
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
    pontos = [];
    contagemDoenca = {};

    for (var l in lista) {
      if (l.latitude == 0.0) continue;

      final pos = LatLng(l.latitude, l.longitude);
      final v = DiagnosticoVisual.fromResultado(l.resultadoIA);

      pontos.add(pos);
      contagemDoenca[v.label] = (contagemDoenca[v.label] ?? 0) + 1;

      circles.add(CircleMarker(
        point: pos,
        color: v.color.withValues(alpha: 0.25),
        borderColor: v.color,
        borderStrokeWidth: 2,
        // Raio fixo em pixels — não escala com o zoom.
        radius: 14,
      ));

      markers.add(Marker(
        point: pos,
        width: 38,
        height: 38,
        alignment: Alignment.topCenter,
        child: _PinMapa(color: v.color, icon: v.icon),
      ));
    }

    if (markers.isNotEmpty) centroMapa = markers.first.point;
  }

  /// Total de ocorrências visíveis no mapa.
  int get totalVisiveis => pontos.length;

  List<TalhaoModel> get talhoes => _todosTalhoes;
}

/// Pino do mapa: gota colorida por diagnóstico, com contorno branco e ícone.
class _PinMapa extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _PinMapa({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const Icon(Icons.location_on, size: 38, color: Colors.white),
        Icon(Icons.location_on, size: 32, color: color),
        Positioned(top: 6, child: Icon(icon, size: 11, color: Colors.white)),
      ],
    );
  }
}
