import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORT NECESSÁRIO
import '../controllers/selecao_talhao_controller.dart';
import 'home_screen.dart';
import '../../../../infra/repositories/sync_repository.dart';
import '../../../../infra/services/connectivity_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/pages/super_admin_page.dart';
import '../../../auth/presentation/pages/admin_page.dart';
import '../../../auth/presentation/controller/session_controller.dart';
import '../../../auth/data/models/auth_model.dart';

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

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
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
    final user = _session.usuario;
    final bool isSuperAdmin = user?.role == UserRole.superAdmin;
    final bool isAdmin = user?.role == UserRole.admin;
    final bool temAcessoGestao = isSuperAdmin || isAdmin;

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              
              accountName: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(user?.name ?? 'Usuário'),
                  // BUSCA O NOME DA EMPRESA NO FIRESTORE
                  if (!isSuperAdmin && user?.companyId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('companies')
                          .doc(user!.companyId)
                          .get(),
                      builder: (context, snapshot) {
                        String empresaTexto = "Carregando...";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          empresaTexto = data['name'] ?? user.companyId;
                        } else if (snapshot.hasError) {
                          empresaTexto = "Erro ao carregar";
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.business, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  empresaTexto,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              accountEmail: Text(user?.email ?? ''),
            ),

            ListTile(
              leading: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, color: Colors.green),
              title: const Text("Sincronizar Dados"),
              onTap: _isSyncing
                  ? null
                  : () {
                      Navigator.pop(context);
                      _handleManualSync();
                    },
            ),

            if (temAcessoGestao) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text(
                  "Administração",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  isSuperAdmin ? Icons.admin_panel_settings : Icons.people,
                  color: Colors.blue,
                ),
                title: Text(
                  isSuperAdmin ? "Painel SuperAdmin" : "Gerenciar Funcionários",
                ),
                subtitle: Text(
                  isSuperAdmin
                      ? "Gestão global do sistema"
                      : "Cadastro de operadores",
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => isSuperAdmin
                          ? const SuperAdminPage()
                          : const AdminPage(),
                    ),
                  );
                },
              ),
            ],

            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Sair da Conta",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 20),
          ],
        ),
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
                                text:
                                    '${user?.name.split(' ').first ?? 'Usuário'}!',
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
                                  final talhao =
                                      _controller.talhoes[index].nome;
                                  final isSelected =
                                      _controller.talhaoSelecionado == talhao;
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
                                      onTap: () =>
                                          _controller.selecionarTalhao(talhao),
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
                                            talhaoAtual:
                                                _controller.talhaoSelecionado!,
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