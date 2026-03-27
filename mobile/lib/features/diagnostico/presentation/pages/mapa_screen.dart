import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../controllers/mapa_controller.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});
  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapaController _controller = MapaController();

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Variáveis temporárias para não alterar o estado do mapa até clicar em "Filtrar"
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
                  const Text("Filtrar Mapa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Divider(),
                  
                  // Filtro Talhão
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
                  
                  // Filtro Doença
                  const Text("Diagnóstico:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8, // Adicionado para não quebrar a tela se tiver muitas opções
                    children: [
                      "saudavel", "Ferrugem", "oidio", "mancha_alvo", 
                      "bacterial_blight", "cercospora", "deficiencia_potassio", 
                      "mildio", "olho_sapo", "septoria", "Inconclusivo"
                    ].map((tipo) {
                      final selecionado = tempDoenca == tipo;
                      return ChoiceChip(
                        label: Text(tipo),
                        selected: selecionado,
                        onSelected: (bool selected) => setModalState(() => tempDoenca = selected ? tipo : null),
                      );
                    }).toList(),
                  ),

                  const Spacer(),
                  
                  // Botões Ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _controller.aplicarFiltros(); // Limpa tudo
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
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) return const Center(child: CircularProgressIndicator());
          
          return FlutterMap(
            options: MapOptions(initialCenter: _controller.centroMapa, initialZoom: 16.0),
            children: [
              TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.agdata.app',
              ),
              CircleLayer(circles: _controller.circles),
              MarkerLayer(markers: _controller.markers),
              
            ],
          );
        },
      ),
    );
  }
}