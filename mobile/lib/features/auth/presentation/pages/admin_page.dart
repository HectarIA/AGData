import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Import necessário
import '../../../../core/di/injection_container.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';
import '../widgets/add_user_dialog.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _session = sl<SessionController>();
  final _firestore = FirebaseFirestore.instance;

  void _logout() async {
    await sl<AuthRepository>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // FUNÇÃO PARA DISPARAR O WHATSAPP
  Future<void> _enviarAcessoWhatsApp(UserModel user) async {
    if (user.phone == null || user.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este usuário não possui telefone cadastrado.")),
      );
      return;
    }

    // Limpa o número para deixar apenas dígitos
    final numeroLimpo = user.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    
    final mensagem = Uri.encodeComponent(
      "Olá ${user.name}! 🌱\n\n"
      "Seu acesso ao app **HectarIA** está pronto.\n"
      "📧 Login: ${user.email}\n"
      "🔑 A senha é a que combinamos no cadastro.\n\n"
      "Dúvidas, estou à disposição!"
    );

    final url = "https://wa.me/$numeroLimpo?text=$mensagem";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o WhatsApp.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyId = _session.usuario?.companyId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão de Operadores"),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.business, color: Color(0xFF2E7D32)),
                const SizedBox(width: 12),
                Text(
                  "Unidade ID: $companyId",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('companyId', isEqualTo: companyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Erro ao carregar"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("Nenhum operador cadastrado."));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = UserModel.fromMap(docs[index].data() as Map<String, dynamic>);
                    final isMe = user.uid == _session.usuario?.uid;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.role == UserRole.admin ? Colors.blue : Colors.orange,
                        child: Icon(
                          user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text("${user.role.name} • ${user.phone ?? 'Sem tel.'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // BOTÃO DO WHATSAPP
                          if (!isMe && user.phone != null && user.phone!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              onPressed: () => _enviarAcessoWhatsApp(user),
                            ),
                          
                          isMe 
                            ? const Chip(label: Text("Você"))
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmarExclusao(user),
                              ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoCadastro(),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text("Novo Operador"),
      ),
    );
  }

  void _abrirDialogoCadastro() {
    showDialog(
      context: context,
      builder: (_) => const AddUserDialog(),
    );
  }

  void _confirmarExclusao(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Usuário"),
        content: Text("Deseja remover ${user.name} do sistema?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestore.collection('users').doc(user.uid).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }
}