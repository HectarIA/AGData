import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_service.dart';
import '../models/leitura_model.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Marker> _marcadores = [];
  List<CircleMarker> _circulos = []; // <-- NOVA LISTA PARA OS RAIOS!
  LatLng _centroDoMapa = const LatLng(-26.2295, -51.0871);
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMarcadores();
  }

  Color _pegarCorPino(String resultado) {
    switch (resultado) {
      case "SAUDÁVEL":
        return Colors.green;
      case "FERRUGEM":
        return Colors.red;
      case "OÍDIO":
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Future<void> _carregarMarcadores() async {
    List<LeituraModel> leituras = await _databaseService.buscarTodasLeituras();
    List<Marker> novosMarcadores = [];
    List<CircleMarker> novosCirculos = []; // <-- PREPARA OS CÍRCULOS

    for (var leitura in leituras) {
      if (leitura.latitude != 0.0 && leitura.longitude != 0.0) {
        var coordenada = LatLng(leitura.latitude, leitura.longitude);

        // 1. Cria o Pino
        novosMarcadores.add(
          Marker(
            point: coordenada,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${leitura.resultadoIA} - ${(leitura.confianca * 100).toStringAsFixed(1)}%'),
                    backgroundColor: _pegarCorPino(leitura.resultadoIA),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Icon(Icons.location_on, color: _pegarCorPino(leitura.resultadoIA), size: 40),
            ),
          ),
        );

        // 2. Cria o Círculo (Zona de Infecção/Buffer)
        novosCirculos.add(
          CircleMarker(
            point: coordenada,
            color: _pegarCorPino(leitura.resultadoIA).withOpacity(0.3), // Cor transparente (30%)
            borderColor: _pegarCorPino(leitura.resultadoIA), // Borda mais forte
            borderStrokeWidth: 2,
            useRadiusInMeter: true, // Garante que o raio é em metros reais, não em pixels da tela
            radius: 50, // <-- 50 METROS DE RAIO (Você pode aumentar ou diminuir)
          ),
        );
      }
    }

    if (novosMarcadores.isNotEmpty) {
      _centroDoMapa = novosMarcadores.first.point;
    }

    setState(() {
      _marcadores = novosMarcadores;
      _circulos = novosCirculos; // <-- ATUALIZA A TELA COM OS CÍRCULOS
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonamento de Risco', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : FlutterMap(
              options: MapOptions(
                initialCenter: _centroDoMapa,
                initialZoom: 16.0, // Aumentei um pouco o zoom para ver os círculos melhor
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.agdata.app',
                ),
                // IMPORTANTE: Os círculos devem vir ANTES dos marcadores para ficarem "por baixo" dos pinos
                CircleLayer(
                  circles: _circulos,
                ),
                MarkerLayer(
                  markers: _marcadores,
                ),
              ],
            ),
    );
  }
}