import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_service.dart';
import '../models/leitura_model.dart';
import '../models/talhao_model.dart'; // Importe para listar os talhões no filtro

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  // Dados brutos (cache)
  List<LeituraModel> _todasLeituras = [];
  List<TalhaoModel> _todosTalhoes = [];

  // Dados visíveis no mapa
  List<Marker> _marcadores = [];
  List<CircleMarker> _circulos = [];
  LatLng _centroDoMapa = const LatLng(-26.2295, -51.0871);
  bool _carregando = true;

  // --- ESTADO DOS FILTROS ---
  String? _filtroTalhao;
  String? _filtroDoenca; // "SAUDÁVEL", "FERRUGEM", "OÍDIO"
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    // 1. Busca leituras e talhões do banco
    final leituras = await _databaseService.buscarTodasLeituras();
    final talhoes = await _databaseService.buscarTodosTalhoes();

    setState(() {
      _todasLeituras = leituras;
      _todosTalhoes = talhoes;
      _aplicarFiltros(); // Gera os marcadores iniciais (sem filtro)
      _carregando = false;
    });
  }

  Color _pegarCor(String resultado) {
    switch (resultado) {
      case "SAUDÁVEL": return Colors.green;
      case "FERRUGEM": return Colors.red;
      case "OÍDIO": return Colors.orange[700]!;
      default: return Colors.grey[700]!;
    }
  }

  // --- LÓGICA DE FILTRAGEM ---
  void _aplicarFiltros() {
    List<LeituraModel> filtradas = _todasLeituras.where((leitura) {
      // 1. Filtro de Talhão
      if (_filtroTalhao != null && leitura.talhao != _filtroTalhao) {
        return false;
      }
      // 2. Filtro de Doença
      if (_filtroDoenca != null && leitura.resultadoIA != _filtroDoenca) {
        return false;
      }
      // 3. Filtro de Data
      if (_dataInicio != null && leitura.dataHora.isBefore(_dataInicio!)) {
        return false;
      }
      if (_dataFim != null) {
        // Ajuste para pegar até o final do dia selecionado (23:59:59)
        final fimDia = _dataFim!.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        if (leitura.dataHora.isAfter(fimDia)) {
          return false;
        }
      }
      return true;
    }).toList();

    _gerarMarcadores(filtradas);
  }

  void _gerarMarcadores(List<LeituraModel> lista) {
    List<Marker> novosMarcadores = [];
    List<CircleMarker> novosCirculos = [];

    for (var leitura in lista) {
      if (leitura.latitude != 0.0) {
        var coordenada = LatLng(leitura.latitude, leitura.longitude);
        Color cor = _pegarCor(leitura.resultadoIA);

        novosMarcadores.add(
          Marker(
            point: coordenada,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${leitura.resultadoIA} (${leitura.talhao})'),
                    backgroundColor: cor,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Icon(Icons.location_on, color: cor, size: 40),
            ),
          ),
        );

        // Círculo (Raio)
        novosCirculos.add(
          CircleMarker(
            point: coordenada,
            color: cor.withValues(alpha: 0.3),
            borderColor: cor,
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
            radius: 50, 
          ),
        );
      }
    }

    if (novosMarcadores.isNotEmpty) {
      _centroDoMapa = novosMarcadores.first.point;
    }

    setState(() {
      _marcadores = novosMarcadores;
      _circulos = novosCirculos;
    });
  }

  // --- INTERFACE DO FILTRO (BOTTOM SHEET) ---
  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal cresça se necessário
      builder: (context) {
        // Variáveis temporárias para o estado do Modal
        String? tempTalhao = _filtroTalhao;
        String? tempDoenca = _filtroDoenca;
        DateTime? tempInicio = _dataInicio;
        DateTime? tempFim = _dataFim;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 600, // Altura fixa ou dinâmica
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtrar Mapa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Divider(),
                  
                  // 1. TALHÃO
                  const Text("Talhão:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tempTalhao,
                    hint: const Text("Todos os talhões"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Todos")),
                      ..._todosTalhoes.map((t) => DropdownMenuItem(value: t.nome, child: Text(t.nome)))
                    ],
                    onChanged: (val) => setModalState(() => tempTalhao = val),
                  ),
                  const SizedBox(height: 15),

                  // 2. DOENÇA
                  const Text("Diagnóstico:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ["SAUDÁVEL", "FERRUGEM", "OÍDIO"].map((tipo) {
                      final selecionado = tempDoenca == tipo;
                      return ChoiceChip(
                        label: Text(tipo),
                        selected: selecionado,
                        selectedColor: _pegarCor(tipo).withValues(alpha: 0.2),
                        labelStyle: TextStyle(color: selecionado ? _pegarCor(tipo) : Colors.black),
                        onSelected: (bool selected) {
                          setModalState(() {
                            tempDoenca = selected ? tipo : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 15),

                  // 3. DATAS
                  const Text("Período:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(tempInicio == null ? "Início" : "${tempInicio!.day}/${tempInicio!.month}"),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempInicio ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setModalState(() => tempInicio = picked);
                          },
                        ),
                      ),
                      const Text("-"),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(tempFim == null ? "Fim" : "${tempFim!.day}/${tempFim!.month}"),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempFim ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setModalState(() => tempFim = picked);
                          },
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                  
                  // BOTÕES DE AÇÃO
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Limpar tudo
                            setState(() {
                              _filtroTalhao = null;
                              _filtroDoenca = null;
                              _dataInicio = null;
                              _dataFim = null;
                              _aplicarFiltros();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Limpar Filtros"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: () {
                            // Aplicar
                            setState(() {
                              _filtroTalhao = tempTalhao;
                              _filtroDoenca = tempDoenca;
                              _dataInicio = tempInicio;
                              _dataFim = tempFim;
                              _aplicarFiltros();
                            });
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
    // Conta quantos filtros estão ativos para mostrar um indicador visual
    int filtrosAtivos = 0;
    if (_filtroTalhao != null) filtrosAtivos++;
    if (_filtroDoenca != null) filtrosAtivos++;
    if (_dataInicio != null) filtrosAtivos++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonamento', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _abrirFiltros,
                tooltip: "Filtrar Mapa",
              ),
              if (filtrosAtivos > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      filtrosAtivos.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : FlutterMap(
              options: MapOptions(
                initialCenter: _centroDoMapa,
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.agdata.app',
                ),
                CircleLayer(circles: _circulos),
                MarkerLayer(markers: _marcadores),
              ],
            ),
    );
  }
}