import 'package:flutter/material.dart';
import '../controllers/selecao_talhao_controller.dart';
import 'home_screen.dart';
import '../../../../infra/repositories/sync_repository.dart';
import '../../../../infra/services/connectivity_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/controller/session_controller.dart';

import '../../../auth/presentation/widgets/custom_drawer.dart'; 

class SelecaoTalhaoScreen extends StatefulWidget {
  const SelecaoTalhaoScreen({super.key});

  @override
  State<SelecaoTalhaoScreen> createState() => _SelecaoTalhaoScreenState();
}

class _SelecaoTalhaoScreenState extends State<SelecaoTalhaoScreen> {
  final SelecaoTalhaoController _controller = SelecaoTalhaoController();
  final SyncRepository _syncRepo = sl<SyncRepository>();
  final ConnectivityService _connectivity = sl<ConnectivityService>();
  final SessionController _session = sl<SessionController>();

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
              content: Text('Dados sincronizados!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
    setState(() => _isSyncing = false);
  }

  Future<void> _mostrarDialogoNovoTalhao() async {
    TextEditingController textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Talhão', style: TextStyle(color: Colors.green)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Ex: Lote Sul'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                await _controller.salvarTalhao(textController.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usado apenas para a saudação de boas vindas na tela principal
    final user = _session.usuario; 

    return Scaffold(
      // CHAMADA DO SEU CUSTOM DRAWER AQUI
      drawer: CustomDrawer(
        onSync: _handleManualSync,
        isSyncing: _isSyncing,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovoTalhao,
        backgroundColor: Colors.green[800],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Talhão', style: TextStyle(color: Colors.white)),
      ),

      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                              ),
                              const Text(
                                'HectarIA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFF2E7D32),
                            ),
                            children: [
                              const TextSpan(
                                text: 'Bem vindo, ',
                                style: TextStyle(fontWeight: FontWeight.w400),
                              ),
                              TextSpan(
                                text: '${user?.name.split(' ').first ?? 'Usuário'}!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Card(
                              elevation: 2,
                              color: Colors.grey[50],
                              child: const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Monitoramento Local',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Selecione a área de trabalho abaixo.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_controller.talhoes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text('Nenhum talhão cadastrado.'),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _controller.talhoes.length,
                                itemBuilder: (context, index) {
                                  final talhao = _controller.talhoes[index].nome;
                                  final isSelected = _controller.talhaoSelecionado == talhao;
                                  return Card(
                                    color: isSelected
                                        ? Colors.green[50]
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFF2E7D32)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.layers_outlined,
                                        color: isSelected
                                            ? const Color(0xFF2E7D32)
                                            : Colors.grey,
                                      ),
                                      title: Text(
                                        talhao,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF2E7D32),
                                            )
                                          : const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                            ),
                                      onTap: () => _controller.selecionarTalhao(talhao),
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _controller.talhaoSelecionado == null
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomeScreen(
                                              talhaoAtual: _controller.talhaoSelecionado!,
                                            ),
                                          ),
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'INICIAR MONITORAMENTO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}