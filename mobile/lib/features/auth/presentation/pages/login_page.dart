import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';
import '../pages/forgot_password_page.dart';
import '../pages/super_admin_page.dart';
import '../pages/change_password_page.dart';
import '../../../../features/diagnostico/presentation/pages/selecao_talhao_screen.dart';
import '../../data/models/auth_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _carregando = false;
  bool _senhaVisivel = false; 

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final authRepo = sl<AuthRepository>();
      final session = sl<SessionController>();

      final usuario = await authRepo.loginComEmail(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (usuario != null) {
        session.setUsuario(usuario);

        if (mounted) {
          if (usuario.needsPasswordChange) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            );
            return;
          }

          if (usuario.role == UserRole.superAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SuperAdminPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SelecaoTalhaoScreen()),
            );
          }
        }
      } else {
        throw Exception("Não foi possível carregar os dados do usuário.");
      }

    } on FirebaseAuthException catch (e) {
      String mensagemErro = "Ocorreu um erro ao entrar.";

      if (e.code == 'user-not-found' || 
          e.code == 'wrong-password' || 
          e.code == 'invalid-credential' || 
          e.code == 'invalid-email') {
        mensagemErro = "E-mail ou senha incorretos.";
      } else if (e.code == 'user-disabled') {
        mensagemErro = "Esta conta foi desativada pelo administrador.";
      } else if (e.code == 'network-request-failed' || e.code == 'channel-error') {
        mensagemErro = "Sem conexão. Login offline não disponível para este usuário.";
      } else if (e.code == 'too-many-requests') {
        mensagemErro = "Muitas tentativas. Tente novamente em alguns minutos.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErro), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')), 
            backgroundColor: Colors.orangeAccent
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.eco, size: 80, color: Color(0xFF2E7D32)),
                const SizedBox(height: 16),
                const Text(
                  "HectarIA",
                  style: TextStyle(
                    fontSize: 36, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF2E7D32),
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  "Monitoramento Inteligente",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    hintText: "seu@email.com",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? "Insira um e-mail válido" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _fazerLogin(),
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? "A senha deve ter no mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _carregando 
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("ENTRAR NO SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _carregando ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: const Text(
                    "Esqueceu sua senha?",
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}