import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';
import '../../../../features/diagnostico/presentation/pages/selecao_talhao_screen.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;
  bool _senhaVisivel = false;

  final _authRepo = sl<AuthRepository>();
  final _session = sl<SessionController>();

  @override
  void dispose() {
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _atualizarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      // 1. Atualiza no Firebase e Firestore via Repositório
      await _authRepo.atualizarSenha(_novaSenhaController.text.trim());

      // 2. Atualiza a sessão local
      if (_session.usuario != null) {
        final usuarioAtualizado = _session.usuario!.copyWith(
          needsPasswordChange: false,
        );
        _session.setUsuario(usuarioAtualizado);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Senha definida com sucesso!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 3. Redireciona limpando a pilha para evitar que o usuário volte para esta tela
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SelecaoTalhaoScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Segurança"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Opção de sair caso o usuário não queira trocar a senha agora
          IconButton(
            onPressed: () => _authRepo.logout(),
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Sair",
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF1B5E20),
              padding: const EdgeInsets.only(bottom: 32),
              child: const Column(
                children: [
                  Icon(Icons.lock_reset, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Defina sua senha",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Você está usando uma senha provisória. Para sua segurança, crie uma senha pessoal de acesso.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      controller: _novaSenhaController,
                      obscureText: !_senhaVisivel,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: "Nova Senha",
                        hintText: "Mínimo 6 dígitos",
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? "Senha muito curta" : null,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _confirmarSenhaController,
                      obscureText: !_senhaVisivel,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: "Confirmar Senha",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v != _novaSenhaController.text) return "As senhas não coincidem";
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _atualizarSenha,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: _carregando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "SALVAR E ACESSAR",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}