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
  
  List<LeituraModel> _todasLeituras = [];      // Guarda TUDO que vem do banco
  List<LeituraModel> _leiturasFiltradas = [];  // Guarda só o que passa no filtro
  
  List<int> _selecionados = []; 
  bool _loading = true;

  // --- VARIÁVEIS DOS FILTROS ---
  DateTime? _dataFiltro;
  String _doencaFiltro = 'Todas';
  double _confiancaFiltro = 0.0;
  final List<String> _opcoesDoenca = ['Todas', 'FERRUGEM', 'OÍDIO', 'SAUDÁVEL', 'INCONCLUSIVO'];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final dados = await _databaseService.buscarTodasLeituras();
    setState(() {
      _todasLeituras = dados.reversed.toList();
      _leiturasFiltradas = List.from(_todasLeituras); // Inicialmente, mostra tudo
      _loading = false;
    });
  }

  // --- LÓGICA DE FILTRAGEM (O Motor de Busca) ---
  void _aplicarFiltros() {
    setState(() {
      _selecionados.clear(); // Limpa a seleção para evitar enviar coisas escondidas pro WhatsApp

      _leiturasFiltradas = _todasLeituras.where((leitura) {
        // 1. Filtro de Data (Lotes por Dia)
        bool passaData = true;
        if (_dataFiltro != null) {
          passaData = leitura.dataHora.year == _dataFiltro!.year &&
                      leitura.dataHora.month == _dataFiltro!.month &&
                      leitura.dataHora.day == _dataFiltro!.day;
        }

        // 2. Filtro de Tipo de Análise (Doença)
        bool passaDoenca = true;
        if (_doencaFiltro != 'Todas') {
          passaDoenca = leitura.resultadoIA == _doencaFiltro;
        }

        // 3. Filtro de Confiança (Preço de E-commerce)
        bool passaConfianca = leitura.confianca >= _confiancaFiltro;

        return passaData && passaDoenca && passaConfianca;
      }).toList();
    });
  }

  // --- MENU INFERIOR DE FILTROS (BottomSheet) ---
  void _abrirMenuDeFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (ctx) {
        // StatefulBuilder é necessário para atualizar a tela do menu deslizante em tempo real
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Filtrar Leituras", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 1. Filtro de Data (Lotes)
                  const Text("Lote por Dia:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _dataFiltro == null 
                        ? "Todas as datas (Mostrar tudo)" 
                        : "Dia: ${_dataFiltro!.day.toString().padLeft(2, '0')}/${_dataFiltro!.month.toString().padLeft(2, '0')}/${_dataFiltro!.year}",
                      style: TextStyle(color: _dataFiltro == null ? Colors.grey : Colors.black),
                    ),
                    trailing: const Icon(Icons.calendar_month, color: Colors.green),
                    onTap: () async {
                      final DateTime? escolhida = await showDatePicker(
                        context: context,
                        initialDate: _dataFiltro ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (escolhida != null) {
                        setModalState(() => _dataFiltro = escolhida);
                        _aplicarFiltros();
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Filtro de Doença
                  const Text("Tipo de Análise:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _doencaFiltro,
                    items: _opcoesDoenca.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (novoValor) {
                      setModalState(() => _doencaFiltro = novoValor!);
                      _aplicarFiltros();
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Filtro de Confiança (Slider)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grau de Certeza Mínimo:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${(_confiancaFiltro * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  Slider(
                    value: _confiancaFiltro,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20, // Pula de 5 em 5%
                    activeColor: Colors.green,
                    inactiveColor: Colors.green[100],
                    onChanged: (valor) {
                      setModalState(() => _confiancaFiltro = valor);
                      _aplicarFiltros();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Botão de Limpar Tudo
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.clear_all, color: Colors.red),
                      label: const Text("Limpar Filtros", style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      onPressed: () {
                        setModalState(() {
                          _dataFiltro = null;
                          _doencaFiltro = 'Todas';
                          _confiancaFiltro = 0.0;
                        });
                        _aplicarFiltros();
                        Navigator.pop(context);
                      },
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  // --- FUNÇÕES DE INTERFACE PADRÃO (Mesmas de antes) ---
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

  Future<void> _enviarRelatorioWhatsApp() async {
    // Busca na lista filtrada
    final itensMarcados = _leiturasFiltradas.where((l) => _selecionados.contains(l.id)).toList();
    if (itensMarcados.isEmpty) return;

    StringBuffer sb = StringBuffer();
    sb.writeln("📊 *Relatório AGdata - Inspeção de Campo*");
    sb.writeln("📅 *Data do Envio:* ${_formatarData(DateTime.now())}\n");
    sb.writeln("⚠️ *Atenção:* ${itensMarcados.length} registo(s) selecionado(s).\n");

    for (int i = 0; i < itensMarcados.length; i++) {
      final item = itensMarcados[i];
      sb.writeln("*Foco ${i + 1} - ${item.resultadoIA}*");
      sb.writeln("Precisão: ${(item.confianca * 100).toStringAsFixed(1)}%");
      final linkMapa = "https://maps.google.com/?q=${item.latitude},${item.longitude}";
      sb.writeln("📍 Localização: $linkMapa\n");
    }
    sb.writeln("Aguardando orientações de manejo. 🚜");

    final textoCodificado = Uri.encodeComponent(sb.toString());
    final url = Uri.parse("https://wa.me/?text=$textoCodificado");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o link');
      }
      setState(() => _selecionados.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao abrir o WhatsApp.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Campo', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // <-- NOVO BOTÃO DE FILTRO AQUI
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar Análises',
            onPressed: _abrirMenuDeFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Enviar WhatsApp',
            onPressed: _selecionados.isEmpty ? null : _enviarRelatorioWhatsApp,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _leiturasFiltradas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("Nenhuma análise encontrada.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  // AGORA USA A LISTA FILTRADA!
                  itemCount: _leiturasFiltradas.length,
                  itemBuilder: (context, index) {
                    final leitura = _leiturasFiltradas[index];
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
                              ClipRidge(leitura: leitura),
                              const SizedBox(width: 12),
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