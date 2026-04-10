import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _recuperarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Chama o método de recuperação do seu repositório
      await sl<AuthRepository>().recuperarSenha(_emailController.text.trim());

      if (mounted) {
        _mostrarFeedback(
          "E-mail enviado!",
          "Verifique sua caixa de entrada (e spam) para redefinir sua senha.",
          Colors.green,
        );
        Navigator.pop(context); // Volta para a tela de login
      }
    } catch (e) {
      if (mounted) {
        _mostrarFeedback(
          "Erro",
          "Não foi possível enviar o e-mail: $e",
          Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarFeedback(String titulo, String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Senha"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                "Esqueceu sua senha?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Digite seu e-mail abaixo. Enviaremos um link para você criar uma nova senha.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "E-mail cadastrado",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? "E-mail inválido" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _recuperarSenha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENVIAR E-MAIL DE RECUPERAÇÃO",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "A recuperação de senha requer conexão com a internet. Certifique-se de estar conectado para receber o e-mail.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
