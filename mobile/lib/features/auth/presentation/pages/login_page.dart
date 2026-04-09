import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';

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

      // 1. Faz o login no Firebase Auth
      final userCredential = await authRepo.loginComEmail(
        _emailController.text.trim(),
        _senhaController.text,
      );

      // 2. Busca o perfil no Firestore
      final usuario = await authRepo.getPerfilUsuario(userCredential.user!.uid);

      if (usuario != null) {
        // 3. Alimenta a sessão global
        session.setUsuario(usuario);
        
        // NOTA: Não fazemos Navigator.push aqui. 
        // O AuthWrapper no main.dart cuidará do redirecionamento automático
        // assim que detectar a mudança no FirebaseAuth.instance.authStateChanges()
        
      } else {
        // Caso o login ocorra mas o perfil não exista no banco (usuário fantasma)
        await FirebaseAuth.instance.signOut();
        throw Exception("Perfil de usuário não encontrado no sistema.");
      }

    } on FirebaseAuthException catch (e) {
      String mensagemErro = "Ocorreu um erro ao entrar.";

      // Tratamento unificado para segurança (não informar se o erro é no e-mail ou na senha)
      if (e.code == 'user-not-found' || 
          e.code == 'wrong-password' || 
          e.code == 'invalid-credential' || 
          e.code == 'invalid-email') {
        mensagemErro = "E-mail ou senha incorretos.";
      } else if (e.code == 'user-disabled') {
        mensagemErro = "Esta conta foi desativada pelo administrador.";
      } else if (e.code == 'network-request-failed') {
        mensagemErro = "Sem conexão com a internet.";
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

  Future<void> _resetarSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite seu e-mail para receber o link de recuperação.")),
      );
      return;
    }
    
    try {
      await sl<AuthRepository>().recuperarSenha(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("E-mail de recuperação enviado! Verifique sua caixa de entrada."), 
            backgroundColor: Colors.green
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Erro ao processar solicitação.";
      if (e.code == 'user-not-found') msg = "Este e-mail não está cadastrado.";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENTRAR NO SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _carregando ? null : _resetarSenha,
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