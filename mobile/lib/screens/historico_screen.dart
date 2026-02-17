import 'dart:io';
import 'package:flutter/material.dart';
import '../models/leitura_model.dart';
import '../services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // --- FUNÇÃO DO WHATSAPP ORGANIZADA AQUI ---
  Future<void> _enviarRelatorioWhatsApp() async {
    // 1. Separa só as leituras que o utilizador marcou na caixinha
    final itensMarcados = _leituras.where((l) => _selecionados.contains(l.id)).toList();
    if (itensMarcados.isEmpty) return;

    // 2. Constrói o texto do relatório linha por linha
    StringBuffer sb = StringBuffer();
    sb.writeln("📊 *Relatório AGdata - Inspeção de Campo*");
    sb.writeln("📅 *Data do Envio:* ${_formatarData(DateTime.now())}\n");
    sb.writeln("⚠️ *Atenção:* ${itensMarcados.length} registo(s) selecionado(s).\n");

    for (int i = 0; i < itensMarcados.length; i++) {
      final item = itensMarcados[i];
      sb.writeln("*Foco ${i + 1} - ${item.resultadoIA}*");
      sb.writeln("Precisão: ${(item.confianca * 100).toStringAsFixed(1)}%");
      
      // Mudei para o link oficial do Google Maps que crava o pino!
      final linkMapa = "https://maps.google.com/?q=${item.latitude},${item.longitude}";
      sb.writeln("📍 Localização: $linkMapa\n");
    }

    sb.writeln("Aguardando orientações de manejo. 🚜");

    // 3. Converte o texto para formato de link de internet
    final textoCodificado = Uri.encodeComponent(sb.toString());
    
    // O link universal do WhatsApp
    final url = Uri.parse("https://wa.me/?text=$textoCodificado");

    // 4. Tenta abrir o WhatsApp no celular
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o link');
      }
      // Se deu certo, limpa a seleção para a tela ficar bonita novamente
      setState(() {
        _selecionados.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao abrir o WhatsApp. Ele está instalado?")),
        );
      }
    }
  }
  // --- FIM DA FUNÇÃO DO WHATSAPP ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Campo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            // Se a lista estiver vazia, botão fica null (apagado). Se tiver itens, chama a função!
            onPressed: _selecionados.isEmpty ? null : _enviarRelatorioWhatsApp,
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