import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import '../controllers/mapa_controller.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapaController _controller = MapaController();

  Future<String> _getPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? tempTalhao = _controller.filtroTalhao;
        String? tempDoenca = _controller.filtroDoenca;
        DateTime? tempInicio = _controller.dataInicio;
        DateTime? tempFim = _controller.dataFim;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtrar Mapa", 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Divider(),
                  const Text("Talhão:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tempTalhao,
                    hint: const Text("Todos os talhões"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todos")),
                      ..._controller.talhoes.map((t) => DropdownMenuItem(value: t.nome, child: Text(t.nome)))
                    ],
                    onChanged: (val) => setModalState(() => tempTalhao = val),
                  ),
                  const SizedBox(height: 15),
                  const Text("Diagnóstico:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ["SAUDÁVEL", "FERRUGEM", "OÍDIO", "MANCHA ALVO", "INCONCLUSIVO"].map((tipo) {
                      final selecionado = tempDoenca == tipo;
                      return ChoiceChip(
                        label: Text(tipo),
                        selected: selecionado,
                        onSelected: (bool selected) => setModalState(() => tempDoenca = selected ? tipo : null),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _controller.aplicarFiltros();
                            Navigator.pop(context);
                          },
                          child: const Text("Limpar"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: () {
                            _controller.aplicarFiltros(talhao: tempTalhao, doenca: tempDoenca, inicio: tempInicio, fim: tempFim);
                            Navigator.pop(context);
                          },
                          child: const Text("Filtrar"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonamento', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _abrirFiltros,
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getPath(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cachePath = snapshot.data!;

          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.loading) return const Center(child: CircularProgressIndicator());

              return FlutterMap(
                options: MapOptions(
                  initialCenter: _controller.centroMapa,
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.agdata.app',
                    tileProvider: CachedTileProvider(
                      // Configuração correta do Store com limite de tamanho
                      store: HiveCacheStore(
                        cachePath,
                        hiveBoxName: 'agdata_tiles',
                      ),
                    ),
                  ),
                  CircleLayer(circles: _controller.circles),
                  MarkerLayer(markers: _controller.markers),
                ],
              );
            },
          );
        },
      ),
    );
  }
}