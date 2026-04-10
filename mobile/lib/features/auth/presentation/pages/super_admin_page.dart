import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

// Imports de Injeção e Controller
import '../../../../core/di/injection_container.dart';
import '../controller/session_controller.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';

// IMPORT DO SEU CUSTOM DRAWER (Ajuste o caminho conforme sua pasta)
import '../../presentation/widgets/custom_drawer.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final SessionController _session = sl<SessionController>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  // Controladores
  final _nomeEmpresaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _nomeAdminController = TextEditingController();
  final _emailAdminController = TextEditingController();
  final _cpfAdminController = TextEditingController();
  final _phoneAdminController = TextEditingController();

  bool _carregando = false;

  // Formatadores
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
  final _cnpjFormatter = MaskTextInputFormatter(mask: '##.###.###/####-##');
  final _phoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _cnpjController.dispose();
    _nomeAdminController.dispose();
    _emailAdminController.dispose();
    _cpfAdminController.dispose();
    _phoneAdminController.dispose();
    super.dispose();
  }

  String _gerarSenhaProvisoria() =>
      (Random().nextInt(900000) + 100000).toString();

  Future<void> _enviarWhatsapp(
    String nome,
    String email,
    String senha,
    String telefone,
  ) async {
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.length < 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de telefone inválido.')),
        );
      }
      return;
    }

    final mensagem =
        "Olá administrador $nome! Seu acesso ao HectarIA está pronto.\n\n"
        "📧 Login: $email\n"
        "🔑 Senha Provisória: $senha\n\n"
        "Obs: Por segurança, altere sua senha no primeiro acesso.";

    final url = Uri.parse(
      "https://wa.me/55$numeroLimpo?text=${Uri.encodeComponent(mensagem)}",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir WhatsApp.')),
        );
      }
    }
  }

  Future<void> _cadastrarTudo() async {
    if (_session.usuario?.role != UserRole.superAdmin) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    final senhaGerada = _gerarSenhaProvisoria();

    try {
      DocumentReference empresaRef = FirebaseFirestore.instance
          .collection('companies')
          .doc();

      await _authRepo.cadastrarNovoUsuario(
        nome: _nomeAdminController.text.trim(),
        email: _emailAdminController.text.trim(),
        senha: senhaGerada,
        role: 'admin',
        companyId: empresaRef.id,
        cpf: _cpfAdminController.text,
        phone: _phoneAdminController.text,
      );

      await empresaRef.set({
        'id': empresaRef.id,
        'name': _nomeEmpresaController.text.trim(),
        'cnpj': _cnpjController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _exibirDialogoSucesso(
          _nomeAdminController.text.trim(),
          _emailAdminController.text.trim(),
          senhaGerada,
          _phoneAdminController.text,
        );
        _limparCampos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha no cadastro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _exibirDialogoSucesso(
    String nome,
    String email,
    String senha,
    String telefone,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "🚀 Sucesso!",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Administrador e Empresa cadastrados com sucesso no sistema.",
            ),
            const SizedBox(height: 16),
            const Text(
              "Senha provisória:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                senha,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FECHAR"),
          ),
          ElevatedButton.icon(
            onPressed: () => _enviarWhatsapp(nome, email, senha, telefone),
            icon: const Icon(Icons.send, size: 18),
            label: const Text("ENVIAR ACESSO"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _limparCampos() {
    _nomeEmpresaController.clear();
    _cnpjController.clear();
    _nomeAdminController.clear();
    _emailAdminController.clear();
    _cpfAdminController.clear();
    _phoneAdminController.clear();
    _formKey.currentState?.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Global HectarIA'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // UTILIZANDO O SEU CUSTOM DRAWER AQUI
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildForm(),
            const SizedBox(height: 40),
            _buildCompanyListHeader(),
            const Divider(),
            _buildCompanyStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'DADOS DA EMPRESA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomeEmpresaController,
            decoration: const InputDecoration(
              labelText: 'Nome da Empresa',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Informe o nome da empresa' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cnpjController,
            inputFormatters: [_cnpjFormatter],
            decoration: const InputDecoration(
              labelText: 'CNPJ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.assignment_ind),
            ),
            keyboardType: TextInputType.number,
          ),
          const Divider(height: 40, thickness: 1),
          const Text(
            'ADMINISTRADOR RESPONSÁVEL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomeAdminController,
            decoration: const InputDecoration(
              labelText: 'Nome Completo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Informe o nome do administrador'
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailAdminController,
            decoration: const InputDecoration(
              labelText: 'E-mail de Login',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneAdminController,
            inputFormatters: [_phoneFormatter],
            decoration: const InputDecoration(
              labelText: 'WhatsApp',
              border: OutlineInputBorder(),
              hintText: '(00) 00000-0000',
              prefixIcon: Icon(Icons.phone_iphone),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Telefone obrigatório' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cpfAdminController,
            inputFormatters: [_cpfFormatter],
            decoration: const InputDecoration(
              labelText: 'CPF',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _carregando ? null : _cadastrarTudo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CADASTRAR EMPRESA E ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyListHeader() {
    return const Row(
      children: [
        Icon(Icons.list_alt, color: Colors.green),
        SizedBox(width: 8),
        Text(
          'EMPRESAS PARCEIRAS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCompanyStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Erro ao carregar empresas');
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Nenhuma empresa cadastrada."),
          );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final company = docs[index].data() as Map<String, dynamic>;
            final companyId = company['id'] ?? docs[index].id;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.agriculture, color: Colors.green),
                ),
                title: Text(
                  company['name'] ?? 'Sem nome',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CNPJ: ${company['cnpj'] ?? 'N/A'}'),
                    _buildAdminInfo(companyId),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminInfo(String companyId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get(),
      builder: (context, userSnap) {
        if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
          final adminData =
              userSnap.data!.docs.first.data() as Map<String, dynamic>;

          // Captura dos dados
          final String nome = adminData['name'] ?? 'N/A';
          final String email = adminData['email'] ?? 'N/A';
          final String phone = adminData['phone'] ?? 'S/ Tel';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Adm: $nome',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Email: $email',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              Text(
                'Whats: $phone',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
