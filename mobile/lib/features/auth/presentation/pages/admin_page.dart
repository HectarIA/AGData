import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 
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
    if (mounted) {
      // Limpa a pilha de navegação e volta para a raiz (login)
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // FUNÇÃO PARA DISPARAR O WHATSAPP (Atualizada para evitar erros de componente)
  Future<void> _enviarAcessoWhatsApp(UserModel user) async {
    if (user.phone == null || user.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este usuário não possui telefone cadastrado.")),
      );
      return;
    }

    // Limpa o número para deixar apenas dígitos
    final numeroLimpo = user.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Texto formatado para o operador
    final mensagem = "Olá ${user.name}! 🌱\n\n"
        "Seu acesso ao app *HectarIA* está pronto.\n"
        "📧 Login: ${user.email}\n"
        "🔑 A senha padrão é: 123456\n\n"
        "Dúvidas, estou à disposição!";

    final url = "https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}";
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication, // Força abertura do App do WhatsApp
        );
      } else {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível abrir o WhatsApp. Verifique se o app está instalado."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir WhatsApp: $e")),
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
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: _logout,
            tooltip: "Sair",
          ),
        ],
      ),
      body: Column(
        children: [
          // Info da Unidade
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.business, color: Color(0xFF2E7D32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Unidade: $companyId",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("Nenhum operador nesta unidade."));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = UserModel.fromMap(docs[index].data() as Map<String, dynamic>);
                    final isMe = user.uid == _session.usuario?.uid;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: user.role == UserRole.admin ? Colors.blue[700] : Colors.orange[700],
                        child: Icon(
                          user.role == UserRole.admin ? Icons.admin_panel_settings : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text(
                            user.phone != null && user.phone!.isNotEmpty 
                                ? "📱 ${user.phone}" 
                                : "⚠️ Sem telefone",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botão do WhatsApp (Não aparece para mim mesmo)
                          if (!isMe)
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              tooltip: "Enviar acesso via WhatsApp",
                              onPressed: () => _enviarAcessoWhatsApp(user),
                            ),
                          
                          if (isMe) 
                            const Chip(
                              label: Text("Você", style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.grey,
                            )
                          else 
                            IconButton(
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
        onPressed: _abrirDialogoCadastro,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Novo Operador"),
      ),
    );
  }

  void _abrirDialogoCadastro() {
    showDialog(
      context: context,
      barrierDismissible: false, // Força usar o botão cancelar
      builder: (_) => const AddUserDialog(),
    );
  }

  void _confirmarExclusao(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Usuário"),
        content: Text("Deseja remover ${user.name}?\nEsta ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(user.uid).delete();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao excluir: $e")),
                  );
                }
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}