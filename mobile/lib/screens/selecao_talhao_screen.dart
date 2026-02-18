import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/database_service.dart';
import '../models/talhao_model.dart';

class SelecaoTalhaoScreen extends StatefulWidget {
  const SelecaoTalhaoScreen({super.key});

  @override
  State<SelecaoTalhaoScreen> createState() => _SelecaoTalhaoScreenState();
}

class _SelecaoTalhaoScreenState extends State<SelecaoTalhaoScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  List<TalhaoModel> _talhoes = [];
  String? _talhaoSelecionado;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTalhoesDoBanco();
  }

  Future<void> _carregarTalhoesDoBanco() async {
    List<TalhaoModel> lista = await _databaseService.buscarTodosTalhoes();
    setState(() {
      _talhoes = lista;
      if (_talhaoSelecionado == null && lista.isNotEmpty) {
        _talhaoSelecionado = lista.first.nome;
      }
      _carregando = false;
    });
  }

  Future<void> _mostrarDialogoNovoTalhao() async {
    TextEditingController controlador = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cadastrar Novo Talhão', style: TextStyle(color: Colors.green)),
          content: TextField(
            controller: controlador,
            decoration: const InputDecoration(
              hintText: 'Ex: Lote Sul, Gleba 03...',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                String nome = controlador.text.trim();
                if (nome.isNotEmpty) {
                  final novoTalhao = TalhaoModel()..nome = nome;
                  await _databaseService.guardarTalhao(novoTalhao);
                  
                  if (context.mounted) Navigator.pop(context);
                  _carregarTalhoesDoBanco();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AGdata - Áreas', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovoTalhao,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Talhão'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Onde você vai realizar o monitoramento?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  if (_talhoes.isEmpty)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.agriculture, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum talhão cadastrado.\nCrie o primeiro agora.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _talhoes.length,
                        itemBuilder: (context, index) {
                          final talhao = _talhoes[index].nome;
                          final isSelected = _talhaoSelecionado == talhao;

                          return Card(
                            color: isSelected ? Colors.green[50] : Colors.white,
                            elevation: isSelected ? 3 : 1,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: isSelected ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(Icons.eco, color: isSelected ? Colors.green[800] : Colors.grey),
                              title: Text(
                                talhao, 
                                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              ),
                              trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                              onTap: () {
                                setState(() {
                                  _talhaoSelecionado = talhao;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _talhaoSelecionado == null
                        ? null
                        : () {
                            // Aqui ele chama a HomeScreen passando o nome do Talhão!
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(talhaoAtual: _talhaoSelecionado!),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Iniciar Análises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 60), 
                ],
              ),
            ),
    );
  }
}