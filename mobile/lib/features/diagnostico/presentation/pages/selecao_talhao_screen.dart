import 'package:flutter/material.dart';
import '../controllers/selecao_talhao_controller.dart'; 
import 'home_screen.dart';
import '/../infra/repositories/sync_repository.dart';
import '/../infra/services/connectivity_service.dart';

class SelecaoTalhaoScreen extends StatefulWidget {
  const SelecaoTalhaoScreen({super.key});

  @override
  State<SelecaoTalhaoScreen> createState() => _SelecaoTalhaoScreenState();
}

class _SelecaoTalhaoScreenState extends State<SelecaoTalhaoScreen> {
  final SelecaoTalhaoController _controller = SelecaoTalhaoController();
  final SyncRepository _syncRepo = SyncRepository();
  final ConnectivityService _connectivity = ConnectivityService();
  bool _isSyncing = false;

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    
    final isStable = await _connectivity.triplePingCheck();
    
    if (isStable) {
      try {
        await _syncRepo.sincronizarLeituras();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados sincronizados com a nuvem!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na sincronização: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conexão instável ou inexistente. Tente mais tarde.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    setState(() => _isSyncing = false);
  }

  Future<void> _mostrarDialogoNovoTalhao() async {
    TextEditingController textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cadastrar Novo Talhão', style: TextStyle(color: Colors.green)),
          content: TextField(
            controller: textController,
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
                String nome = textController.text.trim();
                if (nome.isNotEmpty) {
                  await _controller.salvarTalhao(nome);
                  if (context.mounted) Navigator.pop(context);
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
        actions: [
          _isSyncing 
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )
            : IconButton(
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
                onPressed: _handleManualSync,
                tooltip: 'Sincronizar com Nuvem',
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovoTalhao,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Talhão'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          return Padding(
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
                
                if (_controller.talhoes.isEmpty)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.agriculture, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Nenhum talhão cadastrado.\nCrie o primeiro agora.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _controller.talhoes.length,
                      itemBuilder: (context, index) {
                        final talhao = _controller.talhoes[index].nome;
                        final isSelected = _controller.talhaoSelecionado == talhao;

                        return Card(
                          color: isSelected ? Colors.green[50] : Colors.white,
                          elevation: isSelected ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: isSelected ? Colors.green : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(Icons.eco, color: isSelected ? Colors.green[800] : Colors.grey),
                            title: Text(talhao, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                            onTap: () => _controller.selecionarTalhao(talhao),
                          ),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _controller.talhaoSelecionado == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(talhaoAtual: _controller.talhaoSelecionado!),
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
          );
        },
      ),
    );
  }
}