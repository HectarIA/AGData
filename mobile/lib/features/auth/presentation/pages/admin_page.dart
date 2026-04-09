import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';
import '../widgets/add_user_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _session = sl<SessionController>();
  final _firestore = FirebaseFirestore.instance;

  // O AuthWrapper no main.dart cuidará da navegação após o logout
  void _logout() async {
    try {
      await sl<AuthRepository>().logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao sair: $e")));
      }
    }
  }

  String _gerarSenhaAleatoria() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  Future<void> _enviarAcessoWhatsApp(UserModel user) async {
    if (user.phone == null || user.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este usuário não possui telefone cadastrado."),
        ),
      );
      return;
    }

    final numeroLimpo = user.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    final senhaGerada = _gerarSenhaAleatoria();

    final mensagem =
        "Olá ${user.name}! 🌱\n\n"
        "Seu acesso ao app *HectarIA* está pronto.\n\n"
        "📧 *Login:* ${user.email}\n"
        "🔑 *Senha Provisória:* $senhaGerada\n\n"
        "⚠️ *Atenção:* Por segurança, o sistema solicitará a troca da senha no primeiro acesso.\n\n"
        "Dúvidas, estou à disposição!";

    final url =
        "https://wa.me/55$numeroLimpo?text=${Uri.encodeComponent(mensagem)}";
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Não foi possível abrir o WhatsApp.";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.orangeAccent,
          ),
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Sair do Sistema",
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de Unidade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(bottom: BorderSide(color: Colors.green.shade100)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      children: [
                        const TextSpan(text: "Unidade: "),
                        TextSpan(
                          text: companyId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
                if (snapshot.hasError)
                  return const Center(
                    child: Text("Erro ao carregar lista de operadores."),
                  );
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Center(
                    child: Text("Nenhum operador cadastrado."),
                  );

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = UserModel.fromMap(
                      docs[index].data() as Map<String, dynamic>,
                    );
                    final isMe = user.uid == _session.usuario?.uid;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: user.role == UserRole.admin
                              ? Colors.blue.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            user.role == UserRole.admin
                                ? Icons.admin_panel_settings
                                : Icons.engineering,
                            color: user.role == UserRole.admin
                                ? Colors.blue.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.phone ?? "Sem telefone",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              IconButton(
                                icon: FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.green,
                                ),
                                tooltip: "Enviar Credenciais",
                                onPressed: () => _enviarAcessoWhatsApp(user),
                              ),
                            if (isMe)
                              const Badge(
                                label: Text("VOCÊ"),
                                backgroundColor: Colors.blueGrey,
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _confirmarExclusao(user),
                              ),
                          ],
                        ),
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
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          "ADICIONAR OPERADOR",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _abrirDialogoCadastro() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddUserDialog(),
    );
  }

  void _confirmarExclusao(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover Operador?"),
        content: Text(
          "Isso excluirá o acesso de ${user.name}. Essa ação é irreversível.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(user.uid).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Operador removido com sucesso."),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text(
              "CONFIRMAR EXCLUSÃO",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
