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

  Future<void> _atualizarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      // 1. Chama o método do repositório que já faz tudo:
      // - Atualiza a senha no Firebase Auth
      // - Muda 'needsPasswordChange' para false no Firestore
      await _authRepo.atualizarSenha(_novaSenhaController.text);

      if (_session.usuario != null) {
        // Criamos uma cópia do usuário com a flag alterada e salvamos na sessão
        final usuarioAtualizado = _session.usuario!.copyWith(
          needsPasswordChange: false,
        );
        _session.setUsuario(usuarioAtualizado);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Senha atualizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );

        // 3. Redireciona para a tela principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SelecaoTalhaoScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar senha: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
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
      appBar: AppBar(
        title: const Text("Nova Senha"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Bloqueia o botão de voltar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 64, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Segurança da Conta",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Esta é uma senha provisória. Por favor, crie uma nova senha definitiva para acessar o HectarIA.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _novaSenhaController,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  labelText: "Nova Senha",
                  hintText: "Mínimo 6 caracteres",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? "A senha deve ter pelo menos 6 caracteres"
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmarSenhaController,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  labelText: "Confirmar Nova Senha",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_reset),
                ),
                validator: (v) {
                  if (v != _novaSenhaController.text)
                    return "As senhas não coincidem";
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _atualizarSenha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                          "DEFINIR NOVA SENHA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
