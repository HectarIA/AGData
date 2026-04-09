import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/auth_model.dart'; 
import '../controller/session_controller.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Sincronizado com seu enum: UserRole.operador
  UserRole _roleSelecionada = UserRole.operador;
  bool _isLoading = false;

  String _gerarSenhaAleatoria() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  Future<void> _enviarAcessoWhatsApp(String nome, String email, String senha, String telefone) async {
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    
    final mensagem = "Olá $nome! 🌱\n\n"
        "Seu acesso ao app *HectarIA* está pronto.\n\n"
        "📧 *Login:* $email\n"
        "🔑 *Senha Provisória:* $senha\n\n"
        "⚠️ *Atenção:* Por segurança, o sistema solicitará a troca da senha no primeiro acesso.";
    
    final url = Uri.parse("https://wa.me/55$numeroLimpo?text=${Uri.encodeComponent(mensagem)}");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir WhatsApp.'))
        );
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final session = sl<SessionController>();
    final senhaProvisoria = _gerarSenhaAleatoria();
    final email = _emailController.text.trim().toLowerCase();
    final nome = _nomeController.text.trim();
    final telefone = _phoneController.text.trim();

    try {
      final newUserRef = FirebaseFirestore.instance.collection('users').doc();
      
      // Criando o objeto usando o seu UserModel para garantir consistência
      final novoUsuario = UserModel(
        uid: newUserRef.id,
        name: nome,
        email: email,
        phone: telefone,
        role: _roleSelecionada,
        companyId: session.usuario?.companyId ?? '',
        needsPasswordChange: true, // Sincronizado com seu model
      );

      // Salvando no Firestore usando o seu método toMap()
      await newUserRef.set(novoUsuario.toMap());

      await _enviarAcessoWhatsApp(nome, email, senhaProvisoria, telefone);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Operador cadastrado com sucesso!"), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Operador"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Cadastro de Acesso", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome Completo", 
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "E-mail", 
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.contains("@") ? null : "E-mail inválido",
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "WhatsApp (DDD + Número)", 
                      border: OutlineInputBorder(),
                      hintText: "Ex: 42999998888"
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.length < 10 ? "Telefone inválido" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown corrigido para UserRole
                  DropdownButtonFormField<UserRole>(
                    value: _roleSelecionada,
                    decoration: const InputDecoration(
                      labelText: "Cargo", 
                      border: OutlineInputBorder(),
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
                  
                  ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      "CADASTRAR E ENVIAR WHATSAPP", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}