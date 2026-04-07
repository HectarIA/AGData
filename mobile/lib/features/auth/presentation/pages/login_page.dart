import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';
import '../../../../features/diagnostico/presentation/pages/selecao_talhao_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _carregando = false;
  bool _senhaVisivel = false; 

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final authRepo = sl<AuthRepository>();
      final session = sl<SessionController>();

      final userCredential = await authRepo.loginComCpf(
        _cpfController.text,
        _senhaController.text,
      );

      final usuario = await authRepo.getPerfilUsuario(userCredential.user!.uid);

      if (usuario != null) {
        session.setUsuario(usuario);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SelecaoTalhaoScreen()),
          );
        }
      } else {
        throw Exception("Perfil de usuário não encontrado.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao entrar: ${e.toString()}"),
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
                const Icon(
                  Icons.eco,
                  size: 80,
                  color: Color(0xFF2E7D32),
                ),
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
                  controller: _cpfController,
                  inputFormatters: [_cpfMask],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "CPF",
                    hintText: "000.000.000-00",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => v!.length < 14 ? "CPF incompleto" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _senhaVisivel = !_senhaVisivel;
                        });
                      },
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? "Senha muito curta" : null,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _carregando 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text(
                          "ENTRAR NO SISTEMA", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
                
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                  },
                  child: const Text(
                    "Esqueceu sua senha?",
                    style: TextStyle(color: Color(0xFF2E7D32)),
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