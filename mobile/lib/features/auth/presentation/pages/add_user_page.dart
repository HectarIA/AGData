import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../controller/session_controller.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final SessionController _session = sl<SessionController>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  UserRole _roleSelecionada = UserRole.operador;
  bool _carregando = false;

  final _phoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

  String _gerarSenhaProvisoria() => (Random().nextInt(900000) + 100000).toString();

  Future<void> _enviarWhatsapp(String nome, String email, String senha, String telefone) async {
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    
    final mensagem = "Olá $nome! 🌱\n\n"
        "Seu acesso ao app *HectarIA* está pronto.\n\n"
        "📧 *Login:* $email\n"
        "🔑 *Senha Provisória:* $senha\n\n"
        "⚠️ *Atenção:* Por segurança, altere sua senha no primeiro acesso.";
    
    final url = Uri.parse("https://wa.me/55$numeroLimpo?text=${Uri.encodeComponent(mensagem)}");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir WhatsApp. Verifique se o app está instalado.'))
        );
      }
    }
  }

  Future<void> _salvar() async {
    // Apenas admins e superAdmins da empresa podem cadastrar novos usuários aqui
    if (_session.usuario?.role == UserRole.operador) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    final senhaGerada = _gerarSenhaProvisoria();

    try {
      // Usando o padrão do AuthRepository conforme visto na SuperAdminPage
      await _authRepo.cadastrarNovoUsuario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: senhaGerada,
        role: _roleSelecionada.name, // 'admin' ou 'operador'
        companyId: _session.usuario?.companyId ?? '',
        phone: _phoneController.text,
      );

      if (mounted) {
        _exibirDialogoSucesso(
          _nomeController.text.trim(),
          _emailController.text.trim(),
          senhaGerada,
          _phoneController.text,
        );
        _limparCampos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha no cadastro: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _exibirDialogoSucesso(String nome, String email, String senha, String telefone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Sucesso!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Usuário cadastrado com sucesso!"),
            const SizedBox(height: 16),
            const Text("Senha provisória:", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(senha, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 4)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR")),
          ElevatedButton.icon(
            onPressed: () => _enviarWhatsapp(nome, email, senha, telefone),
            icon: const Icon(Icons.send, size: 18),
            label: const Text("ENVIAR ACESSO"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _limparCampos() {
    _nomeController.clear();
    _emailController.clear();
    _phoneController.clear();
    setState(() {
      _roleSelecionada = UserRole.operador;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Acesso"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'DADOS DO NOVO USUÁRIO', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1.2)
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome Completo", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? "Informe o nome" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "E-mail de Login", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains("@")) ? "E-mail inválido" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                inputFormatters: [_phoneFormatter],
                decoration: const InputDecoration(
                  labelText: "WhatsApp", 
                  border: OutlineInputBorder(),
                  hintText: "(00) 00000-0000",
                  prefixIcon: Icon(Icons.phone_iphone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Telefone obrigatório" : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<UserRole>(
                value: _roleSelecionada,
                decoration: const InputDecoration(
                  labelText: "Nível de Acesso", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: UserRole.operador, 
                    child: Text("Operador"),
                  ),
                  DropdownMenuItem(
                    value: UserRole.admin, 
                    child: Text("Administrador"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _roleSelecionada = val);
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _carregando 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "CADASTRAR E GERAR ACESSO", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}