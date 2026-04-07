import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../controller/session_controller.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final SessionController _session = sl<SessionController>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  final _nomeEmpresaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _nomeAdminController = TextEditingController();
  final _emailAdminController = TextEditingController();
  final _cpfAdminController = TextEditingController();

  bool _carregando = false;
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
  final _cnpjFormatter = MaskTextInputFormatter(mask: '##.###.###/####-##');

  /// Gera uma senha aleatória de 6 dígitos
  String _gerarSenhaProvisoria() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  /// Abre o WhatsApp com a mensagem pronta
  Future<void> _enviarWhatsapp(String nome, String email, String senha) async {
    final mensagem = "Olá $nome! Seu acesso ao HectarIA está pronto.\n\n"
        "📧 Login: $email\n"
        "🔑 Senha Provisória: $senha\n\n"
        "Obs: Por segurança, o sistema solicitará que você crie uma nova senha no seu primeiro acesso.";

    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(mensagem)}");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir WhatsApp. Verifique se o app está instalado.')),
        );
      }
    }
  }

  Future<void> _cadastrarTudo() async {
    // 1. Verificação de permissão
    if (_session.usuario?.role != UserRole.superAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acesso negado.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    final senhaGerada = _gerarSenhaProvisoria();

    try {
      // 2. Gerar ID da Empresa
      DocumentReference empresaRef = FirebaseFirestore.instance.collection('companies').doc();

      // 3. Criar Admin via instância secundária (Evita deslogar o SuperAdmin)
      await _authRepo.cadastrarNovoUsuario(
        nome: _nomeAdminController.text,
        email: _emailAdminController.text.trim(),
        senha: senhaGerada,
        role: 'admin',
        companyId: empresaRef.id,
        cpf: _cpfAdminController.text,
      );

      // 4. Registrar a Empresa no Firestore
      await empresaRef.set({
        'id': empresaRef.id,
        'name': _nomeEmpresaController.text,
        'cnpj': _cnpjController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _exibirDialogoSucesso(
          _nomeAdminController.text,
          _emailAdminController.text.trim(),
          senhaGerada,
        );
        _limparCampos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha no cadastro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _exibirDialogoSucesso(String nome, String email, String senha) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Sucesso!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Administrador criado com sucesso!"),
            const SizedBox(height: 10),
            Text("Senha gerada: ", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(senha, style: const TextStyle(fontSize: 20, color: Colors.blueAccent, letterSpacing: 2)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FECHAR"),
          ),
          ElevatedButton.icon(
            onPressed: () => _enviarWhatsapp(nome, email, senha),
            icon: const Icon(Icons.share),
            label: const Text("ENVIAR WHATSAPP"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _limparCampos() {
    _formKey.currentState!.reset();
    _nomeEmpresaController.clear();
    _cnpjController.clear();
    _nomeAdminController.clear();
    _emailAdminController.clear();
    _cpfAdminController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HectarIA - Gestão Global'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authRepo.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('DADOS DA FAZENDA / EMPRESA', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomeEmpresaController,
                    decoration: const InputDecoration(labelText: 'Nome Comercial', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _cnpjController,
                    inputFormatters: [_cnpjFormatter],
                    decoration: const InputDecoration(labelText: 'CNPJ', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const Divider(height: 40),
                  const Text('ACESSO DO ADMINISTRADOR', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomeAdminController,
                    decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailAdminController,
                    decoration: const InputDecoration(labelText: 'E-mail Real (Login e Recuperação)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _cpfAdminController,
                    inputFormatters: [_cpfFormatter],
                    decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _carregando ? null : _cadastrarTudo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _carregando 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('FINALIZAR CADASTRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Align(alignment: Alignment.centerLeft, child: Text('EMPRESAS CADASTRADAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('companies').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.agriculture, color: Colors.green),
                        title: Text(data['name'] ?? 'Sem nome'),
                        subtitle: Text('CNPJ: ${data['cnpj'] ?? 'N/A'}'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}