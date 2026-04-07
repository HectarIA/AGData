import 'package:flutter/material.dart';
import '../../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  bool _carregando = false;

  Future<void> _salvar() async {
    if (_nomeController.text.isEmpty || _emailController.text.isEmpty) return;

    setState(() => _carregando = true);
    final session = sl<SessionController>();

    try {
      await sl<AuthRepository>().cadastrarNovoUsuario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: "123456", // Senha padrão de primeiro acesso
        role: "operador", // Admin comum só cria operadores por padrão
        companyId: session.usuario!.companyId, // HERDA DA SESSÃO DO ADMIN
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Novo Operador"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nomeController, decoration: const InputDecoration(labelText: "Nome")),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-mail")),
          const SizedBox(height: 10),
          const Text("A senha inicial será: 123456", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: _carregando ? null : _salvar,
          child: _carregando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Criar"),
        ),
      ],
    );
  }
}