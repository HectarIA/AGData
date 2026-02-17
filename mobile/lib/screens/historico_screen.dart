import 'dart:io';
import 'package:flutter/material.dart';
import '../models/leitura_model.dart';
import '../services/database_service.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<LeituraModel> _leituras = [];
  List<int> _selecionados = []; 
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final dados = await _databaseService.buscarTodasLeituras();
    // Inverte a lista para mostrar os mais recentes primeiro
    setState(() {
      _leituras = dados.reversed.toList();
      _loading = false;
    });
  }

  // Função simples para deixar a data bonita
  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
  }

  Color _pegarCorResultado(String resultado) {
    switch (resultado) {
      case "SAUDÁVEL": return Colors.green;
      case "FERRUGEM": return Colors.red;
      case "OÍDIO": return Colors.orange[700]!;
      default: return Colors.grey[700]!;
    }
  }

  void _alternarSelecao(int id) {
    setState(() {
      if (_selecionados.contains(id)) {
        _selecionados.remove(id);
      } else {
        _selecionados.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Campo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Este é o botão que usaremos no próximo passo para o WhatsApp!
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _selecionados.isEmpty 
              ? null // Fica desativado se nada estiver selecionado
              : () {
                  // Aqui entrará a lógica do WhatsApp na próxima etapa
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Preparar envio de ${_selecionados.length} itens... (Em breve)")),
                  );
                },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _leituras.isEmpty
              ? const Center(child: Text("Nenhuma leitura encontrada no histórico.", style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _leituras.length,
                  itemBuilder: (context, index) {
                    final leitura = _leituras[index];
                    final isSelecionado = _selecionados.contains(leitura.id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isSelecionado ? Colors.green : Colors.transparent, 
                          width: 2
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () => _alternarSelecao(leitura.id),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // 1. A Foto em miniatura
                              ClipRidge(leitura: leitura),
                              const SizedBox(width: 12),
                              
                              // 2. Os Dados
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      leitura.resultadoIA,
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold, 
                                        color: _pegarCorResultado(leitura.resultadoIA)
                                      ),
                                    ),
                                    Text(
                                      "Confiança: ${(leitura.confianca * 100).toStringAsFixed(1)}%",
                                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatarData(leitura.dataHora),
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 3. O Checkbox
                              Checkbox(
                                value: isSelecionado,
                                activeColor: Colors.green,
                                onChanged: (value) => _alternarSelecao(leitura.id),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// Widget extra só para deixar a foto bonitinha no canto
class ClipRidge extends StatelessWidget {
  final LeituraModel leitura;
  const ClipRidge({super.key, required this.leitura});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(leitura.caminhoImagem),
        height: 70,
        width: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 70, width: 70, color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}